import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/security/lock_repository.dart';
import '../../data/security/security_preferences.dart';

/// Provides a singleton [LockRepository] backed by [SharedPreferences].
///
/// Must be overridden in `main.dart` with a real [SharedPreferences] instance
/// (same pattern as [appSettingsProvider]).
final lockRepositoryProvider = Provider<LockRepository>((ref) {
  throw UnimplementedError('Override with a SharedPreferences-backed instance');
});

/// Constructs a [LockRepository] from an already-open [SharedPreferences].
/// Call this in `main.dart` to create the override.
LockRepository createLockRepository(SharedPreferences prefs) {
  return LockRepository(SecurityPreferences(prefs));
}
