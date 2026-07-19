import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/biometric_service.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/glass_container.dart';
import '../../domain/entities/lock_type.dart';
import '../providers/lock_provider.dart';
import '../widgets/pattern_lock_view.dart';
import '../widgets/pin_keypad.dart';
import '../../router/app_router.dart';

/// Guided setup flow for the app-lock feature.
///
/// The user picks a lock type (Biometric / Pattern / PIN), then enrolls their
/// secret (for pattern/PIN, they must enter it twice to confirm). On success
/// the lock is enabled and the user is returned to the previous screen.
class LockSetupPage extends ConsumerStatefulWidget {
  const LockSetupPage({super.key});

  @override
  ConsumerState<LockSetupPage> createState() => _LockSetupPageState();
}

class _LockSetupPageState extends ConsumerState<LockSetupPage> {
  LockType _selectedType = LockType.none;
  _SetupPhase _phase = _SetupPhase.choose;
  String? _firstEntry; // first PIN/pattern entered (for confirmation)
  String? _error;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(
              title: _phaseTitle,
              onBack: _onBack,
            ),
            Expanded(
              child: _phase == _SetupPhase.enroll ||
                      _phase == _SetupPhase.confirm
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: _buildPhase(),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: _buildPhase(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String get _phaseTitle {
    switch (_phase) {
      case _SetupPhase.choose:
        return 'Choose Lock Type';
      case _SetupPhase.enroll:
        return 'Set ${_selectedType.label}';
      case _SetupPhase.confirm:
        return 'Confirm ${_selectedType.label}';
      case _SetupPhase.done:
        return 'Lock Enabled';
    }
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _SetupPhase.choose:
        return _ChoosePhase(
          onSelected: _onTypeSelected,
        );
      case _SetupPhase.enroll:
      case _SetupPhase.confirm:
        return _EnrollPhase(
          type: _selectedType,
          phase: _phase,
          error: _error,
          onPatternComplete: _onPatternComplete,
          onPinComplete: _onPinComplete,
          onBiometricSetup: _setupBiometric,
          busy: _busy,
        );
      case _SetupPhase.done:
        return _DonePhase(type: _selectedType, onDone: () => context.pop());
    }
  }

  // ---- Flow logic ----

  void _onTypeSelected(LockType type) {
    setState(() {
      _selectedType = type;
      _error = null;
      _firstEntry = null;
    });
    if (type == LockType.biometric) {
      // Transition to enroll phase so the UI shows the biometric prompt.
      setState(() => _phase = _SetupPhase.enroll);
      // Auto-trigger biometric after a short delay so the UI renders first.
      WidgetsBinding.instance.addPostFrameCallback((_) => _setupBiometric());
    } else if (type == LockType.pattern || type == LockType.pin) {
      setState(() => _phase = _SetupPhase.enroll);
    } else {
      // None — disable lock and go back
      ref.read(lockRepositoryProvider).disableLock();
      context.pop();
    }
  }

  Future<void> _setupBiometric() async {
    setState(() => _busy = true);
    final available = await BiometricService.instance.isAvailable;
    if (!available) {
      setState(() {
        _error = 'Biometrics not available on this device';
        _busy = false;
      });
      return;
    }
    final ok = await BiometricService.instance.authenticate(
      reason: 'Confirm to enable biometric lock',
    );
    if (ok) {
      await ref.read(lockRepositoryProvider).enableLock(LockType.biometric);
      // Clear the should-lock flag so the router doesn't immediately redirect
      // to the lock screen after setup. Lock should only trigger on NEXT app
      // open or resume from background.
      clearShouldLock();
      if (mounted) setState(() => _phase = _SetupPhase.done);
    } else {
      setState(() => _error = 'Biometric authentication failed');
    }
    setState(() => _busy = false);
  }

  void _onPatternComplete(List<int> pattern) {
    if (pattern.length < 4) {
      setState(() => _error = 'Pattern too short (min 4 dots)');
      return;
    }
    final str = pattern.join('-');
    if (_phase == _SetupPhase.enroll) {
      _firstEntry = str;
      setState(() {
        _phase = _SetupPhase.confirm;
        _error = null;
      });
    } else {
      if (str == _firstEntry) {
        _saveSecret(str);
      } else {
        setState(() {
          _error = 'Patterns don\'t match. Try again.';
          _phase = _SetupPhase.enroll;
          _firstEntry = null;
        });
      }
    }
  }

  void _onPinComplete(String pin) {
    if (_phase == _SetupPhase.enroll) {
      _firstEntry = pin;
      setState(() {
        _phase = _SetupPhase.confirm;
        _error = null;
      });
    } else {
      if (pin == _firstEntry) {
        _saveSecret(pin);
      } else {
        setState(() {
          _error = 'PINs don\'t match. Try again.';
          _phase = _SetupPhase.enroll;
          _firstEntry = null;
        });
      }
    }
  }

  Future<void> _saveSecret(String secret) async {
    setState(() => _busy = true);
    await ref
        .read(lockRepositoryProvider)
        .enableLock(_selectedType, secret: secret);
    // Clear should-lock so router doesn't immediately force lock screen.
    clearShouldLock();
    if (mounted) setState(() => _phase = _SetupPhase.done);
    setState(() => _busy = false);
  }

  void _onBack() {
    if (_phase == _SetupPhase.choose) {
      context.pop();
    } else if (_phase == _SetupPhase.done) {
      context.pop();
    } else {
      setState(() {
        _phase = _SetupPhase.choose;
        _firstEntry = null;
        _error = null;
      });
    }
  }
}

enum _SetupPhase { choose, enroll, confirm, done }

// ---------------------------------------------------------------------------
// Phase widgets
// ---------------------------------------------------------------------------

class _ChoosePhase extends StatelessWidget {
  const _ChoosePhase({required this.onSelected});
  final ValueChanged<LockType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select how you want to lock Taskflow. You can change this anytime in Settings.',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        for (final type in [
          LockType.biometric,
          LockType.pattern,
          LockType.pin,
        ]) ...[
          _LockTypeCard(
            type: type,
            onTap: () => onSelected(type),
          ),
          const SizedBox(height: 12),
        ],
        _LockTypeCard(
          type: LockType.none,
          subtitle: 'Disable app lock',
          onTap: () => onSelected(LockType.none),
        ),
      ],
    );
  }
}

