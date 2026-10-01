import 'package:hive_flutter/hive_flutter.dart';

import '../storage/hive_boxes.dart';
import '../features/contacts/data/models/cached_contact_model.dart';
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

  Future<void> init() async {
  _settingsBox = await Hive.openBox(HiveBoxes.settings);

  // Contacts cache
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(CachedContactModelAdapter());
  }
  await Hive.openBox<CachedContactModel>(HiveBoxes.contactsCache);
  await Hive.openBox<dynamic>(HiveBoxes.contactsMeta);
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
