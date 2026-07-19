import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys used in [SharedPreferences].
class _Keys {
  static const onboardingSeen = 'onboarding_seen';
  static const appLockEnabled = 'app_lock_enabled';
  static const autoLockSeconds = 'auto_lock_seconds';
  static const accentColorIndex = 'accent_color_index';
}

/// App-wide settings persisted via [SharedPreferences].
class AppSettings {
  const AppSettings({
    this.onboardingSeen = false,
    this.appLockEnabled = false,
    this.autoLockSeconds = 0, // 0 = lock on app background immediately
    this.accentColorIndex = 0,
  });

  final bool onboardingSeen;
  final bool appLockEnabled;
  final int autoLockSeconds;
  final int accentColorIndex;

  AppSettings copyWith({
    bool? onboardingSeen,
    bool? appLockEnabled,
    int? autoLockSeconds,
    int? accentColorIndex,
  }) {
    return AppSettings(
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
      accentColorIndex: accentColorIndex ?? this.accentColorIndex,
    );
  }
}

/// Accent color presets the user can choose from in Settings.
class AccentPresets {
  const AccentPresets._();
  static const colors = <Color>[
    Color(0xFF7C5CFC), // violet (default)
    Color(0xFF22D3EE), // cyan
    Color(0xFFEC4899), // pink
    Color(0xFF10B981), // emerald
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
  ];
  static const labels = <String>[
    'Violet',
    'Cyan',
    'Pink',
    'Emerald',
    'Amber',
    'Red',
  ];
}

/// Notifier that loads, holds, and persists [AppSettings].
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier(this._prefs) : super(const AppSettings());

  final SharedPreferences _prefs;

  Future<void> load() async {
    state = AppSettings(
      onboardingSeen: _prefs.getBool(_Keys.onboardingSeen) ?? false,
      appLockEnabled: _prefs.getBool(_Keys.appLockEnabled) ?? false,
      autoLockSeconds: _prefs.getInt(_Keys.autoLockSeconds) ?? 0,
      accentColorIndex: _prefs.getInt(_Keys.accentColorIndex) ?? 0,
    );
  }

  Future<void> markOnboardingSeen() async {
    await _prefs.setBool(_Keys.onboardingSeen, true);
    state = state.copyWith(onboardingSeen: true);
  }

  Future<void> setAppLock(bool enabled) async {
    await _prefs.setBool(_Keys.appLockEnabled, enabled);
    state = state.copyWith(appLockEnabled: enabled);
  }

  Future<void> setAutoLockSeconds(int seconds) async {
    await _prefs.setInt(_Keys.autoLockSeconds, seconds);
    state = state.copyWith(autoLockSeconds: seconds);
  }

  Future<void> setAccentColor(int index) async {
    await _prefs.setInt(_Keys.accentColorIndex, index);
    state = state.copyWith(accentColorIndex: index);
  }

  Future<void> resetOnboarding() async {
    await _prefs.setBool(_Keys.onboardingSeen, false);
    state = state.copyWith(onboardingSeen: false);
  }
}

/// FutureProvider that resolves to a constructed [AppSettingsNotifier].
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  throw UnimplementedError('Override with a SharedPreferences-backed instance');
});
