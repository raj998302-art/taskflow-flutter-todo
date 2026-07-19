import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_enums.dart';

/// Serialisation model for [Reminder] backed by a Hive box.
///
/// Manual Map-based (de)serialisation — no code generation needed.
class ReminderModel {
  const ReminderModel({
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

  final String id;
  final String title;
  final String? note;
  final DateTime scheduledAt;
  final String recurrence;
  final bool voiceEnabled;
  final String voicePrefix;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastFiredAt;

  factory ReminderModel.fromEntity(Reminder r) {
    return ReminderModel(
      id: r.id,
      title: r.title,
      note: r.note,
      scheduledAt: r.scheduledAt,
      recurrence: r.recurrence.value,
      voiceEnabled: r.voiceEnabled,
      voicePrefix: r.voicePrefix,
      isActive: r.isActive,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      lastFiredAt: r.lastFiredAt,
    );
  }

  Reminder toEntity() {
    return Reminder(
      id: id,
      title: title,
      note: note,
      scheduledAt: scheduledAt,
      recurrence: Recurrence.fromString(recurrence),
      voiceEnabled: voiceEnabled,
      voicePrefix: voicePrefix,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastFiredAt: lastFiredAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'scheduledAt': scheduledAt.toIso8601String(),
      'recurrence': recurrence,
      'voiceEnabled': voiceEnabled,
      'voicePrefix': voicePrefix,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastFiredAt': lastFiredAt?.toIso8601String(),
    };
  }

  factory ReminderModel.fromMap(Map<dynamic, dynamic> map) {
    return ReminderModel(
      id: map['id'] as String,
      title: map['title'] as String,
      note: map['note'] as String?,
      scheduledAt: map['scheduledAt'] == null
          ? DateTime.now()
          : DateTime.parse(map['scheduledAt'] as String),
      recurrence: (map['recurrence'] as String?) ?? 'once',
      voiceEnabled: (map['voiceEnabled'] as bool?) ?? false,
      voicePrefix: (map['voicePrefix'] as String?) ?? 'Boss',
      isActive: (map['isActive'] as bool?) ?? true,
      createdAt: map['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] == null
          ? DateTime.now()
          : DateTime.parse(map['updatedAt'] as String),
      lastFiredAt: map['lastFiredAt'] == null
          ? null
          : DateTime.parse(map['lastFiredAt'] as String),
    );
  }
}
