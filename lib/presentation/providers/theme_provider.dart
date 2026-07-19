import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';

/// Holds the user's theme mode preference, persisted in Hive.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._box) : super(_read(_box)) {
    _box.listenable(keys: [AppConstants.themeModeKey]).addListener(_onChange);
  }

  final Box<dynamic> _box;

  static ThemeMode _read(Box<dynamic> box) {
    final raw = box.get(AppConstants.themeModeKey) as String?;
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void _onChange() {
    state = _read(_box);
  }

  Future<void> set(ThemeMode mode) async {
    await _box.put(AppConstants.themeModeKey, mode.name);
    state = mode;
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await set(next);
  }

  @override
  void dispose() {
    _box.listenable(keys: [AppConstants.themeModeKey]).removeListener(_onChange);
    super.dispose();
  }
}

/// Provides the current [ThemeMode] and lets the UI toggle it.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final box = Hive.box<dynamic>(AppConstants.settingsBox);
  return ThemeModeNotifier(box);
});
