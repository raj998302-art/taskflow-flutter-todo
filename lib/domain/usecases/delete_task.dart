import '../../domain/repositories/task_repository.dart';

/// Deletes a task by id.
class DeleteTask {
  DeleteTask(this._repository);
  final TaskRepository _repository;

  Future<void> call(String id) => _repository.deleteTask(id);
}
