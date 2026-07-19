import '../entities/reminder.dart';

/// Contract for the reminder repository.
///
/// Implemented by the data layer (Hive). The notification scheduler service
/// also depends on this interface so it can re-arm alarms after device reboot
/// without reaching into Hive directly.
abstract class ReminderRepository {
  Future<List<Reminder>> getAllReminders();
  Future<Reminder?> getReminderById(String id);
  Future<Reminder> createReminder(Reminder reminder);
  Future<Reminder> updateReminder(Reminder reminder);
  Future<void> deleteReminder(String id);
  Future<void> markFired(String id, {DateTime? firedAt});
  Future<void> clearAllReminders();
}
