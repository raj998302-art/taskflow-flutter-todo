import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

/// Updates an existing task.
class UpdateTask {
  UpdateTask(this._repository);
  final TaskRepository _repository;

  Future<Task> call(Task task) => _repository.updateTask(task);
}
