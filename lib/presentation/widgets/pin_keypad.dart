import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';

/// A numeric keypad for entering a 4–6 digit PIN.
///
/// Displays a row of dots that fill in as the user types, and a 3×4 grid of
/// large circular number buttons (1–9, blank, 0, backspace). When [length]
/// digits have been entered, [onPinComplete] is invoked with the full string.
///
/// The keypad is **responsive** — button size is computed from the available
/// screen width so it fills the phone width naturally on every device.
///
/// Set [error] to `true` to turn the dots red and shake the row — the parent
/// should set it back to `false` after clearing the entry.
///
/// If [onBiometricTap] is provided, a fingerprint icon button is shown on
/// the left of the bottom row.
class PinKeypad extends StatefulWidget {
  const PinKeypad({
    super.key,
    required this.onPinComplete,
    this.length = 4,
    this.enabled = true,
    this.error = false,
    this.onBiometricTap,
  });

  final ValueChanged<String> onPinComplete;
  final int length;
  final bool enabled;
  final bool error;
  final VoidCallback? onBiometricTap;

  @override
  State<PinKeypad> createState() => PinKeypadState();
}

class PinKeypadState extends State<PinKeypad> {
  String _entered = '';

  void _addDigit(String digit) {
    if (!widget.enabled) return;
    if (_entered.length >= widget.length) return;
    setState(() => _entered += digit);
    if (_entered.length == widget.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPinComplete(_entered);
      });
    }
  }

  void _removeDigit() {
    if (!widget.enabled) return;
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

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

    // Responsive button size: fill up to 80% of screen width, 3 buttons per
    // row with 16px gaps. Max button size 80, min 56.
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth * 0.82;
    final buttonSize = ((availableWidth - 32) / 3).clamp(56.0, 80.0);
    final gap = (screenWidth * 0.04).clamp(12.0, 24.0);
    final fontSize = (buttonSize * 0.38).clamp(22.0, 30.0);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: buttonSize * 3 + gap * 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // ─── PIN dots ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(widget.length, (int i) {
              final bool filled = i < _entered.length;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: gap * 0.3),
                width: 18,
                height: 18,
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

          SizedBox(height: widget.onBiometricTap != null ? 32 : 40),

          // ─── Numpad ────────────────────────────────────────
          _NumpadGrid(
            buttonSize: buttonSize,
            gap: gap,
            fontSize: fontSize,
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
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, end: 0, duration: 300.ms);
  }
}

/// The 3×4 numeric grid backing [PinKeypad].
///
/// Layout (left-to-right, top-to-bottom): 1 2 3 / 4 5 6 / 7 8 9 /
/// [biometric?] 0 backspace. Button size is computed by the parent for
/// responsive layout.
class _NumpadGrid extends StatelessWidget {
  const _NumpadGrid({
    required this.buttonSize,
    required this.gap,
    required this.fontSize,
    required this.onDigit,
    required this.onBackspace,
    required this.onBiometric,
    required this.enabled,
    required this.showBiometric,
  });

  final double buttonSize;
  final double gap;
  final double fontSize;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;
  final bool enabled;
  final bool showBiometric;

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
          padding: EdgeInsets.only(bottom: gap),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (final String d in row)
                _DigitButton(
                  d,
                  size: buttonSize,
                  fontSize: fontSize,
                  onTap: () => onDigit(d),
                  enabled: enabled,
                  theme: theme,
                ),
            ],
          ),
        ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          if (showBiometric)
            _IconButton(
              icon: Icons.fingerprint_rounded,
              color: AppColors.primary,
              size: buttonSize,
              iconSize: buttonSize * 0.36,
              onTap: onBiometric,
              enabled: enabled,
              theme: theme,
            )
          else
            SizedBox(width: buttonSize, height: buttonSize),
          _DigitButton(
            '0',
            size: buttonSize,
            fontSize: fontSize,
            onTap: () => onDigit('0'),
            enabled: enabled,
            theme: theme,
          ),
          _IconButton(
            icon: Icons.backspace_rounded,
            color: theme.colorScheme.onSurfaceVariant,
            size: buttonSize,
            iconSize: buttonSize * 0.32,
            onTap: onBackspace,
            enabled: enabled,
            theme: theme,
          ),
        ],
      ),
    ];

    return Column(children: rows);
  }
}

/// A circular digit button with ripple feedback.
class _DigitButton extends StatelessWidget {
  const _DigitButton(
    this.label, {
    required this.size,
    required this.fontSize,
    required this.onTap,
    required this.enabled,
    required this.theme,
  });

  final String label;
  final double size;
  final double fontSize;
  final VoidCallback onTap;
  final bool enabled;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
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
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A circular icon button used for backspace / biometric.
class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
    required this.onTap,
    required this.enabled,
    required this.theme,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final VoidCallback? onTap;
  final bool enabled;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, color: color, size: iconSize),
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
