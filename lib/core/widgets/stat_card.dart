import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'glass_container.dart';

/// A statistics dashboard card.
///
/// Displays a labelled metric — for example "Completed", "12" — alongside an
/// icon in a tinted square. The card uses [GlassContainer] by default. When
/// [isPrimary] is `true` the card switches to a solid gradient background
/// using [color] with white text.
///
/// Tap interactions are delegated to [onTap]; the whole card is wrapped in an
/// [InkWell] with a matching border radius so the ripple is contained.
class StatCard extends StatelessWidget {
  /// Creates a statistics card.
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
    this.isPrimary = false,
  });

  /// Short metric label (e.g. "Completed").
  final String label;

  /// Headline metric value (e.g. "12").
  final String value;

  /// Decorative icon drawn inside the tinted square.
  final IconData icon;

  /// Accent colour used for the icon, icon background, and (when primary) the
  /// gradient background.
  final Color color;

  /// Optional small caption rendered beneath the label.
  final String? subtitle;

  /// Optional tap handler.
  final VoidCallback? onTap;

  /// When `true`, the card uses a solid gradient background and white text.
  final bool isPrimary;

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color onCardColor = isPrimary
        ? Colors.white
        : theme.colorScheme.onSurface;

    final Color labelColor = isPrimary
        ? Colors.white.withValues(alpha: 0.9)
        : theme.colorScheme.onSurfaceVariant;

    final Widget iconTile = Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isPrimary
            ? Colors.white.withValues(alpha: 0.2)
            : color.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      child: Icon(
        icon,
        size: 24,
        color: isPrimary ? Colors.white : color,
      ),
    );

    final Widget content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          iconTile,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: onCardColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: labelColor,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: labelColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final Widget card = isPrimary
        ? Container(
            decoration: BoxDecoration(
              borderRadius: _radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  color,
                  color.withValues(alpha: 0.6),
                ],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: content,
          )
        : GlassContainer(
            padding: EdgeInsets.zero,
            borderRadius: _radius,
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.55),
            shadows: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            child: content,
          );

    final Widget interactive = onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius: _radius,
            child: card,
          )
        : card;

    return interactive
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, end: 0);
  }
}
