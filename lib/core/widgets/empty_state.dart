import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'glass_container.dart';

/// A beautifully animated empty-state illustration with an icon, title,
/// optional subtitle and optional call-to-action button.
///
/// Use this widget for any list / screen that can have no data — for example
/// an empty task list, an empty search result, or a fresh statistics page.
///
/// The icon is rendered inside a circular frosted-glass container with a soft
/// radial gradient backdrop. The whole widget fades and scales in on first
/// build using [flutter_animate].
class AppEmptyState extends StatelessWidget {
  /// Creates an empty-state placeholder.
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  /// Large icon displayed in the centre of the circular container.
  final IconData icon;

  /// Bold headline of the empty state.
  final String title;

  /// Optional supporting copy shown beneath the title.
  final String? subtitle;

  /// Optional label for the call-to-action button.
  final String? actionLabel;

  /// Invoked when the call-to-action button is pressed.
  final VoidCallback? onAction;

  /// Colour of the icon. Defaults to the theme primary colour.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color resolvedIconColor =
        iconColor ?? theme.colorScheme.primary;
    final bool isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Icon medallion with soft gradient + frosted glass overlay.
              Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[
                          resolvedIconColor.withValues(alpha: 0.35),
                          resolvedIconColor.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                  GlassContainer(
                    padding: EdgeInsets.zero,
                    borderRadius: const BorderRadius.all(Radius.circular(72)),
                    blur: 14,
                    child: Container(
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        size: 44,
                        color: resolvedIconColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...<Widget>[
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.9, 0.9));
  }
}
