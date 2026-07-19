import '../../core/utils/crypto_utils.dart';
import '../../domain/entities/lock_type.dart';
import 'security_preferences.dart';

/// Business logic for the app-lock feature.
///
/// Acts as the single source of truth for: enabling/disabling a lock,
/// verifying PIN/pattern secrets, tracking failed attempts, and enforcing
/// a temporary lockout after too many failures.
class LockRepository {
  LockRepository(this._prefs);

  final SecurityPreferences _prefs;

  /// Maximum failed attempts before a lockout is triggered.
  static const maxFailedAttempts = 5;

  /// Lockout duration in milliseconds (30 seconds).
  static const lockoutDurationMs = 30 * 1000;

  // ---- Queries ----

  bool get isLockEnabled => _prefs.isLockEnabled;
  LockType get lockType => _prefs.lockType;
  bool get hasSecret =>
      _prefs.storedHash != null && _prefs.storedSalt != null;

  /// True if the user is currently in a lockout period.
  bool get isLockedOut {
    final until = _prefs.lockoutUntil;
    if (until == 0) return false;
    return DateTime.now().millisecondsSinceEpoch < until;
  }

  /// Seconds remaining in the current lockout (0 if not locked out).
  int get lockoutSecondsRemaining {
    final until = _prefs.lockoutUntil;
    if (until == 0) return 0;
    final remaining =
        (until - DateTime.now().millisecondsSinceEpoch) ~/ 1000;
    return remaining > 0 ? remaining : 0;
  }

  int get failedAttempts => _prefs.failedAttempts;

  /// Whether to show a PIN fallback when biometric authentication fails.
  bool get biometricFallbackEnabled => _prefs.biometricFallbackEnabled;

  // ---- Enable / Disable ----

  /// Enables a lock of the given [type]. For PIN/pattern, [secret] is the
  /// raw value (e.g. "1234" or "0-1-2-5") — it is hashed+salted before
  /// storage. For biometric, [secret] can be null.
  Future<void> enableLock(LockType type, {String? secret}) async {
    await _prefs.setLockType(type);
    if (type == LockType.pin || type == LockType.pattern) {
      if (secret == null || secret.isEmpty) {
        throw ArgumentError('Secret required for ${type.label} lock');
      }
      final salt = CryptoUtils.generateSalt();
      final hash = CryptoUtils.hashWithSalt(secret, salt);
      await _prefs.setHashAndSalt(hash, salt);
    }
    await _prefs.setLockEnabled(true);
    await _prefs.setFailedAttempts(0);
    await _prefs.setLockoutUntil(0);
  }

  /// Disables the lock entirely and clears all stored secrets.
  Future<void> disableLock() async {
    await _prefs.clearAll();
  }

  // ---- Verification ----

  /// Verifies a PIN string against the stored hash.
  /// Returns true on success, false on mismatch.
  /// Automatically records failed attempts and triggers lockout if needed.
  Future<bool> verifyPin(String pin) async {
    return _verifySecret(pin);
  }

  /// Verifies a pattern (list of node indices) against the stored hash.
  Future<bool> verifyPattern(List<int> pattern) async {
    return _verifySecret(CryptoUtils.patternToString(pattern));
  }

  Future<bool> _verifySecret(String secret) async {
    final hash = _prefs.storedHash;
    final salt = _prefs.storedSalt;
    if (hash == null || salt == null) return false;

    final ok = CryptoUtils.verify(secret, hash, salt);
    if (ok) {
      await _prefs.setFailedAttempts(0);
      await _prefs.setLockoutUntil(0);
    } else {
      await _recordFailedAttempt();
    }
    return ok;
  }

  /// Records a failed attempt. After [maxFailedAttempts], triggers a lockout.
  Future<void> _recordFailedAttempt() async {
    final attempts = _prefs.failedAttempts + 1;
    await _prefs.setFailedAttempts(attempts);
    if (attempts >= maxFailedAttempts) {
      final until =
          DateTime.now().millisecondsSinceEpoch + lockoutDurationMs;
      await _prefs.setLockoutUntil(until);
    }
  }

  /// Manually resets the failed-attempt counter (e.g. after a successful
  /// biometric unlock).
  Future<void> resetFailedAttempts() async {
    await _prefs.setFailedAttempts(0);
    await _prefs.setLockoutUntil(0);
  }
}
