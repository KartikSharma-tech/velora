import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../storage/hive_boxes.dart';
import '../../features/contacts/data/models/cached_contact_model.dart';

/// ===========================================================
/// Velora
/// Hive Service
/// -----------------------------------------------------------
///
/// Thin wrapper around the local `settings` Hive box.
/// Call [init] once from bootstrap() after Hive.initFlutter().
///
/// ===========================================================

class HiveService {
  HiveService._();

  static final HiveService instance = HiveService._();

  Box? _settingsBox;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _contactsKeyName = 'velora_contacts_cache_key_v2';
  static const String _legacyContactsBox = 'contacts_cache';
  static const String _legacyContactsMetaBox = 'contacts_meta';

  Future<void> init() async {
    _settingsBox = await Hive.openBox(HiveBoxes.settings);

    // Contacts cache
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(CachedContactModelAdapter());
    }
    final key = await _getOrCreateContactsEncryptionKey();
    final secureContacts = await Hive.openBox<CachedContactModel>(
      HiveBoxes.contactsCache,
      encryptionCipher: HiveAesCipher(key),
    );
    final secureMeta = await Hive.openBox<dynamic>(
      HiveBoxes.contactsMeta,
      encryptionCipher: HiveAesCipher(key),
    );
    await _migratePlaintextContacts(secureContacts, secureMeta);
  }

  Future<Uint8List> _getOrCreateContactsEncryptionKey() async {
    final storedKey = await _secureStorage.read(key: _contactsKeyName);
    if (storedKey != null) {
      return Uint8List.fromList(base64Url.decode(storedKey));
    }

    final random = Random.secure();
    final key = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    await _secureStorage.write(
      key: _contactsKeyName,
      value: base64UrlEncode(key),
    );
    return key;
  }

  Future<void> _migratePlaintextContacts(
    Box<CachedContactModel> secureContacts,
    Box<dynamic> secureMeta,
  ) async {
    final hasLegacyContacts = await Hive.boxExists(_legacyContactsBox);
    final hasLegacyMeta = await Hive.boxExists(_legacyContactsMetaBox);
    if (!hasLegacyContacts && !hasLegacyMeta) {
      return;
    }

    final legacyContacts = await Hive.openBox<CachedContactModel>(
      _legacyContactsBox,
    );
    final legacyMeta = await Hive.openBox<dynamic>(_legacyContactsMetaBox);

    if (secureContacts.isEmpty && legacyContacts.isNotEmpty) {
      await secureContacts.addAll(
        legacyContacts.values.map((contact) => contact.copyWith()).toList(),
      );
    }
    for (final key in legacyMeta.keys) {
      if (!secureMeta.containsKey(key)) {
        await secureMeta.put(key, legacyMeta.get(key));
      }
    }

    await legacyContacts.clear();
    await legacyMeta.clear();
    await legacyContacts.close();
    await legacyMeta.close();
    await Hive.deleteBoxFromDisk(_legacyContactsBox);
    await Hive.deleteBoxFromDisk(_legacyContactsMetaBox);
  }

  Box get _box {
    final box = _settingsBox;
    if (box == null) {
      throw StateError('HiveService.init() must be called before use.');
    }
    return box;
  }

  T? read<T>(String key) => _box.get(key) as T?;

  Future<void> write(String key, dynamic value) => _box.put(key, value);

  Future<void> delete(String key) => _box.delete(key);
}
