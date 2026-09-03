import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/watchlist_alert.dart';

class WatchlistService {
  static const String _key = 'analytics_watchlist_v1';

  Future<List<WatchlistAlert>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    final alerts = decoded.map((e) => WatchlistAlert.fromJson(e as Map<String, dynamic>)).toList();
    alerts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return alerts;
  }

  Future<void> create(WatchlistAlert alert) async {
    final alerts = await getAll();
    alerts.insert(0, alert);
    await _saveAll(alerts);
  }

  Future<void> update(WatchlistAlert updated) async {
    final alerts = await getAll();
    final index = alerts.indexWhere((a) => a.id == updated.id);
    if (index == -1) return;
    alerts[index] = updated;
    await _saveAll(alerts);
  }

  Future<void> delete(String id) async {
    final alerts = await getAll();
    alerts.removeWhere((a) => a.id == id);
    await _saveAll(alerts);
  }

  Future<void> _saveAll(List<WatchlistAlert> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(alerts.map((a) => a.toJson()).toList()));
  }
}