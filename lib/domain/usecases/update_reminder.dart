import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';

/// Updates an existing reminder.
class UpdateReminder {
  UpdateReminder(this._repository);
  final ReminderRepository _repository;
  Future<Reminder> call(Reminder reminder) => _repository.updateReminder(reminder);
}
