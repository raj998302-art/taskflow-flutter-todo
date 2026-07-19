import 'reminder_enums.dart';

/// A scheduled reminder with optional voice playback.
///
/// Example: "8:05 PM on the 19th — Boss, apko sabji lena hai" with voice on.
///
/// Reminders are persisted in Hive and mirrored into the host platform's
/// alarm / notification scheduler (see [NotificationService]) so they fire
/// even when the app is closed. Voice reminders additionally speak the
/// subject aloud via text-to-speech when the alarm fires.
class Reminder {
  Reminder({
    required this.id,
    required this.title,
    this.note,
    required this.scheduledAt,
    required this.recurrence,
    required this.voiceEnabled,
    required this.voicePrefix,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastFiredAt,
  });

  /// Stable unique id (also used as the Android notification id).
  final String id;

  /// Short subject, e.g. "Sabji lena hai".
  final String title;

  /// Optional longer note shown in the notification body.
  final String? note;

  /// When the reminder should fire.
  final DateTime scheduledAt;

  /// How the reminder repeats after firing.
  final Recurrence recurrence;

  /// When true the device speaks the reminder aloud using [voicePrefix] +
  /// [title] when the alarm fires.
  final bool voiceEnabled;

  /// Spoken prefix, e.g. "Boss," — produces "Boss, apko sabji lena hai".
  final String voicePrefix;

  /// Whether the reminder is armed (false = paused / snoozed indefinitely).
  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Last time the alarm actually fired (used to compute the next occurrence).
  final DateTime? lastFiredAt;

  /// The full sentence that the TTS engine will speak.
  String get spokenText {
    final prefix = voicePrefix.trim();
    if (prefix.isEmpty) return title;
    return '$prefix, $title';
  }

  /// Computes the next firing time after [from] for repeating reminders.
  /// Returns `null` for one-off reminders (no next occurrence).
  DateTime? nextOccurrenceAfter(DateTime from) {
    if (recurrence == Recurrence.once) return null;
    DateTime base = scheduledAt;
    // Walk forward until we pass [from].
    while (!base.isAfter(from)) {
      base = _step(base);
    }
    return base;
  }

  DateTime _step(DateTime d) {
    switch (recurrence) {
      case Recurrence.daily:
        return d.add(const Duration(days: 1));
      case Recurrence.weekdays:
        final next = d.add(const Duration(days: 1));
        // Skip Saturday (6) and Sunday (7).
        if (next.weekday == DateTime.saturday) {
          return d.add(const Duration(days: 3));
        }
        if (next.weekday == DateTime.sunday) {
          return d.add(const Duration(days: 2));
        }
        return next;
      case Recurrence.weekly:
        return d.add(const Duration(days: 7));
      case Recurrence.monthly:
        // Same day next month, clamping to month length.
        final nextMonth = DateTime(d.year, d.month + 1, d.day, d.hour, d.minute);
        return nextMonth;
      case Recurrence.once:
        return d;
    }
  }

  Reminder copyWith({
    String? title,
    String? note,
    DateTime? scheduledAt,
    Recurrence? recurrence,
    bool? voiceEnabled,
    String? voicePrefix,
    bool? isActive,
    DateTime? lastFiredAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      recurrence: recurrence ?? this.recurrence,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      voicePrefix: voicePrefix ?? this.voicePrefix,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastFiredAt: lastFiredAt ?? this.lastFiredAt,
    );
  }

  @override
  String toString() =>
      'Reminder(id: $id, title: $title, at: $scheduledAt, voice: $voiceEnabled, '
      'prefix: $voicePrefix, repeat: $recurrence, active: $isActive)';
}
