import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/hive_service.dart';

/// ===========================================================
/// Velora
/// App-wide Providers
/// -----------------------------------------------------------
///
/// Small, app-level state that doesn't belong to a single
/// feature — currently just the persisted theme mode.
///
/// ===========================================================

const _themeModeKey = 'theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_readInitial());

  static ThemeMode _readInitial() {
    final stored = HiveService.instance.read<String>(_themeModeKey);
    switch (stored) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void set(ThemeMode mode) {
    state = mode;
    HiveService.instance.write(_themeModeKey, mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
