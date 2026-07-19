import '../../domain/repositories/task_repository.dart';

/// Toggles the completion state of a task.
class ToggleTask {
  ToggleTask(this._repository);
  final TaskRepository _repository;

  Future<void> call(String id) => _repository.toggleComplete(id);
}
