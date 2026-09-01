import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/domain_data.dart';

// ============================================================
// GROWTH CACHE SERVICE
// ------------------------------------------------------------
// Offline Data Storage feature: saves the last successful
// domain-data API fetch locally, so the Growth Tracker page can
// still show something meaningful with no internet connection.
// ============================================================

class GrowthCacheService {
  static const String _dataKey = 'growth_cache_data_v1';
  static const String _timeKey = 'growth_cache_time_v1';

  Future<void> save(List<DomainData> data) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(data
        .map((d) => {
      'date': d.date.toIso8601String(),
      'domain': d.domain,
      'series': d.series,
      'registrations': d.registrations,
    })
        .toList());
    await prefs.setString(_dataKey, encoded);
    await prefs.setString(_timeKey, DateTime.now().toIso8601String());
  }

  Future<(List<DomainData>, DateTime)?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dataKey);
    final timeRaw = prefs.getString(_timeKey);

    if (raw == null || timeRaw == null) return null;

    final List<dynamic> decoded = jsonDecode(raw);
    final data = decoded
        .map((json) => DomainData(
      date: DateTime.parse(json['date']),
      domain: json['domain'],
      series: json['series'],
      registrations: json['registrations'],
    ))
        .toList();

    return (data, DateTime.parse(timeRaw));
  }
}