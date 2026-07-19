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
}