class _LockTypeCard extends StatelessWidget {
  const _LockTypeCard({
    required this.type,
    required this.onTap,
    this.subtitle,
  });
  final LockType type;
  final VoidCallback onTap;
  final String? subtitle;

  IconData get _icon {
    switch (type) {
      case LockType.biometric:
        return Icons.fingerprint_rounded;
      case LockType.pattern:
        return Icons.pattern_rounded;
      case LockType.pin:
        return Icons.password_rounded;
      case LockType.none:
        return Icons.lock_open_rounded;
    }
  }

  Color get _color {
    switch (type) {
      case LockType.biometric:
        return AppColors.success;
      case LockType.pattern:
        return AppColors.primary;
      case LockType.pin:
        return AppColors.accent;
      case LockType.none:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: _color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle ?? type.description,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: context.colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 80.ms, duration: 300.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

class _EnrollPhase extends StatelessWidget {
  const _EnrollPhase({
    required this.type,
    required this.phase,
    required this.error,
    required this.onPatternComplete,
    required this.onPinComplete,
    required this.onBiometricSetup,
    required this.busy,
  });
  final LockType type;
  final _SetupPhase phase;
  final String? error;
  final ValueChanged<List<int>> onPatternComplete;
  final ValueChanged<String> onPinComplete;
  final VoidCallback onBiometricSetup;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    // ---- Biometric enroll ----
    if (type == LockType.biometric) {
      return FutureBuilder<String>(
        future: BiometricService.instance.availableBiometricsDescription,
        builder: (context, snapshot) {
          final available = snapshot.data ?? '...';
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Authenticate to enable biometric lock',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Available: $available',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Use your fingerprint or face to confirm. Taskflow will require this every time you open the app.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    error!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (busy)
                const CircularProgressIndicator()
              else
                GestureDetector(
                  onTap: onBiometricSetup,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (!busy)
                TextButton(
                  onPressed: onBiometricSetup,
                  child: const Text('Tap to authenticate'),
                ),
            ],
          );
        },
      );
    }

    // ---- Pattern / PIN enroll ----
    final prompt = phase == _SetupPhase.enroll
        ? 'Confirm your ${type.label.toLowerCase()}'
        : 'Confirm your ${type.label.toLowerCase()}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          phase == _SetupPhase.enroll
              ? (type == LockType.pattern
                  ? 'Draw a pattern (min 4 dots)'
                  : 'Enter a 4-digit PIN')
              : prompt,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (phase == _SetupPhase.confirm)
          Text(
            'Re-enter to confirm',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              error!,
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 24),
        if (busy)
          const CircularProgressIndicator()
        else if (type == LockType.pattern)
          PatternLockView(onPatternComplete: onPatternComplete)
        else if (type == LockType.pin)
          PinKeypad(
            onPinComplete: onPinComplete,
            error: error != null,
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _DonePhase extends StatelessWidget {
  const _DonePhase({required this.type, required this.onDone});
  final LockType type;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 44),
            )
                .animate()
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
            const SizedBox(height: 20),
            Text(
              '${type.label} lock enabled!',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Taskflow will now require ${type.label.toLowerCase()} authentication on launch.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onDone,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _AppBar extends StatelessWidget {
  const _AppBar({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
          ),
          Text(
            title,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
