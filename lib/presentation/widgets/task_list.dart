import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/empty_state.dart';
import '../../domain/entities/task.dart';
import 'task_card.dart';

/// Renders the supplied list of [Task]s as a scrollable list of [TaskCard]s.
///
/// The widget does **not** watch any provider itself — callers pass the tasks
/// in (typically via [filteredTasksProvider]) so the list is purely
/// presentational. When the list is empty an [AppEmptyState] is shown instead.
class TaskList extends ConsumerWidget {
  const TaskList({
    super.key,
    required this.tasks,
    this.controller,
    this.physics,
  });

  /// The tasks to render, in the order they should appear.
  final List<Task> tasks;

  /// Optional scroll controller, useful when embedding the list inside a
  /// scaffold that needs to react to scroll events (e.g. to hide the FAB).
  final ScrollController? controller;

  /// Optional scroll physics. Defaults to always-scrollable so the user can
  /// pull to refresh even when the list is short.
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return const Center(
        child: AppEmptyState(
          icon: Icons.task_alt_rounded,
          title: 'No tasks yet',
          subtitle: 'Tap the + button to add your first task.',
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemBuilder: (context, index) =>
          TaskCard(task: tasks[index], index: index),
    );
  }
}
