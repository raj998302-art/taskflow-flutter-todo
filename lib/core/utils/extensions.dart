import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/date_utils.dart';

/// Common [DateTime] helpers re-exported under a single import name.
export 'date_utils.dart' show DateUtilsX;

/// Helpers for [BuildContext].
extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  bool get isMobile => MediaQuery.sizeOf(this).width < 600;
  bool get isTablet =>
      MediaQuery.sizeOf(this).width >= 600 &&
      MediaQuery.sizeOf(this).width < 1024;
  bool get isDesktop => MediaQuery.sizeOf(this).width >= 1024;
}

/// Color helpers for [Color].
extension ColorX on Color {
  Color withOpacityValue(double v) => withValues(alpha: v);
}

/// Helpers for [DateTime] using the app's [DateUtilsX].
extension DateTimeX on DateTime {
  bool get isOverdue => DateUtilsX.isOverdue(this);
  bool get isToday => DateUtilsX.isToday(this);
  String get dueLabel => DateUtilsX.formatDueDate(this);
  String get groupLabel => DateUtilsX.groupLabel(this);
  DateTime get dateOnly => DateTime(year, month, day);
}

/// Map a priority label string to its color.
String priorityLabel(String priority) {
  switch (priority.toLowerCase()) {
    case 'high':
      return 'High';
    case 'low':
      return 'Low';
    default:
      return 'Medium';
  }
}

/// Return the [Color] associated with a priority string.
Color priorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'high':
      return AppColors.highPriority;
    case 'low':
      return AppColors.lowPriority;
    default:
      return AppColors.mediumPriority;
  }
}
