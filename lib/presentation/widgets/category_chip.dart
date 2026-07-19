import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/task_enums.dart';

/// Maps a [TaskCategory] to its brand color from [AppColors].
Color _categoryColor(TaskCategory category) {
  switch (category) {
    case TaskCategory.personal:
      return AppColors.personal;
    case TaskCategory.work:
      return AppColors.work;
    case TaskCategory.shopping:
      return AppColors.shopping;
    case TaskCategory.health:
      return AppColors.health;
    case TaskCategory.other:
      return AppColors.other;
  }
}

/// A selectable pill representing a single [TaskCategory].
///
/// When [selected] is true, the chip fills with the category's accent color and
/// shows a check icon next to the label. When unselected, it shows a small
/// colored dot (8×8) and the category label on a subtle surface tint. An
/// optional [count] badge can be displayed to indicate the number of tasks in
/// the category.
///
/// Used by the home screen's category filter strip and the add-task sheet.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    this.selected = false,
    this.onTap,
    this.showCount = false,
    this.count,
  });

  /// The category this chip represents.
  final TaskCategory category;

  /// Whether the chip is currently selected.
  final bool selected;

  /// Called when the chip is tapped.
  final VoidCallback? onTap;

  /// Whether to render the optional count badge.
  final bool showCount;

  /// The number to display in the count badge. Ignored when [showCount]
  /// is false or the value is `null`.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    final scheme = Theme.of(context).colorScheme;

    final label = Text(
      category.label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : scheme.onSurface,
      ),
    );

    // The leading element switches between a colored dot (unselected) and a
    // check icon (selected) so the user always has a quick visual anchor.
    final leading = selected
        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
        : Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          );

    // Optional count badge shown to the right of the label.
    final badge = (showCount && count != null)
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.25)
                  : scheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : scheme.onSurfaceVariant,
              ),
            ),
          )
        : null;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 8),
            label,
            if (badge != null) ...[
              const SizedBox(width: 6),
              badge,
            ],
          ],
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? color : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? null
                : Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                    width: 1,
                  ),
          ),
          child: content
              .animate(target: selected ? 1 : 0)
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1, 1),
                duration: 200.ms,
              ),
        ),
      ),
    );
  }
}
