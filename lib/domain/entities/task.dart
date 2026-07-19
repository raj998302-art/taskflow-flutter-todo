import 'task_enums.dart';

/// A single todo task — the core domain entity.
///
/// This class is deliberately free of any persistence or framework concerns
/// (no Hive adapters, no JSON annotations). The data layer is responsible for
/// serialising/deserialising it via [TaskModel].
class Task {
  Task({
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
  final Priority priority;
  final TaskCategory category;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Convenience flag computed from [dueDate]. A task is overdue when it has
  /// a due date in the past (day-level) and is not yet completed.
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return target.isBefore(today);
  }

  Task copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    Priority? priority,
    TaskCategory? category,
    DateTime? dueDate,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Task(id: $id, title: $title, completed: $isCompleted, '
      'priority: $priority, category: $category, due: $dueDate)';
}
