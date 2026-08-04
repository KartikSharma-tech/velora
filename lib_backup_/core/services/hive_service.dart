import 'package:hive_flutter/hive_flutter.dart';

import '../storage/hive_boxes.dart';

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
