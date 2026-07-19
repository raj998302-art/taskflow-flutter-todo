import 'dart:async';

/// APPLICATION-LEVEL session manager — the single source of truth for
/// "is the user currently authenticated".
///
/// Stored as a singleton (not in a Widget/Provider) so it survives Activity
/// recreation, BiometricPrompt lifecycle events, and config changes.
///
/// Tracks:
/// * [_isAuthenticated] — whether the user has unlocked the app this session
/// * [_isBiometricPromptShowing] — true while the system BiometricPrompt is
///   visible (Activity may receive onStop during this — must NOT auto-lock)
/// * [_isNavigatingToEnrollment] — true while we sent the user to phone
///   Settings to enroll biometrics (app goes to background — must NOT
///   auto-lock)
/// * [_wentToBackgroundAtMs] — timestamp of when the app was last backgrounded
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  // ── Core Authentication State ─────────────────────────────────────────────
  bool _isAuthenticated = false;

  // ── Background Tracking ───────────────────────────────────────────────────
  DateTime? _wentToBackgroundAt;

  // ── Special State Flags (prevent false auto-locks) ───────────────────────
  bool _isBiometricPromptShowing = false;
  bool _isNavigatingToEnrollment = false;

  // Stream so the router can react to session changes without polling.
  final _controller = StreamController<void>.broadcast();
  Stream<void> get onSessionChange => _controller.stream;

  // ── Public API ───────────────────────────────────────────────────────────

  /// Call this after successful biometric/PIN/pattern authentication.
  void onAuthenticated() {
    _isAuthenticated = true;
    _wentToBackgroundAt = null;
    _isBiometricPromptShowing = false;
    _isNavigatingToEnrollment = false;
    _controller.add(null);
  }

  /// Returns true if the user is currently authenticated and the session is
  /// still valid.
  ///
  /// With a zero grace period (default), any background trip invalidates the
  /// session — UNLESS the background was caused by the biometric prompt or
  /// enrollment flow.
  bool isSessionValid() {
    if (!_isAuthenticated) return false;

    // Don't lock if user is currently doing enrollment or bio prompt.
    if (_isBiometricPromptShowing || _isNavigatingToEnrollment) return true;

    // If went to background at some point (and not in special flow),
    // invalidate the session.
    if (_wentToBackgroundAt != null) {
      _isAuthenticated = false;
      _wentToBackgroundAt = null;
      _controller.add(null);
      return false;
    }
    return true;
  }

  /// Call from lifecycle observer onStop.
  void onAppGoingToBackground() {
    // CRITICAL: Do NOT mark background if biometric prompt is showing
    // or if we are navigating to enrollment settings.
    if (_isBiometricPromptShowing || _isNavigatingToEnrollment) {
      return; // ← This fixes auto-lock during bio prompt & enrollment
    }
    if (_isAuthenticated) {
      _wentToBackgroundAt = DateTime.now();
    }
  }

  /// Call from lifecycle observer onStart.
  void onAppComingToForeground() {
    // If returning from enrollment, clear the enrollment flag.
    // _wentToBackgroundAt should still be null (we didn't set it in onStop).
    _isNavigatingToEnrollment = false;
  }

  /// Call BEFORE showing the BiometricPrompt dialog.
  void onBiometricPromptStarting() {
    _isBiometricPromptShowing = true;
  }

  /// Call after the BiometricPrompt is dismissed (success, fail, or cancel).
  void onBiometricPromptDismissed() {
    _isBiometricPromptShowing = false;
  }

  /// Call BEFORE launching the enrollment Intent (going to phone Settings).
  void onStartingEnrollment() {
    _isNavigatingToEnrollment = true;
  }

  /// Call when returning from enrollment settings.
  void onEnrollmentComplete() {
    _isNavigatingToEnrollment = false;
  }

  /// Force logout / re-lock.
  void invalidateSession() {
    _isAuthenticated = false;
    _wentToBackgroundAt = null;
    _isBiometricPromptShowing = false;
    _isNavigatingToEnrollment = false;
    _controller.add(null);
  }

  /// Whether we're in enrollment flow (used to suppress lock screen).
  bool get isNavigatingToEnrollment => _isNavigatingToEnrollment;

  /// Whether the biometric prompt is showing (used to suppress background lock).
  bool get isBiometricPromptShowing => _isBiometricPromptShowing;

  void dispose() {
    _controller.close();
  }
}
