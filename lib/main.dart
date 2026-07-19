import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';

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

  runApp(
    const ProviderScope(
      child: TodoApp(),
    ),
  );
}
