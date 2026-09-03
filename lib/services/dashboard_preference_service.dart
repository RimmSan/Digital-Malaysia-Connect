import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_preferences.dart';

class DashboardPreferencesService {
  static const String _prefsKey = 'dashboard_preferences_v1';

  Future<DashboardPreferences> get() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);

    if (raw == null || raw.isEmpty) {
      return DashboardPreferences();
    }

    return DashboardPreferences.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> save(DashboardPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(preferences.toJson()));
  }
}
