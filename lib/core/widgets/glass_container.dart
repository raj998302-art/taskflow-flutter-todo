import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A frosted-glass / glassmorphism container.
///
/// Renders a translucent surface blurred from the background using
/// [BackdropFilter]. The default tint adapts to light/dark themes via
/// [AppColors.glassLight] / [AppColors.glassDark] and a subtle 1px border is
/// drawn using [AppColors.glassBorderLight] / [AppColors.glassBorderDark].
///
/// Example:
/// ```dart
/// GlassContainer(
///   child: Text('Hello'),
/// )
/// ```
class GlassContainer extends StatelessWidget {
  /// Creates a frosted-glass container.
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.blur = 18,
    this.color,
    this.border,
    this.shadows,
    this.margin = EdgeInsets.zero,
  });

  /// The content rendered on top of the frosted surface.
  final Widget child;

  /// Inner padding applied to the inner [Container].
  final EdgeInsetsGeometry padding;

  /// Corner radius applied to the clip, container, and border.
  final BorderRadius borderRadius;

  /// Sigma used by the [ImageFilter.blur] backdrop filter.
  final double blur;

  /// Tint colour of the surface. Defaults to theme-aware glass colours.
  final Color? color;

  /// Optional custom [Border]. When `null`, a subtle 1px glass border is used.
  final Border? border;

  /// Optional list of box shadows drawn behind the surface.
  final List<BoxShadow>? shadows;

  /// Outer margin applied around the clip.
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color tint = color ??
        (isDark ? AppColors.glassDark : AppColors.glassLight);
    final Border resolvedBorder = border ??
        Border.all(
          color: isDark
              ? AppColors.glassBorderDark
              : AppColors.glassBorderLight,
          width: 1,
        );

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tint,
              border: resolvedBorder,
              borderRadius: borderRadius,
              boxShadow: shadows,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
