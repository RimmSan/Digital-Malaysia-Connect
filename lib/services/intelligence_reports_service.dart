import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/intelligence_report.dart';

class IntelligenceReportsService {
  static const String _storageKey = 'intelligence_reports_v1';

  Future<List<IntelligenceReport>> getAll() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(raw);

    final reports = decoded
        .map(
          (json) => IntelligenceReport.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();

    reports.sort(
          (a, b) => b.updatedAt.compareTo(a.updatedAt),
    );

    return reports;
  }

  Future<void> create(IntelligenceReport report) async {
    final reports = await getAll();

    reports.insert(0, report);

    await _saveAll(reports);
  }

  Future<void> update(IntelligenceReport updatedReport) async {
    final reports = await getAll();

    final index = reports.indexWhere(
          (report) => report.id == updatedReport.id,
    );

    if (index == -1) {
      throw Exception(
        'Intelligence report not found: ${updatedReport.id}',
      );
    }

    reports[index] = updatedReport;

    await _saveAll(reports);
  }

  Future<void> delete(String id) async {
    final reports = await getAll();

    reports.removeWhere(
          (report) => report.id == id,
    );

    await _saveAll(reports);
  }

  Future<void> _saveAll(
      List<IntelligenceReport> reports,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      reports
          .map(
            (report) => report.toJson(),
      )
          .toList(),
    );

    await prefs.setString(
      _storageKey,
      encoded,
    );
  }
}