import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/notification_service.dart';
import '../../data/repositories/reminder_repository_impl.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_enums.dart';
import '../../domain/repositories/reminder_repository.dart';

/// Provides a single [ReminderRepository] instance backed by Hive.
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return createReminderRepositorySync();
});

/// Notifier that owns the in-memory reminder list and exposes all CRUD
/// operations. Every mutation also mirrors the change into the OS alarm
/// scheduler via [NotificationService] so alarms stay in sync with the data.
class ReminderListNotifier extends StateNotifier<AsyncValue<List<Reminder>>> {
  ReminderListNotifier(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }

  final ReminderRepository _repository;
  final _uuid = const Uuid();

  Future<void> _load() async {
    try {
      final reminders = await _repository.getAllReminders();
      // Re-arm every active reminder so they survive app/device restarts.
      await NotificationService.instance.rescheduleAll(reminders);
      if (!mounted) return;
      state = AsyncValue.data(reminders);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<Reminder> addReminder({
    required String title,
    String? note,
    required DateTime scheduledAt,
    required Recurrence recurrence,
    required bool voiceEnabled,
    required String voicePrefix,
  }) async {
    final now = DateTime.now();
    final reminder = Reminder(
      id: _uuid.v4(),
      title: title.trim(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      scheduledAt: scheduledAt,
      recurrence: recurrence,
      voiceEnabled: voiceEnabled,
      voicePrefix: voicePrefix.trim().isEmpty
          ? AppConstants.defaultVoicePrefix
          : voicePrefix.trim(),
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    final saved = await _repository.createReminder(reminder);
    await NotificationService.instance.scheduleReminder(saved);
    state = AsyncValue.data([...?state.value, saved]);
    return saved;
  }

  Future<void> updateReminder(Reminder reminder) async {
    final updated = reminder.copyWith(updatedAt: DateTime.now());
    await _repository.updateReminder(updated);
    await NotificationService.instance.scheduleReminder(updated);
    final list = state.value ?? [];
    state = AsyncValue.data([
      for (final r in list) if (r.id == updated.id) updated else r,
    ]);
  }

  Future<void> toggleActive(String id) async {
    final list = state.value ?? [];
    final existing = list.where((r) => r.id == id).firstOrNull;
    if (existing == null) return;
    final updated = existing.copyWith(
      isActive: !existing.isActive,
      updatedAt: DateTime.now(),
    );
    await _repository.updateReminder(updated);
    if (updated.isActive) {
      await NotificationService.instance.scheduleReminder(updated);
    } else {
      await NotificationService.instance.cancelReminder(updated.id);
    }
    state = AsyncValue.data([
      for (final r in list) if (r.id == id) updated else r,
    ]);
  }

  Future<void> deleteReminder(String id) async {
    final previous = state.value ?? [];
    state = AsyncValue.data(previous.where((r) => r.id != id).toList());
    try {
      await _repository.deleteReminder(id);
      await NotificationService.instance.cancelReminder(id);
    } catch (_) {
      state = AsyncValue.data(previous);
    }
  }

  Future<void> markFired(String id) async {
    final list = state.value ?? [];
    final existing = list.where((r) => r.id == id).firstOrNull;
    if (existing == null) return;
    await _repository.markFired(id);
    final updated = existing.copyWith(
      lastFiredAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    // For one-off reminders, deactivate after firing.
    if (existing.recurrence == Recurrence.once) {
      final deactivated = updated.copyWith(isActive: false);
      await _repository.updateReminder(deactivated);
      await NotificationService.instance.cancelReminder(id);
      state = AsyncValue.data([
        for (final r in list) if (r.id == id) deactivated else r,
      ]);
    } else {
      state = AsyncValue.data([
        for (final r in list) if (r.id == id) updated else r,
      ]);
    }
  }

  Future<void> clearAll() async {
    state = const AsyncValue.data([]);
    await NotificationService.instance.cancelAll();
    await _repository.clearAllReminders();
  }
}

/// The primary provider the UI watches for the current list of reminders.
final reminderListProvider =
    StateNotifierProvider<ReminderListNotifier, AsyncValue<List<Reminder>>>(
        (ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return ReminderListNotifier(repo);
});

extension on Iterable<Reminder> {
  Reminder? get firstOrNull => isEmpty ? null : first;
}
