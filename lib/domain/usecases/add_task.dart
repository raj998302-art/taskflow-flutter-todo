import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

/// Creates a new task.
class AddTask {
  AddTask(this._repository);
  final TaskRepository _repository;

  Future<Task> call(Task task) {
    return _repository.createTask(
      title: task.title,
      description: task.description,
      priority: task.priority,
      category: task.category,
      dueDate: task.dueDate,
    );
  }
}
