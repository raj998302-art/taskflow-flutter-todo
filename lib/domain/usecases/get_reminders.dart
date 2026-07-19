import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';

/// Retrieves all reminders.
class GetReminders {
  GetReminders(this._repository);
  final ReminderRepository _repository;
  Future<List<Reminder>> call() => _repository.getAllReminders();
}
