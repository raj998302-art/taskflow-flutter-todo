/// Application-wide constant values.
class AppConstants {
  AppConstants._();

  static const String appName = 'Taskflow';

  // Hive box names
  static const String tasksBox = 'tasks_box';
  static const String remindersBox = 'reminders_box';
  static const String settingsBox = 'settings_box';

  // Settings keys
  static const String themeModeKey = 'theme_mode';
  static const String firstRunKey = 'first_run';

  // Notification channel for alarm reminders
  static const String alarmChannelId = 'taskflow_reminders';
  static const String alarmChannelName = 'Reminders';

  // Default voice prefix spoken before the reminder title.
  static const String defaultVoicePrefix = 'Boss';

  // Default task categories
  static const List<String> defaultCategories = [
    'Personal',
    'Work',
    'Shopping',
    'Health',
    'Other',
  ];

  // Animation durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 600);
}
