import '../../domain/repositories/reminder_repository.dart';

/// Marks a reminder as having fired at the given time (used by the
/// notification service to advance recurring reminders).
class MarkReminderFired {
  MarkReminderFired(this._repository);
  final ReminderRepository _repository;
  Future<void> call(String id, {DateTime? firedAt}) =>
      _repository.markFired(id, firedAt: firedAt);
}
