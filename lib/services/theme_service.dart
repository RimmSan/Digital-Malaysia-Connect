import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// THEME SERVICE
// ------------------------------------------------------------
// Dark Mode has to be controlled from the app root (main.dart)
// because it affects every screen, not just Settings. This
// service exposes a ValueNotifier that MaterialApp listens to,
// and persists the choice with SharedPreferences so it survives
// app restarts.
//
// Usage:
//   - Call ThemeService.load() once before runApp().
//   - Wrap MaterialApp in a ValueListenableBuilder listening to
//     ThemeService.themeMode.
//   - From Settings, call ThemeService.setDarkMode(true/false).
// ============================================================

class ThemeService {
  ThemeService._();

  static const String _prefsKey = 'dark_mode_enabled';

  static final ValueNotifier<ThemeMode> themeMode =
  ValueNotifier(ThemeMode.light);

  static bool get isDarkMode => themeMode.value == ThemeMode.dark;

  /// Loads the saved preference. Defaults to light mode if none saved yet.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_prefsKey) ?? false;
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setDarkMode(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, isDark);
  }
}
