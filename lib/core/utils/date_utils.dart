import 'package:intl/intl.dart';

/// Date and time helper utilities used across the app.
class DateUtilsX {
  DateUtilsX._();

  /// Formats a [date] as a human-friendly relative label.
  ///
  /// - Today      -> "Today"
  /// - Tomorrow   -> "Tomorrow"
  /// - Yesterday  -> "Yesterday"
  /// - This week  -> "Mon"
  /// - This year  -> "Mar 5"
  /// - Older      -> "Mar 5, 2024"
  static String formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';

    if (target.isAfter(today) && diff < 7) {
      return DateFormat('EEEE').format(date); // weekday name
    }

    if (date.year == now.year) {
      return DateFormat('MMM d').format(date);
    }
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Returns true if [date] is overdue relative to today (day-level).
  static bool isOverdue(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(today);
  }

  /// Returns true if [date] falls on today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Formats a full timestamp, e.g. "Mar 5, 2024 · 2:30 PM".
  static String formatTimestamp(DateTime date) {
    return '${DateFormat('MMM d, yyyy').format(date)} · '
        '${DateFormat('jmv').format(date)}';
  }

  /// Returns the date string used when grouping tasks, e.g. "Today", "Tomorrow",
  /// "Mon, Mar 5".
  static String groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff < 0 && diff > -7) {
      return DateFormat('EEEE').format(date);
    }
    return DateFormat('EEE, MMM d').format(date);
  }
}
