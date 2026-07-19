import '../../domain/repositories/reminder_repository.dart';

/// Deletes a reminder by id.
class DeleteReminder {
  DeleteReminder(this._repository);
  final ReminderRepository _repository;
  Future<void> call(String id) => _repository.deleteReminder(id);
}
