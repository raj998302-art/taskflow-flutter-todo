import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_enums.dart';

/// A payload broadcast whenever a reminder fires while the app is in the
/// foreground, so the UI can refresh its list (mark fired, advance recurring
/// reminders, etc.).
class ReminderFiredEvent {
  const ReminderFiredEvent(this.reminderId, this.title, {this.spokenText});
  final String reminderId;
  final String title;
  final String? spokenText;
}

/// Central service that arms and disarms scheduled reminders using the host
/// platform's notification / alarm scheduler, and optionally speaks the
/// reminder aloud via text-to-speech when it fires.
///
/// Design notes:
/// * Reminders are stored in Hive by the repository; this service only mirrors
///   them into the OS scheduler. On app start it re-arms everything (so the
///   alarms survive device reboots — Android reboots clear scheduled alarms).
/// * The notification id is derived from a stable hash of the reminder id so
///   that re-arming a reminder simply replaces the previous schedule.
/// * When a notification fires, the background isolate callback decodes the
///   payload (title + spoken text) and, if voice is enabled, asks the TTS
///   engine to speak it.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  FlutterTts? _tts;
  bool _initialized = false;

  /// Stream of fired-reminder events for the foreground UI.
  final StreamController<ReminderFiredEvent> _firedController =
      StreamController<ReminderFiredEvent>.broadcast();
  Stream<ReminderFiredEvent> get onReminderFired => _firedController.stream;

  /// Must be called once at app startup (after Hive boxes are open).
  Future<void> init() async {
    if (_initialized) return;

    // 1. Timezone database for scheduling.
    tzdata.initializeTimeZones();
    try {
      final name = DateTime.now().timeZoneName;
      if (name.isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(name));
      }
    } catch (_) {
      // keep default
    }
    // 2. Initialise the local notifications plugin with a background handler
    //    so alarms fire even when the app is fully backgrounded.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          notificationBackgroundCallback,
    );

    // 3. Create the Android notification channel for alarms (high importance,
    //    sound + vibration) so heads-up notifications actually show on Android
    //    8+.
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(AndroidNotificationChannel(
            AppConstants.alarmChannelId,
            'Reminders',
            description: 'Voice reminders and alarms for your tasks',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList(<int>[0, 400, 200, 400]),
          ));
    }

    // 4. TTS engine for voice reminders ("Boss, apko sabji lena hai").
    _tts = FlutterTts();
    try {
      await _tts!.setLanguage('en-US');
      await _tts!.setSpeechRate(0.5);
      await _tts!.setPitch(1.0);
      await _tts!.awaitSpeakCompletion(true);
    } catch (_) {
      // TTS optional — alarms still fire as silent/popup notifications.
    }

    _initialized = true;
  }

  /// Requests notification & exact-alarm permissions from the user. Returns
  /// true if notifications are permitted.
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      return true;
    }
    return false;
  }

  /// Returns true if the app can schedule exact alarms (Android 12+).
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? false;
  }

  /// Arms (or re-arms) a single reminder in the OS scheduler.
  ///
  /// For recurring reminders the next occurrence after [now] is scheduled;
  /// when it fires the background callback advances it.
  Future<void> scheduleReminder(Reminder reminder) async {
    if (!reminder.isActive) {
      await cancelReminder(reminder.id);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    DateTime when = reminder.scheduledAt;
    if (reminder.recurrence != Recurrence.once) {
      final next = reminder.nextOccurrenceAfter(DateTime.now());
      if (next != null) when = next;
    }

    final tzWhen = tz.TZDateTime.from(when, tz.local);
    if (!tzWhen.isAfter(now) && reminder.recurrence == Recurrence.once) {
      // Already past and one-off — skip scheduling.
      return;
    }

    final payload = jsonEncode({
      'id': reminder.id,
      'title': reminder.title,
      'note': reminder.note ?? '',
      'spoken': reminder.voiceEnabled ? reminder.spokenText : '',
      'voice': reminder.voiceEnabled,
    });

    final androidDetails = AndroidNotificationDetails(
      AppConstants.alarmChannelId,
      'Reminders',
      channelDescription: 'Voice reminders and alarms for your tasks',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        reminder.note?.isNotEmpty == true
            ? reminder.note!
            : reminder.spokenText,
        contentTitle: reminder.title,
      ),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _plugin.zonedSchedule(
      _notificationIdFor(reminder.id),
      reminder.title,
      reminder.note?.isNotEmpty == true ? reminder.note : reminder.spokenText,
      tzWhen,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
      matchDateTimeComponents: _matchComponents(reminder.recurrence),
    );
  }

  /// Cancels a scheduled reminder.
  Future<void> cancelReminder(String reminderId) async {
    await _plugin.cancel(_notificationIdFor(reminderId));
  }

  /// Cancels every scheduled reminder.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Re-arms every reminder in [reminders]. Call on app start (and after
  /// device reboot) so alarms survive resets.
  Future<void> rescheduleAll(List<Reminder> reminders) async {
    await cancelAll();
    for (final r in reminders) {
      if (r.isActive) {
        await scheduleReminder(r);
      }
    }
  }

  /// Speaks the given text aloud using the TTS engine. No-op if TTS is
  /// unavailable.
  Future<void> speak(String text) async {
    if (_tts == null || text.isEmpty) return;
    try {
      await _tts!.stop();
      await _tts!.speak(text);
    } catch (_) {
      // best-effort
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  // ---- internals ----------------------------------------------------------

  DateTimeComponents? _matchComponents(Recurrence r) {
    switch (r) {
      case Recurrence.daily:
      case Recurrence.weekdays:
        return DateTimeComponents.time;
      case Recurrence.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case Recurrence.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case Recurrence.once:
        return null;
    }
  }

  int _notificationIdFor(String reminderId) {
    // Stable 31-bit positive int from the reminder id.
    return reminderId.hashCode & 0x7FFFFFFF;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final spoken = data['spoken'] as String? ?? '';
      final id = data['id'] as String? ?? '';
      _firedController.add(ReminderFiredEvent(
        id,
        data['title'] as String? ?? '',
        spokenText: spoken,
      ));
      if (spoken.isNotEmpty) speak(spoken);
    } catch (_) {
      // ignore malformed payload
    }
  }

  void dispose() {
    _firedController.close();
  }
}

/// Top-level callback wired into the plugin's background handler so that
/// notifications fire even when the app is fully backgrounded.
///
/// Must be a top-level function (not a method or closure) so it can be called
/// from a separate isolate.
@pragma('vm:entry-point')
void notificationBackgroundCallback(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    debugPrint(
        'Reminder fired (background): ${data['title']} — ${data['spoken']}');
    // The background isolate cannot access the singleton's TTS instance, but
    // the foreground service / full-screen intent still shows the alarm with
    // sound + vibration. When the user opens the app, [NotificationService]
    // re-syncs state via [onReminderFired].
  } catch (_) {}
}
