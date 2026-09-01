import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/watchlist_alert.dart';

// ============================================================
// WATCHLIST SERVICE
// ------------------------------------------------------------
// Full CRUD (Create, Read, Update, Delete) for the user's
// locally-saved connectivity metric alerts. Same storage
// approach as DashboardNotesService: one JSON-encoded list
// under a single SharedPreferences key.
// ============================================================

class WatchlistService {
  static const String _storageKey = 'analytics_watchlist_v1';

  // ------------------------------------------------------------
  // READ (all)
  // ------------------------------------------------------------
  Future<List<WatchlistAlert>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(raw);
    final alerts = decoded
        .map((e) => WatchlistAlert.fromJson(e as Map<String, dynamic>))
        .toList();

    alerts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return alerts;
  }

  // ------------------------------------------------------------
  // CREATE
  // ------------------------------------------------------------
  Future<void> create(WatchlistAlert alert) async {
    final alerts = await getAll();
    alerts.insert(0, alert);
    await _saveAll(alerts);
  }

  // ------------------------------------------------------------
  // UPDATE
  // ------------------------------------------------------------
  Future<void> update(WatchlistAlert updatedAlert) async {
    final alerts = await getAll();
    final index = alerts.indexWhere((a) => a.id == updatedAlert.id);

    if (index == -1) {
      throw Exception('Alert not found: ${updatedAlert.id}');
    }

    alerts[index] = updatedAlert;
    await _saveAll(alerts);
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------
  Future<void> delete(String id) async {
    final alerts = await getAll();
    alerts.removeWhere((a) => a.id == id);
    await _saveAll(alerts);
  }

  // ------------------------------------------------------------
  // Internal helper: persist the full list back to prefs.
  // ------------------------------------------------------------
  Future<void> _saveAll(List<WatchlistAlert> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(alerts.map((a) => a.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
