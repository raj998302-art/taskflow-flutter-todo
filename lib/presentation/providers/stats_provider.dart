import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/task_enums.dart';
import 'filter_providers.dart';
import 'task_providers.dart';

/// Aggregated statistics computed from the current task list.
class TaskStats {
  const TaskStats({
    required this.total,
    required this.completed,
    required this.active,
    required this.overdue,
    required this.dueToday,
    required this.completionRate,
    required this.byCategory,
    required this.byPriority,
    required this.weeklyCompleted,
  });

  final int total;
  final int completed;
  final int active;
  final int overdue;
  final int dueToday;
  final double completionRate; // 0.0 – 1.0
  final Map<TaskCategory, int> byCategory;
  final Map<Priority, int> byPriority;
  final List<int> weeklyCompleted; // 7 entries Mon..Sun (or last 7 days)
}

/// Derives a [TaskStats] object from the raw task list, applying the current
/// filters so the dashboard reflects what the user is viewing.
final statsProvider = Provider<TaskStats>((ref) {
  final tasksAsync = ref.watch(taskListProvider);
  final filters = ref.watch(filterProvider);
  final tasks = tasksAsync.valueOrNull ?? const <Task>[];

  final filtered = _applyFilters(tasks, filters);

  int completed = 0;
  int overdue = 0;
  int dueToday = 0;
  final byCategory = <TaskCategory, int>{};
  final byPriority = <Priority, int>{};
  final weekly = List<int>.filled(7, 0);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = today.subtract(const Duration(days: 6));

  for (final t in filtered) {
    if (t.isCompleted) completed++;
    if (t.isOverdue) overdue++;
    if (t.dueDate != null && _sameDay(t.dueDate!, today)) dueToday++;

    byCategory[t.category] = (byCategory[t.category] ?? 0) + 1;
    byPriority[t.priority] = (byPriority[t.priority] ?? 0) + 1;

    if (t.isCompleted &&
        t.updatedAt.isAfter(weekStart.subtract(const Duration(days: 1)))) {
      final diff = t.updatedAt.difference(weekStart).inDays;
      if (diff >= 0 && diff < 7) weekly[diff]++;
    }
  }

  final active = filtered.length - completed;
  final rate = filtered.isEmpty ? 0.0 : completed / filtered.length;

  return TaskStats(
    total: filtered.length,
    completed: completed,
    active: active,
    overdue: overdue,
    dueToday: dueToday,
    completionRate: rate,
    byCategory: byCategory,
    byPriority: byPriority,
    weeklyCompleted: weekly,
  );
});

List<Task> _applyFilters(List<Task> tasks, FilterState f) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  Iterable<Task> result = tasks;

  switch (f.filter) {
    case TaskFilter.active:
      result = result.where((t) => !t.isCompleted);
      break;
    case TaskFilter.completed:
      result = result.where((t) => t.isCompleted);
      break;
    case TaskFilter.overdue:
      result = result.where((t) => t.isOverdue);
      break;
    case TaskFilter.today:
      result = result.where((t) => t.dueDate != null && _sameDay(t.dueDate!, today));
      break;
    case TaskFilter.all:
      break;
  }

  if (f.category != null) {
    result = result.where((t) => t.category == f.category);
  }
  if (f.priority != null) {
    result = result.where((t) => t.priority == f.priority);
  }
  if (f.searchQuery.isNotEmpty) {
    final q = f.searchQuery.toLowerCase();
    result = result.where((t) =>
        t.title.toLowerCase().contains(q) ||
        (t.description?.toLowerCase().contains(q) ?? false));
  }

  final list = result.toList();
  switch (f.sort) {
    case SortOption.byDateCreated:
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case SortOption.byDueDate:
      list.sort((a, b) {
        final ad = a.dueDate;
        final bd = b.dueDate;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
      break;
    case SortOption.byPriority:
      const order = {Priority.high: 0, Priority.medium: 1, Priority.low: 2};
      list.sort((a, b) =>
          (order[a.priority] ?? 9).compareTo(order[b.priority] ?? 9));
      break;
    case SortOption.alphabetical:
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;
  }

  return list;
}

/// Provides the filtered + sorted list of tasks for the home screen.
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasksAsync = ref.watch(taskListProvider);
  final filters = ref.watch(filterProvider);
  final tasks = tasksAsync.valueOrNull ?? const <Task>[];
  return _applyFilters(tasks, filters);
});

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
