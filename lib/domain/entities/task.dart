import 'task_enums.dart';

/// A single sub-item inside a task's checklist.
class SubTask {
  const SubTask({required this.id, required this.title, required this.isDone});

  final String id;
  final String title;
  final bool isDone;

  SubTask copyWith({String? title, bool? isDone}) {
    return SubTask(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isDone': isDone,
      };

  factory SubTask.fromMap(Map<dynamic, dynamic> m) => SubTask(
        id: m['id'] as String,
        title: m['title'] as String,
        isDone: (m['isDone'] as bool?) ?? false,
      );
}

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
    this.subtasks = const [],
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
  final List<SubTask> subtasks;

  /// Convenience flag computed from [dueDate]. A task is overdue when it has
  /// a due date in the past (day-level) and is not yet completed.
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return target.isBefore(today);
  }

  /// Fraction of subtasks completed (0.0–1.0). 1.0 when there are none.
  double get subtaskProgress {
    if (subtasks.isEmpty) return 1.0;
    final done = subtasks.where((s) => s.isDone).length;
    return done / subtasks.length;
  }

  Task copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    Priority? priority,
    TaskCategory? category,
    DateTime? dueDate,
    DateTime? updatedAt,
    List<SubTask>? subtasks,
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
      subtasks: subtasks ?? this.subtasks,
    );
  }

  @override
  String toString() =>
      'Task(id: $id, title: $title, completed: $isCompleted, '
      'priority: $priority, category: $category, due: $dueDate, '
      'subtasks: ${subtasks.length})';
}
