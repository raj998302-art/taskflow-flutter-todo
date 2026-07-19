import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_enums.dart';
import '../../domain/repositories/task_repository.dart';

/// Provides a single [TaskRepository] instance backed by Hive.
///
/// The tasks box is opened eagerly in `main.dart`, so the repository can be
/// constructed synchronously here.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return createTaskRepositorySync();
});

/// Central notifier that owns the in-memory task list and exposes all CRUD
/// operations. UI widgets watch [taskListProvider] and call methods here.
class TaskListNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  TaskListNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final TaskRepository _repository;

  Future<void> _load() async {
    try {
      final tasks = await _repository.getAllTasks();
      if (!mounted) return;
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<Task> addTask({
    required String title,
    String? description,
    required Priority priority,
    required TaskCategory category,
    DateTime? dueDate,
  }) async {
    final task = await _repository.createTask(
      title: title,
      description: description,
      priority: priority,
      category: category,
      dueDate: dueDate,
    );
    // Optimistically insert at the top (newest first).
    state = AsyncValue.data([task, ...?state.value]);
    return task;
  }

  Future<void> updateTask(Task task) async {
    final updated = await _repository.updateTask(task);
    final list = state.value ?? [];
    state = AsyncValue.data([
      for (final t in list) if (t.id == updated.id) updated else t,
    ]);
  }

  Future<void> toggleComplete(String id) async {
    await _repository.toggleComplete(id);
    final list = state.value ?? [];
    state = AsyncValue.data([
      for (final t in list)
        if (t.id == id)
          t.copyWith(
            isCompleted: !t.isCompleted,
            updatedAt: DateTime.now(),
          )
        else
          t,
    ]);
  }

  Future<void> deleteTask(String id) async {
    final previous = state.value ?? [];
    // Optimistic removal.
    state = AsyncValue.data(
      previous.where((t) => t.id != id).toList(),
    );
    try {
      await _repository.deleteTask(id);
    } catch (_) {
      // Rollback on failure.
      state = AsyncValue.data(previous);
    }
  }

  /// Toggles a single subtask's done state and persists the parent task.
  Future<void> toggleSubTask(String taskId, String subTaskId) async {
    final list = state.value ?? [];
    final existing = list.where((t) => t.id == taskId).firstOrNull;
    if (existing == null) return;
    final updatedSubs = existing.subtasks
        .map((s) => s.id == subTaskId ? s.copyWith(isDone: !s.isDone) : s)
        .toList();
    final updated = existing.copyWith(
      subtasks: updatedSubs,
      updatedAt: DateTime.now(),
    );
    await _repository.updateTask(updated);
    state = AsyncValue.data([
      for (final t in list) if (t.id == taskId) updated else t,
    ]);
  }

  /// Adds a new subtask to the given task.
  Future<void> addSubTask(String taskId, String title) async {
    final list = state.value ?? [];
    final existing = list.where((t) => t.id == taskId).firstOrNull;
    if (existing == null) return;
    final newSub = SubTask(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      isDone: false,
    );
    final updated = existing.copyWith(
      subtasks: [...existing.subtasks, newSub],
      updatedAt: DateTime.now(),
    );
    await _repository.updateTask(updated);
    state = AsyncValue.data([
      for (final t in list) if (t.id == taskId) updated else t,
    ]);
  }

  /// Removes a subtask from the given task.
  Future<void> removeSubTask(String taskId, String subTaskId) async {
    final list = state.value ?? [];
    final existing = list.where((t) => t.id == taskId).firstOrNull;
    if (existing == null) return;
    final updated = existing.copyWith(
      subtasks: existing.subtasks.where((s) => s.id != subTaskId).toList(),
      updatedAt: DateTime.now(),
    );
    await _repository.updateTask(updated);
    state = AsyncValue.data([
      for (final t in list) if (t.id == taskId) updated else t,
    ]);
  }

  Future<int> deleteCompletedTasks() async {
    final previous = state.value ?? [];
    final removed = previous.where((t) => t.isCompleted).length;
    state = AsyncValue.data(previous.where((t) => !t.isCompleted).toList());
    await _repository.deleteCompletedTasks();
    return removed;
  }

  Future<void> clearAllTasks() async {
    state = const AsyncValue.data([]);
    await _repository.clearAllTasks();
  }
}

/// The primary provider the UI watches for the current list of tasks.
final taskListProvider =
    StateNotifierProvider<TaskListNotifier, AsyncValue<List<Task>>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return TaskListNotifier(repo);
});
