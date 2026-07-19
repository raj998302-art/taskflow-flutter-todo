import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'session_manager.dart';

/// Wrapper around [local_auth] for fingerprint / face unlock.
///
/// Uses `biometricOnly: false` so the system shows ALL enrolled biometrics
/// (fingerprint + face + iris) plus device credential as fallback. The OS
/// decides which biometric to use based on what the user has enrolled.
///
/// Coordinates with [SessionManager] so that:
/// * When the BiometricPrompt is showing, the app does NOT auto-lock (Android
///   can fire onStop while the system dialog is visible).
/// * When we send the user to phone Settings for enrollment, the app does NOT
///   auto-lock on the background trip.
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

  /// Prompts the user to authenticate with biometrics. Returns true on success.
  ///
  /// Notifies [SessionManager] when the prompt starts and is dismissed so
  /// auto-lock does not trigger during authentication.
  Future<bool> authenticate({
    String reason = 'Please authenticate to unlock Taskflow',
  }) async {
    try {
      // Tell SessionManager the biometric prompt is about to show.
      SessionManager.instance.onBiometricPromptStarting();
      final result = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
      // Prompt dismissed (success, fail, or cancel).
      SessionManager.instance.onBiometricPromptDismissed();
      return result;
    } on PlatformException catch (e) {
      // Make sure flag is cleared even on exception.
      SessionManager.instance.onBiometricPromptDismissed();
      debugPrint('Biometric auth failed: ${e.code} — ${e.message}');
      return false;
    }
  }

  /// Opens the phone's biometric/security enrollment settings.
  ///
  /// Sets the [SessionManager] enrollment flag BEFORE launching so that the
  /// app does NOT auto-lock when it goes to the background.
  Future<void> openEnrollmentSettings() async {
    // CRITICAL: Set enrollment flag before going to background.
    SessionManager.instance.onStartingEnrollment();
    try {
      // Android: ACTION_SECURITY_SETTINGS (covers fingerprint + face enrollment)
      // We use url_launcher as a fallback since local_auth doesn't expose
      // the enrollment intent directly from Dart.
      final uri = Uri.parse('android.settings.SETTINGS');
      await launchUrl(uri);
    } catch (e) {
      debugPrint('Could not open enrollment settings: $e');
      SessionManager.instance.onEnrollmentComplete();
    }
  }
}
