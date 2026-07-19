import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/entities/task_enums.dart';
import '../../models/task_model.dart';

/// Local data source that reads/writes tasks to a Hive box.
///
/// Acts as the lowest layer of the data tier. The repository implementation
/// depends on this class, keeping storage mechanics isolated from the domain.
class TaskLocalDataSource {
  TaskLocalDataSource(this._box);

  final Box<dynamic> _box;

  /// Returns all tasks sorted by creation date (newest first).
  List<Task> getAllTasks() {
    final models = _box.values
        .whereType<Map>()
        .map((m) => TaskModel.fromMap(m.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return models.map((m) => m.toEntity()).toList();
  }

  Task? getTaskById(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return TaskModel.fromMap((raw as Map).cast<String, dynamic>()).toEntity();
  }

  Task createTask({
    required String title,
    String? description,
    required Priority priority,
    required TaskCategory category,
    DateTime? dueDate,
  }) {
    final now = DateTime.now();
    final model = TaskModel(
      id: _generateId(),
      title: title,
      description: description,
      isCompleted: false,
      priority: priority.value,
      category: category.label,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
    );
    _box.put(model.id, model.toMap());
    return model.toEntity();
  }

  Task updateTask(Task task) {
    final updated = task.copyWith(updatedAt: DateTime.now());
    final model = TaskModel.fromEntity(updated);
    _box.put(model.id, model.toMap());
    return updated;
  }

  void deleteTask(String id) {
    _box.delete(id);
  }

  /// Toggles completion and returns the updated task (or null if not found).
  Task? toggleComplete(String id) {
    final existing = getTaskById(id);
    if (existing == null) return null;
    final updated = existing.copyWith(
      isCompleted: !existing.isCompleted,
      updatedAt: DateTime.now(),
    );
    _box.put(id, TaskModel.fromEntity(updated).toMap());
    return updated;
  }

  int deleteCompletedTasks() {
    final completed = getAllTasks().where((t) => t.isCompleted).toList();
    for (final t in completed) {
      _box.delete(t.id);
    }
    return completed.length;
  }

  void clearAllTasks() {
    _box.clear();
  }

  String _generateId() {
    return 'task_${DateTime.now().millisecondsSinceEpoch}'
        '_${(DateTime.now().microsecond % 10000).toString().padLeft(4, '0')}';
  }
}

/// Provider-friendly factory that opens (or retrieves) the tasks box lazily.
Future<TaskLocalDataSource> openTaskDataSource() async {
  final box = await Hive.openBox<dynamic>(AppConstants.tasksBox);
  return TaskLocalDataSource(box);
}
