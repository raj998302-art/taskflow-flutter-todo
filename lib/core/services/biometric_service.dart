import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Wrapper around [local_auth] for fingerprint / face unlock.
///
/// Used by the app-lock feature: when enabled in Settings, the app prompts for
/// biometrics on launch (and re-prompts after being backgrounded).
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// True if the device has biometric hardware enrolled (fingerprint / face).
  Future<bool> get isAvailable async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Lists the biometric types enrolled on the device.
  Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return const <BiometricType>[];
    }
  }

  /// Prompts the user to authenticate with biometrics. Returns true on success.
  ///
  /// Uses `biometricOnly: false` so the system shows ALL enrolled biometrics
  /// (fingerprint AND face AND iris) plus device credential as fallback.
  /// The OS decides which biometric to use based on what the user has enrolled
  /// in their device Settings — we can't force one over the other.
  Future<bool> authenticate({String reason = 'Please authenticate to unlock Taskflow'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric auth failed: ${e.code} — ${e.message}');
      return false;
    }
  }

  /// Returns a human-readable list of available biometric types for display.
  /// e.g. "Fingerprint, Face" or "Fingerprint only".
  Future<String> get availableBiometricsDescription async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      if (biometrics.isEmpty) return 'None';
      final names = <String>[];
      for (final b in biometrics) {
        switch (b) {
          case BiometricType.fingerprint:
            names.add('Fingerprint');
            break;
          case BiometricType.face:
            names.add('Face');
            break;
          case BiometricType.iris:
            names.add('Iris');
            break;
          default:
            break;
        }
      }
      return names.isEmpty ? 'None' : names.join(', ');
    } catch (_) {
      return 'Unknown';
    }
  }
}
