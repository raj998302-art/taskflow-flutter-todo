import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/reminder.dart';
import '../../models/reminder_model.dart';

/// Local data source for reminders backed by a Hive box.
class ReminderLocalDataSource {
  ReminderLocalDataSource(this._box);
  final Box<dynamic> _box;

  List<Reminder> getAllReminders() {
    final models = _box.values
        .whereType<Map>()
        .map((m) => ReminderModel.fromMap(m.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return models.map((m) => m.toEntity()).toList();
  }

  Reminder? getReminderById(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return ReminderModel.fromMap((raw as Map).cast<String, dynamic>()).toEntity();
  }

  Reminder createReminder(Reminder reminder) {
    final model = ReminderModel.fromEntity(reminder);
    _box.put(model.id, model.toMap());
    return reminder;
  }

  Reminder updateReminder(Reminder reminder) {
    final model = ReminderModel.fromEntity(reminder);
    _box.put(model.id, model.toMap());
    return reminder;
  }

  void deleteReminder(String id) => _box.delete(id);

  void markFired(String id, {DateTime? firedAt}) {
    final existing = getReminderById(id);
    if (existing == null) return;
    final updated = existing.copyWith(
      lastFiredAt: firedAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _box.put(id, ReminderModel.fromEntity(updated).toMap());
  }

  void clearAll() => _box.clear();
}

/// Opens (or retrieves) the reminders Hive box lazily.
Future<ReminderLocalDataSource> openReminderDataSource() async {
  final box = await Hive.openBox<dynamic>(AppConstants.remindersBox);
  return ReminderLocalDataSource(box);
}
