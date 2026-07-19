import '../../domain/entities/task.dart';
import '../../domain/entities/task_enums.dart';

/// Serialisation model for [Task] backed by a Hive box.
///
/// We use manual Map-based serialisation (no code generation) to keep the
/// build process simple and avoid `build_runner` friction. The model converts
/// between the plain [Task] entity and the JSON-like [Map] stored in Hive.
class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.priority,
    required this.category,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final String priority;
  final String category;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Convert from a domain [Task] to the persistence model.
  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      isCompleted: task.isCompleted,
      priority: task.priority.value,
      category: task.category.label,
      dueDate: task.dueDate,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
    );
  }

  /// Convert to a domain [Task] entity.
  Task toEntity() {
    return Task(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted,
      priority: Priority.fromString(priority),
      category: TaskCategory.fromString(category),
      dueDate: dueDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Serialise to a Map for storage in Hive.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority,
      'category': category,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Deserialise from a Map stored in Hive.
  factory TaskModel.fromMap(Map<dynamic, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: (map['isCompleted'] as bool?) ?? false,
      priority: (map['priority'] as String?) ?? 'medium',
      category: (map['category'] as String?) ?? 'Other',
      dueDate: map['dueDate'] == null
          ? null
          : DateTime.parse(map['dueDate'] as String),
      createdAt: map['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] == null
          ? DateTime.now()
          : DateTime.parse(map['updatedAt'] as String),
    );
  }
}
