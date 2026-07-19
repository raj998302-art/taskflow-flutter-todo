import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A premium loading indicator composed of three pulsing dots.
///
/// The dots are staggered with [flutter_animate]'s [AnimateThen] extension
/// (`then(delay:)`) to create a gentle "wave" pulse that loops infinitely.
/// An optional caption can be shown beneath the dots.
///
/// Example:
/// ```dart
/// AppLoading(label: 'Loading tasks…')
/// ```
class AppLoading extends StatelessWidget {
  /// Creates a loading indicator.
  const AppLoading({
    super.key,
    this.size = 48,
    this.color,
    this.label,
  });

  /// Diameter of the bounding row of dots. Individual dots scale relative to
  /// this size so the widget stays balanced at any dimension.
  final double size;

  /// Colour of the dots. Defaults to the theme's primary colour.
  final Color? color;

  /// Optional caption rendered beneath the dots.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color dotColor = color ?? theme.colorScheme.primary;
    final double dotSize = (size * 0.25).clamp(8.0, 16.0);

    Widget buildDot(int index) {
      // Each dot starts its pulse loop staggered by 150ms to create a wave.
      return Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
        ),
      )
          .animate(
            delay: (index * 150).ms,
            onPlay: (AnimationController c) => c.repeat(reverse: true),
          )
          .scale(
            duration: 900.ms,
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.6, 1.6),
          );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: size,
            height: size,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                buildDot(0),
                buildDot(1),
                buildDot(2),
              ],
            ),
          ),
          if (label != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              label!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
