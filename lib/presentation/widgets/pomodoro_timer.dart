import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/glass_container.dart';

/// A compact Pomodoro focus timer rendered inside a [GlassContainer].
///
/// Implements the classic 25 minute work / 5 minute break cycle. A circular
/// progress ring shows the elapsed portion of the current phase, a large
/// `MM:SS` readout sits in the centre, and a row of reset / play-pause / skip
/// controls drives the timer. A small "🍅 × n" sessions counter in the header
/// scales up the first time a work session completes, and the phase label
/// ("Work" / "Break") cross-fades whenever the phase switches.
///
/// The widget is self-contained — embed it directly in any dashboard or
/// task-detail page:
///
/// ```dart
/// PomodoroTimer(),
/// ```
class PomodoroTimer extends ConsumerStatefulWidget {
  const PomodoroTimer({super.key});

  @override
  ConsumerState<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends ConsumerState<PomodoroTimer> {
  final int _workMinutes = 25;
  final int _breakMinutes = 5;

  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isWorkPhase = true;
  Timer? _timer;
  int _completedSessions = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  /// Total seconds in the current phase — used to drive the progress ring.
  int get _totalForPhase =>
      (_isWorkPhase ? _workMinutes : _breakMinutes) * 60;

  /// Fraction of the current phase that has elapsed (`0 → 1`).
  double get _progress => 1 - (_remainingSeconds / _totalForPhase);

  /// Start the periodic 1-second countdown timer.
  ///
  /// Each tick decrements [_remainingSeconds]; when it hits zero the phase
  /// flips — a completed work session increments [_completedSessions] and a
  /// haptic fires, then the timer continues into the next phase.
  void _start() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      bool workCompleted = false;
      setState(() {
        _remainingSeconds -= 1;
        if (_remainingSeconds <= 0) {
          if (_isWorkPhase) {
            _completedSessions += 1;
            _isWorkPhase = false;
            _remainingSeconds = _breakMinutes * 60;
            workCompleted = true;
          } else {
            _isWorkPhase = true;
            _remainingSeconds = _workMinutes * 60;
          }
        }
      });
      if (workCompleted) {
        HapticFeedback.heavyImpact();
      }
    });
    setState(() => _isRunning = true);
  }

  /// Pause the countdown without resetting the remaining time.
  void _pause() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isRunning = false);
  }

  /// Cancel and return to the start of a fresh work phase.
  void _reset() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
      _isWorkPhase = true;
      _remainingSeconds = _workMinutes * 60;
    });
  }

  /// Skip straight to the other phase, resetting the remaining time.
  void _skip() {
    setState(() {
      if (_isWorkPhase) {
        _isWorkPhase = false;
        _remainingSeconds = _breakMinutes * 60;
      } else {
        _isWorkPhase = true;
        _remainingSeconds = _workMinutes * 60;
      }
    });
  }

  /// Format [seconds] as `MM:SS` with leading zeros.
  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final Color phaseColor =
        _isWorkPhase ? AppColors.primary : AppColors.success;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: icon + title + sessions counter.
          Row(
            children: [
              Icon(
                Icons.timer_rounded,
                size: 20,
                color: phaseColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Focus Timer',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '🍅 × $_completedSessions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              )
                  .animate(
                    target: _completedSessions > 0 ? 1 : 0,
                  )
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                    duration: 300.ms,
                  ),
            ],
          ),
          const SizedBox(height: 16),
          // Circular countdown ring with time + phase label.
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 8,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _format(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: child,
                      ),
                      child: Text(
                        _isWorkPhase ? 'Work' : 'Break',
                        key: ValueKey(_isWorkPhase),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Reset / play-pause / skip controls.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _reset,
                tooltip: 'Reset',
                icon: const Icon(Icons.restart_alt_rounded),
                color: scheme.onSurfaceVariant,
              ),
              FilledButton.icon(
                onPressed: _isRunning ? _pause : _start,
                icon: Icon(
                  _isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(_isRunning ? 'Pause' : 'Start'),
              ),
              IconButton(
                onPressed: _skip,
                tooltip: 'Skip',
                icon: const Icon(Icons.skip_next_rounded),
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '$_workMinutes min focus · $_breakMinutes min break',
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05);
  }
}
