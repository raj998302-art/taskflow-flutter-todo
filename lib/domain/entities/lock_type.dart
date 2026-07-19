/// The type of app lock the user has chosen.
///
/// Stored as a string in [SharedPreferences]; the enum provides type safety.
enum LockType {
  /// No lock — app opens directly.
  none('none'),

  /// Fingerprint or face unlock via the platform's BiometricPrompt.
  biometric('biometric'),

  /// 3×3 connect-the-dots pattern (drawn on a custom canvas).
  pattern('pattern'),

  /// 4–6 digit numeric PIN entered on a custom keypad.
  pin('pin');

  const LockType(this.value);
  final String value;

  static LockType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'biometric':
        return LockType.biometric;
      case 'pattern':
        return LockType.pattern;
      case 'pin':
        return LockType.pin;
      default:
        return LockType.none;
    }
  }

  /// Human-readable label shown in the UI.
  String get label {
    switch (this) {
      case LockType.biometric:
        return 'Biometric';
      case LockType.pattern:
        return 'Pattern';
      case LockType.pin:
        return 'PIN';
      case LockType.none:
        return 'None';
    }
  }

  /// Short description shown in the settings list.
  String get description {
    switch (this) {
      case LockType.biometric:
        return 'Fingerprint or face unlock';
      case LockType.pattern:
        return '3×3 connect-the-dots pattern';
      case LockType.pin:
        return '4–6 digit numeric code';
      case LockType.none:
        return 'No lock';
    }
  }
}
