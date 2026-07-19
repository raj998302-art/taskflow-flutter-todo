import '../../domain/entities/task.dart';
import '../../domain/entities/task_enums.dart';

/// Contract for the task repository.
///
/// Defined in the domain layer and implemented by the data layer. This keeps
/// the business logic decoupled from persistence details (Hive).
abstract class TaskRepository {
  Future<List<Task>> getAllTasks();
  Future<Task?> getTaskById(String id);
  Future<Task> createTask({
    required String title,
    String? description,
    required Priority priority,
    required TaskCategory category,
    DateTime? dueDate,
  });
  Future<Task> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<void> toggleComplete(String id);
  Future<void> deleteCompletedTasks();
  Future<void> clearAllTasks();
}
