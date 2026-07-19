/// How often a reminder should repeat after it fires once.
///
/// Stored as a lowercase string in Hive; the enum gives type-safety in the
/// domain and presentation layers.
enum Recurrence {
  once('once'),
  daily('daily'),
  weekdays('weekdays'),
  weekly('weekly'),
  monthly('monthly');

  const Recurrence(this.value);
  final String value;

  static Recurrence fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'daily':
        return Recurrence.daily;
      case 'weekdays':
        return Recurrence.weekdays;
      case 'weekly':
        return Recurrence.weekly;
      case 'monthly':
        return Recurrence.monthly;
      default:
        return Recurrence.once;
    }
  }

  /// Human-readable label shown in the UI.
  String get label {
    switch (this) {
      case Recurrence.once:
        return 'Once';
      case Recurrence.daily:
        return 'Every day';
      case Recurrence.weekdays:
        return 'Weekdays';
      case Recurrence.weekly:
        return 'Every week';
      case Recurrence.monthly:
        return 'Every month';
    }
  }
}
