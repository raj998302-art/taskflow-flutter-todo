import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/lock_type.dart';

/// Persisted security settings for the app-lock feature.
///
/// Uses [SharedPreferences] to store the lock type, the salted hash of the
/// PIN/pattern, the salt itself, failed-attempt counters, and a lockout
/// timestamp. The raw secret is **never** stored — only its SHA-256 hash.
class SecurityPreferences {
  SecurityPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _keyLockEnabled = 'sec_lock_enabled';
  static const _keyLockType = 'sec_lock_type';
  static const _keyHash = 'sec_lock_hash';
  static const _keySalt = 'sec_lock_salt';
  static const _keyFailedAttempts = 'sec_failed_attempts';
  static const _keyLockoutUntil = 'sec_lockout_until';
  static const _keyBiometricFallback = 'sec_biometric_fallback';

  // ---- Lock enabled / disabled ----

  bool get isLockEnabled => _prefs.getBool(_keyLockEnabled) ?? false;

  Future<void> setLockEnabled(bool enabled) =>
      _prefs.setBool(_keyLockEnabled, enabled);

  // ---- Lock type ----

  LockType get lockType =>
      LockType.fromString(_prefs.getString(_keyLockType));

  Future<void> setLockType(LockType type) =>
      _prefs.setString(_keyLockType, type.value);

  // ---- Hash + salt (for PIN or Pattern) ----

  String? get storedHash => _prefs.getString(_keyHash);
  String? get storedSalt => _prefs.getString(_keySalt);

  Future<void> setHashAndSalt(String hash, String salt) async {
    await _prefs.setString(_keyHash, hash);
    await _prefs.setString(_keySalt, salt);
  }

  // ---- Failed attempts + lockout ----

  int get failedAttempts => _prefs.getInt(_keyFailedAttempts) ?? 0;

  Future<void> setFailedAttempts(int count) =>
      _prefs.setInt(_keyFailedAttempts, count);

  /// Epoch-millis timestamp until which the user is locked out (0 = no lockout).
  int get lockoutUntil => _prefs.getInt(_keyLockoutUntil) ?? 0;

  Future<void> setLockoutUntil(int epochMillis) =>
      _prefs.setInt(_keyLockoutUntil, epochMillis);

  // ---- Biometric fallback (show PIN pad when biometric fails) ----

  bool get biometricFallbackEnabled =>
      _prefs.getBool(_keyBiometricFallback) ?? true;

  Future<void> setBiometricFallback(bool enabled) =>
      _prefs.setBool(_keyBiometricFallback, enabled);

  // ---- Clear everything ----

  Future<void> clearAll() async {
    await _prefs.remove(_keyLockEnabled);
    await _prefs.remove(_keyLockType);
    await _prefs.remove(_keyHash);
    await _prefs.remove(_keySalt);
    await _prefs.remove(_keyFailedAttempts);
    await _prefs.remove(_keyLockoutUntil);
  }
}
