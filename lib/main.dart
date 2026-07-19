import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';
import 'presentation/providers/app_settings_provider.dart';
import 'presentation/providers/lock_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local database — open every box eagerly so the
  // repository providers can construct synchronously.
  await Hive.initFlutter();
  await Hive.openBox<dynamic>(AppConstants.tasksBox);
  await Hive.openBox<dynamic>(AppConstants.remindersBox);
  await Hive.openBox<dynamic>(AppConstants.settingsBox);

  // Initialize the notification + TTS service. This sets up the alarm
  // channel, loads the timezone database, and prepares the TTS engine so
  // voice reminders can fire as soon as the app runs.
  await NotificationService.instance.init();

  // Load SharedPreferences-backed app settings (onboarding seen, app lock,
  // accent color, auto-lock delay) before running the app so the router
  // redirect logic has the correct initial state.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        appSettingsProvider.overrideWith((ref) {
          final notifier = AppSettingsNotifier(prefs);
          notifier.load();
          return notifier;
        }),
        lockRepositoryProvider.overrideWithValue(createLockRepository(prefs)),
      ],
      child: const TodoApp(),
    ),
  );
}
