import 'package:flutter/material.dart';

/// Centralised color palette for the app.
///
/// Uses a deep purple / violet primary with warm accents. Colors are defined
/// once here and referenced by [AppTheme] so the palette stays consistent
/// across light and dark themes.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF7C5CFC);
  static const Color primaryDark = Color(0xFF5B3FD6);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color secondary = Color(0xFF22D3EE);
  static const Color accent = Color(0xFFFF6B9D);

  // Priorities
  static const Color highPriority = Color(0xFFEF4444);
  static const Color mediumPriority = Color(0xFFF59E0B);
  static const Color lowPriority = Color(0xFF10B981);

  // Categories (consistent hues for chips)
  static const Color personal = Color(0xFF7C5CFC);
  static const Color work = Color(0xFF3B82F6);
  static const Color shopping = Color(0xFFEC4899);
  static const Color health = Color(0xFF10B981);
  static const Color other = Color(0xFF64748B);

  // Surfaces
  static const Color glassLight = Color(0x66FFFFFF);
  static const Color glassDark = Color(0x4D1E1B4B);
  static const Color glassBorderLight = Color(0x33FFFFFF);
  static const Color glassBorderDark = Color(0x66FFFFFF);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}
