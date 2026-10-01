import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/velora_contact.dart';
import '../models/cached_contact_model.dart';

class HiveContactsDataSource {
  static const String _boxName = 'contacts_cache';
  static const String _metaBoxName = 'contacts_meta';
  static const int _cacheValidHours = 24;

  Box<CachedContactModel> get _box => Hive.box<CachedContactModel>(_boxName);
  Box<dynamic> get _metaBox => Hive.box<dynamic>(_metaBoxName);

  /// Contacts cache mein save karo
  Future<void> cacheContacts(List<VeloraContact> contacts) async {
    await _box.clear();

    final models = contacts.map((c) => CachedContactModel(
          phone: c.phone,
          cachedAt: DateTime.now(),
          isOnVelora: c.isOnVelora,
          displayName: c.displayName,
          uid: c.uid,
          veloraName: c.veloraName,
          photoUrl: c.photoUrl,
          username: c.username,
        ));

    await _box.addAll(models);
    await _metaBox.put('lastSyncTime', DateTime.now().toIso8601String());
  }

  /// Cache se contacts lo
  Future<List<VeloraContact>> getCachedContacts() async {
    return _box.values.map((m) => VeloraContact(
          displayName: m.displayName,
          phone: m.phone,
          isOnVelora: m.isOnVelora,
          uid: m.uid,
          veloraName: m.veloraName,
          photoUrl: m.photoUrl,
          username: m.username,
        )).toList();
  }

  /// Cache 24 hours se fresh hai?
  Future<bool> isCacheValid() async {
    final lastSync = _metaBox.get('lastSyncTime') as String?;
    if (lastSync == null) return false;

    final lastSyncTime = DateTime.tryParse(lastSync);
    if (lastSyncTime == null) return false;

    return DateTime.now().difference(lastSyncTime).inHours < _cacheValidHours;
  }

  /// Cache clear karo
  Future<void> clearCache() async {
    await _box.clear();
    await _metaBox.delete('lastSyncTime');
  }

  /// Last sync time
  Future<DateTime?> lastSyncTime() async {
    final lastSync = _metaBox.get('lastSyncTime') as String?;
    if (lastSync == null) return null;
    return DateTime.tryParse(lastSync);
  }
}