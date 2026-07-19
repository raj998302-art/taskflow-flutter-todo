import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';

/// Creates a new reminder.
class AddReminder {
  AddReminder(this._repository);
  final ReminderRepository _repository;
  Future<Reminder> call(Reminder reminder) => _repository.createReminder(reminder);
}
