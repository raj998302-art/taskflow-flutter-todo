import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/biometric_service.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/glass_container.dart';

/// Full-screen biometric lock page shown when the app-lock feature is enabled.
///
/// Auto-prompts biometric authentication on init and exposes a manual unlock
/// button plus a fallback to disable app lock from settings. On success the
/// user is routed to `/home`; on failure the fingerprint icon shakes and a
/// SnackBar is shown.
class LockPage extends ConsumerStatefulWidget {
  /// Creates the biometric lock screen.
  const LockPage({super.key});

  @override
  ConsumerState<LockPage> createState() => _LockPageState();
}

class _LockPageState extends ConsumerState<LockPage> {
  bool _authenticating = false;
  bool _failed = false;
  bool _biometricsAvailable = true;
  bool _autoPrompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Probe availability once so we can render the fallback link.
      final available = await BiometricService.instance.isAvailable;
      if (!mounted) return;
      setState(() => _biometricsAvailable = available);
      if (available && !_autoPrompted) {
        _autoPrompted = true;
        _authenticate();
      }
    });
  }

  Future<void> _authenticate({String? reason}) async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _failed = false;
    });
    final ok = await BiometricService.instance.authenticate(
      reason: reason ?? 'Please authenticate to unlock Taskflow',
    );
    if (!mounted) return;
    if (ok) {
      context.go('/home');
      return;
    }
    setState(() {
      _authenticating = false;
      _failed = true;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Authentication failed. Try again.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _useDevicePin() async {
    // When biometricOnly is false (the default in BiometricService),
    // local_auth automatically falls back to device PIN/pattern/password.
    await _authenticate(
      reason: 'Use your device PIN or password to unlock Taskflow',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme text = context.textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              colors.surface,
              AppColors.primary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // 1. Pulsing app logo.
                    Image.asset(
                      'assets/images/app_logo.png',
                      width: 100,
                      height: 100,
                    )
                        .animate(
                          onPlay: (AnimationController c) =>
                              c.repeat(reverse: true),
                        )
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.05, 1.05),
                          duration: 1800.ms,
                        ),
                    const SizedBox(height: 24),
                    // 2. Title.
                    Text(
                      'Taskflow is locked',
                      style: text.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 3. Subtitle.
                    Text(
                      'Authenticate with your fingerprint or face to continue',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 4. Fingerprint icon button (80x80 glass circle).
                    GestureDetector(
                      onTap: _authenticating
                          ? null
                          : () => _authenticate(),
                      child: GlassContainer(
                        padding: EdgeInsets.zero,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(40),
                        ),
                        color: AppColors.primary.withValues(alpha: 0.12),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: Center(
                            child: _authenticating
                                ? const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.fingerprint_rounded,
                                    size: 40,
                                    color: AppColors.primary,
                                  ),
                          ),
                        ),
                      )
                          .animate(target: _failed ? 1 : 0)
                          .shake(duration: 400.ms),
                    ),
                    const SizedBox(height: 24),
                    // 5. Unlock button.
                    SizedBox(
                      width: double.infinity,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: FilledButton(
                          onPressed: _authenticating
                              ? null
                              : () => _authenticate(),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: _authenticating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Unlock'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 7. Use device PIN instead.
                    TextButton(
                      onPressed: _authenticating ? null : _useDevicePin,
                      child: const Text('Use device PIN instead'),
                    ),
                    // 6. Biometrics not available fallback.
                    if (!_biometricsAvailable) ...<Widget>[
                      const SizedBox(height: 16),
                      Text(
                        'Biometrics not available on this device',
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/settings'),
                        child: const Text('Disable app lock'),
                      ),
                    ],
                  ],
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.1, end: 0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
