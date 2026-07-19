import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/confetti_burst.dart';
import '../../core/widgets/glass_container.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_enums.dart';
import '../providers/task_providers.dart';

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

/// A single task displayed as a swipeable, glassmorphic card.
///
/// The card exposes two swipe actions:
/// - **Swipe right** (start pane): toggle the task's completed state. The icon
///   and label switch to "Undo" when the task is already completed.
/// - **Swipe left** (end pane): delete the task (with a red destructive
///   background).
///
/// The card itself shows a circular checkbox, title, optional description, and
/// a row of meta chips (priority, category, due date). High-priority tasks get
/// an accent color bar on the very left; completed tasks are dimmed and their
/// title is rendered with a strikethrough.
class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.index = 0,
    this.onTap,
  });

  /// The task to render.
  final Task task;

  /// Position in the parent list — used to stagger the entrance animation.
  final int index;

  /// Optional tap callback. When `null`, the card navigates to the task
  /// detail route (`/task/{id}`).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final accentColor = priorityColor(task.priority.value);
    final isOverdue = task.isOverdue;

    return Slidable(
      key: ValueKey('task-${task.id}'),
      groupTag: 'tasks',
      closeOnScroll: true,
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.28,
        children: [
          SlidableAction(
            onPressed: (_) {
              ref.read(taskListProvider.notifier).toggleComplete(task.id);
              if (!task.isCompleted) celebrate(ref);
            },
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            icon: task.isCompleted
                ? Icons.undo_rounded
                : Icons.check_rounded,
            label: task.isCompleted ? 'Undo' : 'Done',
            borderRadius: BorderRadius.circular(16),
            autoClose: true,
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.28,
        children: [
          SlidableAction(
            onPressed: (_) =>
                ref.read(taskListProvider.notifier).deleteTask(task.id),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: 'Delete',
            borderRadius: BorderRadius.circular(16),
            autoClose: true,
          ),
        ],
      ),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(16),
        padding: EdgeInsets.zero,
        color: scheme.surface.withValues(alpha: 0.85),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap ?? () => context.push('/task/${task.id}'),
              child: Opacity(
                opacity: task.isCompleted ? 0.6 : 1,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Priority accent bar (4px) on the very left. High
                      // priority is rendered at full saturation to draw the
                      // eye; lower priorities use a subtle tinted bar.
                      Container(
                        width: 4,
                        color: task.priority == Priority.high
                            ? accentColor
                            : accentColor.withValues(alpha: 0.4),
                      ),
                      // Custom circular checkbox / toggle.
                      _CheckboxToggle(
                        completed: task.isCompleted,
                        color: accentColor,
                        onTap: () {
                          ref
                              .read(taskListProvider.notifier)
                              .toggleComplete(task.id);
                          if (!task.isCompleted) celebrate(ref);
                        },
                      ),
                      // Title + description + meta chips.
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 12,
                            bottom: 12,
                            right: 14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  decorationColor:
                                      scheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if ((task.description ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  task.description!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.3,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 8),
                              _MetaChipsRow(
                                task: task,
                                accentColor: accentColor,
                                overdue: isOverdue,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: (index * 60).ms,
          duration: 300.ms,
        )
        .slideY(begin: 0.05, end: 0, duration: 300.ms);
  }
}

/// The circular checkbox used on the left of a [TaskCard].
class _CheckboxToggle extends StatelessWidget {
  const _CheckboxToggle({
    required this.completed,
    required this.color,
    required this.onTap,
  });

  final bool completed;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Icon(
          completed
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 26,
          color: completed ? color : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Row of meta chips under the task title: priority, category, due date.
class _MetaChipsRow extends StatelessWidget {
  const _MetaChipsRow({
    required this.task,
    required this.accentColor,
    required this.overdue,
  });

  final Task task;
  final Color accentColor;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MetaChip(
          color: accentColor,
          label: priorityLabel(task.priority.value),
        ),
        _MetaChip(
          color: _categoryColor(task.category),
          label: task.category.label,
        ),
        if (task.dueDate != null)
          _MetaChip(
            color: overdue ? AppColors.error : scheme.onSurfaceVariant,
            label: task.dueDate!.dueLabel,
            icon: overdue
                ? Icons.warning_amber_rounded
                : Icons.event_rounded,
            filled: overdue,
          ),
      ],
    );
  }
}

/// A single pill-shaped meta chip with a colored dot (or icon) and label.
class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.color,
    required this.label,
    this.icon,
    this.filled = false,
  });

  final Color color;
  final String label;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled
            ? color.withValues(alpha: 0.16)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 12, color: color)
          else
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: filled ? color : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
