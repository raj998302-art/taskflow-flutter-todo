import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/entities/task_enums.dart';
import '../../../domain/repositories/task_repository.dart';
import '../datasources/local/task_local_datasource.dart';

/// Re-export the model so callers can build entities for tests.
export '../models/task_model.dart' show TaskModel;

/// Concrete implementation of [TaskRepository] backed by Hive.
///
/// This is the only class in the data layer that the domain/presentation
/// layers depend on (via the abstract [TaskRepository]). All Hive-specific
/// mechanics live in [TaskLocalDataSource].
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._dataSource);

  final TaskLocalDataSource _dataSource;

  @override
  Future<List<Task>> getAllTasks() async {
    return _dataSource.getAllTasks();
  }

  @override
  Future<Task?> getTaskById(String id) {
    return Future.value(_dataSource.getTaskById(id));
  }

  @override
  Future<Task> createTask({
    required String title,
    String? description,
    required Priority priority,
    required TaskCategory category,
    DateTime? dueDate,
  }) async {
    return _dataSource.createTask(
      title: title,
      description: description,
      priority: priority,
      category: category,
      dueDate: dueDate,
    );
  }

  @override
  Future<Task> updateTask(Task task) async {
    return _dataSource.updateTask(task);
  }

  @override
  Future<void> deleteTask(String id) async {
    _dataSource.deleteTask(id);
  }

  @override
  Future<void> toggleComplete(String id) async {
    _dataSource.toggleComplete(id);
  }

  @override
  Future<void> deleteCompletedTasks() async {
    _dataSource.deleteCompletedTasks();
  }

  @override
  Future<void> clearAllTasks() async {
    _dataSource.clearAllTasks();
  }
}

/// Opens the Hive box (if needed) and constructs a [TaskRepositoryImpl].
///
/// The boxes are also opened eagerly in `main.dart` so this is effectively a
/// no-op open after the first call.
Future<TaskRepository> createTaskRepository() async {
  final box = await Hive.openBox<dynamic>(AppConstants.tasksBox);
  return TaskRepositoryImpl(TaskLocalDataSource(box));
}

/// Constructs a [TaskRepositoryImpl] synchronously using an already-open Hive
/// box. The tasks box is opened eagerly in `main.dart` before `runApp`, so
/// this is safe to call from a synchronous riverpod [Provider].
TaskRepository createTaskRepositorySync() {
  final box = Hive.box<dynamic>(AppConstants.tasksBox);
  return TaskRepositoryImpl(TaskLocalDataSource(box));
}
