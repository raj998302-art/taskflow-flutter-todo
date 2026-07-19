import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

/// Retrieves all tasks.
class GetTasks {
  GetTasks(this._repository);
  final TaskRepository _repository;

  Future<List<Task>> call() => _repository.getAllTasks();
}
