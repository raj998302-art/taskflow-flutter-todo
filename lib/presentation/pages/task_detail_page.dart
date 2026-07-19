import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/loading_animation.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_enums.dart';
import '../providers/task_providers.dart';
import '../widgets/add_task_sheet.dart';

/// Full-detail view of a single task with edit, complete and delete actions.
class TaskDetailPage extends ConsumerWidget {
  const TaskDetailPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: tasksAsync.when(
          loading: () => const Center(child: AppLoading()),
          error: (e, _) => Center(child: Text('Could not load task: $e')),
          data: (tasks) {
            final task = tasks.where((t) => t.id == taskId).firstOrNull;
            if (task == null) {
              return _NotFound(taskId: taskId);
            }
            return _DetailContent(task: task);
          },
        ),
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pColor = priorityColor(task.priority.value);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit',
              onPressed: () => _openEditSheet(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
          backgroundColor: context.theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Priority ribbon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: pColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_rounded, size: 14, color: pColor),
                        const SizedBox(width: 4),
                        Text(
                          '${priorityLabel(task.priority.value)} priority',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: pColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(task: task),
                ],
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 16),
              Text(
                task.title,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted
                      ? context.colors.onSurfaceVariant
                      : null,
                ),
              ).animate().fadeIn(delay: 80.ms, duration: 300.ms),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notes_rounded,
                              size: 18,
                              color: context.colors.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            'Notes',
                            style: context.textTheme.labelMedium?.copyWith(
                              color: context.colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description!,
                        style: context.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 140.ms, duration: 300.ms),
              ],
              const SizedBox(height: 16),
              _SubtasksSection(task: task),
              const SizedBox(height: 16),
              _MetaGrid(task: task),
              const SizedBox(height: 24),
              _ActionButtons(task: task),
              const SizedBox(height: 16),
              Text(
                'Created ${DateFormat('MMM d, yyyy · h:mm a').format(task.createdAt)}',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Updated ${DateFormat('MMM d, yyyy · h:mm a').format(task.updatedAt)}',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => AddTaskSheet(existing: task),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('“${task.title}” will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(taskListProvider.notifier).deleteTask(task.id);
      if (context.mounted) context.go('/');
    }
  }
}

class _SubtasksSection extends ConsumerStatefulWidget {
  const _SubtasksSection({required this.task});
  final Task task;

  @override
  ConsumerState<_SubtasksSection> createState() => _SubtasksSectionState();
}

class _SubtasksSectionState extends ConsumerState<_SubtasksSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref
        .read(taskListProvider.notifier)
        .addSubTask(widget.task.id, text);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final subs = task.subtasks;
    final doneCount = subs.where((s) => s.isDone).length;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Subtasks',
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$doneCount/${subs.length}',
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: task.subtaskProgress,
              minHeight: 4,
              backgroundColor:
                  AppColors.primary.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          if (subs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: Text(
                  'No subtasks. Add one below.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                for (final sub in subs)
                  _SubtaskRow(
                    key: ValueKey(sub.id),
                    task: task,
                    sub: sub,
                  ).animate().fadeIn(duration: 200.ms),
              ],
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: context.textTheme.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: Icon(
                Icons.add_rounded,
                size: 20,
                color: context.colors.onSurfaceVariant,
              ),
              hintText: 'Add a subtask...',
              hintStyle: TextStyle(
                fontSize: 14,
                color: context.colors.onSurfaceVariant,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      context.colors.onSurfaceVariant.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      context.colors.onSurfaceVariant.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 160.ms, duration: 300.ms);
  }
}

class _SubtaskRow extends ConsumerWidget {
  const _SubtaskRow({super.key, required this.task, required this.sub});

  final Task task;
  final SubTask sub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => ref
                .read(taskListProvider.notifier)
                .toggleSubTask(task.id, sub.id),
            child: Icon(
              sub.isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 22,
              color: sub.isDone
                  ? AppColors.primary
                  : context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sub.title,
              style: TextStyle(
                fontSize: 15,
                decoration:
                    sub.isDone ? TextDecoration.lineThrough : null,
                color: sub.isDone
                    ? context.colors.onSurfaceVariant
                    : null,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: context.colors.onSurfaceVariant,
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
            onPressed: () => ref
                .read(taskListProvider.notifier)
                .removeSubTask(task.id, sub.id),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final completed = task.isCompleted;
    final overdue = task.isOverdue;
    final (label, color, icon) = completed
        ? ('Completed', AppColors.success, Icons.check_circle_rounded)
        : overdue
            ? ('Overdue', AppColors.highPriority, Icons.warning_amber_rounded)
            : ('Active', AppColors.primary, Icons.radio_button_checked_rounded);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(task.category);
    return Row(
      children: [
        Expanded(
          child: _MetaTile(
            icon: Icons.category_rounded,
            label: 'Category',
            value: task.category.label,
            color: catColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetaTile(
            icon: Icons.event_rounded,
            label: 'Due date',
            value: task.dueDate == null ? 'No date' : task.dueDate!.dueLabel,
            color: task.isOverdue ? AppColors.highPriority : AppColors.accent,
            warning: task.isOverdue,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 180.ms, duration: 300.ms);
  }

  Color _categoryColor(TaskCategory c) {
    switch (c) {
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
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.warning = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: warning ? color : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () =>
                ref.read(taskListProvider.notifier).toggleComplete(task.id),
            icon: Icon(task.isCompleted
                ? Icons.undo_rounded
                : Icons.check_rounded),
            label: Text(task.isCompleted ? 'Mark active' : 'Mark complete'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                useSafeArea: true,
                builder: (_) => AddTaskSheet(existing: task),
              );
            },
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit'),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 220.ms, duration: 300.ms);
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/'),
          ),
          backgroundColor: Colors.transparent,
        ),
        const Expanded(
          child: AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'Task not found',
            subtitle: 'This task may have been deleted.',
          ),
        ),
      ],
    );
  }
}

extension on Iterable<Task> {
  Task? get firstOrNull => isEmpty ? null : first;
}
