/// Priority levels for a task.
///
/// Stored as a lowercase string in the database; the enum provides type safety
/// in the domain and presentation layers.
enum Priority {
  low('low'),
  medium('medium'),
  high('high');

  const Priority(this.value);
  final String value;

  static Priority fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return Priority.high;
      case 'low':
        return Priority.low;
      default:
        return Priority.medium;
    }
  }
}

/// Built-in task categories.
///
/// Users can also create custom categories by passing an arbitrary label;
/// the [fromString] factory normalises known ones.
enum TaskCategory {
  personal('Personal'),
  work('Work'),
  shopping('Shopping'),
  health('Health'),
  other('Other');

  const TaskCategory(this.label);
  final String label;

  static TaskCategory fromString(String? value) {
    if (value == null) return TaskCategory.other;
    final v = value.toLowerCase();
    for (final c in TaskCategory.values) {
      if (c.label.toLowerCase() == v) return c;
    }
    return TaskCategory.other;
  }
}
