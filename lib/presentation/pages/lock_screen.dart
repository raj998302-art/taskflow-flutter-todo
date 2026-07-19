import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/biometric_service.dart';
import '../../core/utils/extensions.dart';
import '../../domain/entities/lock_type.dart';
import '../providers/lock_provider.dart';
import '../widgets/pattern_lock_view.dart';
import '../widgets/pin_keypad.dart';
import '../../router/app_router.dart';

/// The verification lock screen shown on app launch (and resume) when a lock
/// is enabled.
///
/// Detects the configured [LockType] and renders the appropriate verification
/// UI:
/// * **Biometric** — auto-prompts on appear; a fingerprint button re-prompts.
/// * **Pattern** — shows the 3×3 pattern grid.
/// * **PIN** — shows the numeric keypad.
///
/// Tracks failed attempts via [LockRepository]. After 5 failures, a 30-second
/// lockout is enforced with a countdown.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _busy = false;
  bool _error = false;
  Timer? _lockoutTimer;
  int _lockoutRemaining = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final repo = ref.read(lockRepositoryProvider);
    if (repo.isLockedOut) {
      _startLockoutCountdown(repo.lockoutSecondsRemaining);
      return;
    }
    if (repo.lockType == LockType.biometric) {
      await _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    if (_busy) return;
    setState(() => _busy = true);
    final available = await BiometricService.instance.isAvailable;
    if (!available) {
      setState(() => _busy = false);
      // Fall back to PIN if biometric is unavailable and a PIN is set.
      return;
    }
    final ok = await BiometricService.instance.authenticate(
      reason: 'Unlock Taskflow',
    );
    if (ok) {
      await ref.read(lockRepositoryProvider).resetFailedAttempts();
      clearShouldLock();
      if (mounted) context.go('/home');
    } else {
      setState(() => _busy = false);
    }
  }

  Future<void> _onPinComplete(String pin) async {
    final repo = ref.read(lockRepositoryProvider);
    final ok = await repo.verifyPin(pin);
    if (ok) {
      clearShouldLock();
      if (mounted) context.go('/home');
    } else {
      _onFailed();
    }
  }

  Future<void> _onPatternComplete(List<int> pattern) async {
    final repo = ref.read(lockRepositoryProvider);
    final ok = await repo.verifyPattern(pattern);
    if (ok) {
      clearShouldLock();
      if (mounted) context.go('/home');
    } else {
      _onFailed();
    }
  }

  void _onFailed() {
    setState(() => _error = true);
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _error = false);
    });
    // Check if we just hit the lockout threshold.
    final repo = ref.read(lockRepositoryProvider);
    if (repo.isLockedOut) {
      _startLockoutCountdown(repo.lockoutSecondsRemaining);
    }
  }

  void _startLockoutCountdown(int seconds) {
    setState(() {
      _lockoutRemaining = seconds;
      _busy = false;
    });
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _lockoutRemaining--);
      if (_lockoutRemaining <= 0) {
        t.cancel();
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(lockRepositoryProvider);
    final type = repo.lockType;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.colors.surface,
                AppColors.primary.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lock icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.05, 1.05),
                          duration: 2000.ms,
                        ),
                    const SizedBox(height: 20),
                    Text(
                      'Taskflow is locked',
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _subtitle(type),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Lockout or verification UI
                    if (_lockoutRemaining > 0)
                      _LockoutView(seconds: _lockoutRemaining)
                    else if (_busy)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      )
                    else ...[
                      if (type == LockType.pattern)
                        PatternLockView(
                          onPatternComplete: _onPatternComplete,
                          enabled: !_error,
                        )
                      else if (type == LockType.pin)
                        PinKeypad(
                          onPinComplete: _onPinComplete,
                          error: _error,
                          onBiometricTap: repo.biometricFallbackEnabled
                              ? _tryBiometric
                              : null,
                        )
                      else if (type == LockType.biometric) ...[
                        _BiometricButton(onTap: _tryBiometric),
                        const SizedBox(height: 16),
                        if (repo.hasSecret &&
                            repo.lockType == LockType.biometric)
                          TextButton(
                            onPressed: () {
                              // TODO: could show PIN fallback if one is set
                            },
                            child: const Text('Use PIN instead'),
                          ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms);
  }

  String _subtitle(LockType type) {
    switch (type) {
      case LockType.biometric:
        return 'Authenticate with your fingerprint or face to continue';
      case LockType.pattern:
        return 'Draw your pattern to unlock';
      case LockType.pin:
        return 'Enter your PIN to unlock';
      case LockType.none:
        return '';
    }
  }
}

class _BiometricButton extends StatelessWidget {
  const _BiometricButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.fingerprint_rounded,
          size: 44,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _LockoutView extends StatelessWidget {
  const _LockoutView({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_off_rounded, size: 48, color: AppColors.error),
        const SizedBox(height: 16),
        Text(
          'Too many failed attempts',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Try again in ${seconds}s',
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
