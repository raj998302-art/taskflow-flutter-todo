import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/repositories/reminder_repository.dart';
import '../datasources/local/reminder_local_datasource.dart';

/// Concrete [ReminderRepository] backed by Hive.
class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl(this._dataSource);
  final ReminderLocalDataSource _dataSource;

  @override
  Future<List<Reminder>> getAllReminders() async => _dataSource.getAllReminders();

  @override
  Future<Reminder?> getReminderById(String id) =>
      Future.value(_dataSource.getReminderById(id));

  @override
  Future<Reminder> createReminder(Reminder reminder) async =>
      _dataSource.createReminder(reminder);

  @override
  Future<Reminder> updateReminder(Reminder reminder) async =>
      _dataSource.updateReminder(reminder);

  @override
  Future<void> deleteReminder(String id) async => _dataSource.deleteReminder(id);

  @override
  Future<void> markFired(String id, {DateTime? firedAt}) async =>
      _dataSource.markFired(id, firedAt: firedAt);

  @override
  Future<void> clearAllReminders() async => _dataSource.clearAll();
}

/// Opens the Hive box (no-op after first call) and constructs the repository.
Future<ReminderRepository> createReminderRepository() async {
  final box = await Hive.openBox<dynamic>(AppConstants.remindersBox);
  return ReminderRepositoryImpl(ReminderLocalDataSource(box));
}

/// Synchronous constructor that reuses an already-open Hive box.
ReminderRepository createReminderRepositorySync() {
  final box = Hive.box<dynamic>(AppConstants.remindersBox);
  return ReminderRepositoryImpl(ReminderLocalDataSource(box));
}
