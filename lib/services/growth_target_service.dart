import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/growth_target.dart';

// ============================================================
// GROWTH TARGET SERVICE
// ------------------------------------------------------------
// Full CRUD for user-created growth milestones. Same pattern
// as DashboardNotesService / IntelligenceReportsService — single
// JSON-encoded list under one SharedPreferences key.
// ============================================================

class GrowthTargetService {
  static const String _storageKey = 'growth_targets_v1';

  // ------------------------------------------------------------
  // READ (all)
  // ------------------------------------------------------------
  Future<List<GrowthTarget>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(raw);
    final targets = decoded
        .map((e) => GrowthTarget.fromJson(e as Map<String, dynamic>))
        .toList();

    targets.sort((a, b) => a.deadline.compareTo(b.deadline));
    return targets;
  }

  // ------------------------------------------------------------
  // CREATE
  // ------------------------------------------------------------
  Future<void> create(GrowthTarget target) async {
    final targets = await getAll();
    targets.insert(0, target);
    await _saveAll(targets);
  }

  // ------------------------------------------------------------
  // UPDATE
  // ------------------------------------------------------------
  Future<void> update(GrowthTarget updatedTarget) async {
    final targets = await getAll();
    final index = targets.indexWhere((t) => t.id == updatedTarget.id);

    if (index == -1) {
      throw Exception('Growth target not found: ${updatedTarget.id}');
    }

    targets[index] = updatedTarget;
    await _saveAll(targets);
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------
  Future<void> delete(String id) async {
    final targets = await getAll();
    targets.removeWhere((t) => t.id == id);
    await _saveAll(targets);
  }

  // ------------------------------------------------------------
  // Internal helper
  // ------------------------------------------------------------
  Future<void> _saveAll(List<GrowthTarget> targets) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(targets.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}