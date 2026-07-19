import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';

/// A numeric keypad for entering a 4–6 digit PIN.
///
/// Displays a row of dots that fill in as the user types, and a 3×4 grid of
/// circular number buttons (1–9, blank, 0, backspace). When [length] digits
/// have been entered, [onPinComplete] is invoked with the full string.
///
/// Set [error] to `true` to turn the dots red and shake the row — the parent
/// should set it back to `false` after clearing the entry (e.g. by calling
/// [PinKeypadState.clear] via a `GlobalKey<PinKeypadState>`).
///
/// If [onBiometricTap] is provided, a fingerprint icon button is shown on
/// the left of the bottom row.
class PinKeypad extends StatefulWidget {
  /// Creates a PIN keypad.
  const PinKeypad({
    super.key,
    required this.onPinComplete,
    this.length = 4,
    this.enabled = true,
    this.error = false,
    this.onBiometricTap,
  });

  /// Called when [length] digits have been entered.
  final ValueChanged<String> onPinComplete;

  /// Number of digits required (4 or 6). Defaults to 4.
  final int length;

  /// When `false`, taps are ignored.
  final bool enabled;

  /// When `true`, dots turn red and the row shakes.
  final bool error;

  /// Optional callback for the biometric fingerprint button.
  final VoidCallback? onBiometricTap;

  @override
  State<PinKeypad> createState() => PinKeypadState();
}

/// Public state for [PinKeypad] so parents can clear the entry via a key.
class PinKeypadState extends State<PinKeypad> {
  /// Digits entered so far.
  String _entered = '';

  /// Append a digit and fire [PinKeypad.onPinComplete] when full.
  void _addDigit(String digit) {
    if (!widget.enabled) return;
    if (_entered.length >= widget.length) return;
    setState(() => _entered += digit);
    if (_entered.length == widget.length) {
      // Defer the callback one frame so the final dot repaints first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPinComplete(_entered);
      });
    }
  }

  /// Remove the last entered digit.
  void _removeDigit() {
    if (!widget.enabled) return;
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  /// Reset the entered PIN.
  void clear() {
    setState(() => _entered = '');
  }

  Future<void> _handleDigit(String digit) async {
    await HapticFeedback.lightImpact();
    _addDigit(digit);
  }

  Future<void> _handleBackspace() async {
    await HapticFeedback.selectionClick();
    _removeDigit();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final Color dotFilled =
        widget.error ? AppColors.error : AppColors.primary;
    final Color dotHollow = colors.onSurfaceVariant.withValues(alpha: 0.4);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // ─── PIN dots ──────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(widget.length, (int i) {
            final bool filled = i < _entered.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? dotFilled : Colors.transparent,
                border: Border.all(
                  color: filled ? dotFilled : dotHollow,
                  width: 2,
                ),
              ),
            );
          }),
        )
            .animate(target: widget.error ? 1 : 0)
            .shake(duration: 400.ms, hz: 4)
            .fadeIn(duration: 200.ms),

        SizedBox(height: widget.onBiometricTap != null ? 24 : 32),

        // ─── Numpad ────────────────────────────────────────────────────────
        _NumpadGrid(
          onDigit: _handleDigit,
          onBackspace: _handleBackspace,
          onBiometric: widget.onBiometricTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  widget.onBiometricTap!();
                }
              : null,
          enabled: widget.enabled,
          showBiometric: widget.onBiometricTap != null,
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, end: 0, duration: 300.ms);
  }
}

/// The 3×4 numeric grid backing [PinKeypad].
///
/// Layout (left-to-right, top-to-bottom): 1 2 3 / 4 5 6 / 7 8 9 /
/// [biometric?] 0 backspace. Each cell is 64×64; the grid uses a 24px gap
/// both horizontally and vertically.
class _NumpadGrid extends StatelessWidget {
  const _NumpadGrid({
    required this.onDigit,
    required this.onBackspace,
    required this.onBiometric,
    required this.enabled,
    required this.showBiometric,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;
  final bool enabled;
  final bool showBiometric;

  static const double _gap = 24;
  static const List<List<String>> _rows = <List<String>>[
    <String>['1', '2', '3'],
    <String>['4', '5', '6'],
    <String>['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final List<Widget> rows = <Widget>[
      for (final List<String> row in _rows)
        Padding(
          padding: const EdgeInsets.only(bottom: _gap),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (final String d in row)
                _DigitButton(
                  d,
                  onTap: () => onDigit(d),
                  enabled: enabled,
                  theme: theme,
                ),
            ],
          ),
        ),
      Padding(
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            if (showBiometric)
              _IconButton(
                icon: Icons.fingerprint_rounded,
                color: AppColors.primary,
                onTap: onBiometric,
                enabled: enabled,
                theme: theme,
              )
            else
              const SizedBox(width: 64, height: 64),
            _DigitButton(
              '0',
              onTap: () => onDigit('0'),
              enabled: enabled,
              theme: theme,
            ),
            _IconButton(
              icon: Icons.backspace_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              onTap: onBackspace,
              enabled: enabled,
              theme: theme,
            ),
          ],
        ),
      ),
    ];

    return SizedBox(
      width: 64 * 3 + _gap * 2,
      child: Column(children: rows),
    );
  }
}

/// A circular digit button (64×64) with ripple feedback.
class _DigitButton extends StatelessWidget {
  const _DigitButton(
    this.label, {
    required this.onTap,
    required this.enabled,
    required this.theme,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                fontSize: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A circular icon button (64×64) used for backspace / biometric.
class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.enabled,
    required this.theme,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, color: color, size: 26),
        style: IconButton.styleFrom(
          backgroundColor:
              theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          foregroundColor: color,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}
