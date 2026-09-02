import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_note.dart';

// ============================================================
// DASHBOARD NOTES SERVICE
// ------------------------------------------------------------
// Provides full CRUD (Create, Read, Update, Delete) for the
// user's locally-saved dashboard insights/pinned indicators.
//
// Storage: SharedPreferences, as a single JSON-encoded list
// under one key. This is intentionally simple (no local DB
// setup required) but still gives real persistence across
// app restarts.
// ============================================================

class DashboardNotesService {
  static const String _storageKey = 'dashboard_notes_v1';

  // ------------------------------------------------------------
  // READ (all)
  // ------------------------------------------------------------
  Future<List<DashboardNote>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    List<dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as List<dynamic>;
    } catch (e) {
      // Corrupted storage (shouldn't normally happen since we only
      // ever write our own JSON) - fail safe to an empty list rather
      // than crashing the whole dashboard on startup.
      debugPrint('DashboardNotesService: corrupted storage, resetting: $e');
      return [];
    }

    final notes = <DashboardNote>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) {
        debugPrint('DashboardNotesService: skipping malformed record: $item');
        continue;
      }
      try {
        notes.add(DashboardNote.fromJson(item));
      } catch (e) {
        debugPrint('DashboardNotesService: skipping malformed note: $e');
      }
    }

    // Most recently updated first.
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  // ------------------------------------------------------------
  // CREATE
  // ------------------------------------------------------------
  Future<void> create(DashboardNote note) async {
    final notes = await getAll();
    notes.insert(0, note);
    await _saveAll(notes);
  }

  // ------------------------------------------------------------
  // UPDATE
  // ------------------------------------------------------------
  Future<void> update(DashboardNote updatedNote) async {
    final notes = await getAll();
    final index = notes.indexWhere((n) => n.id == updatedNote.id);

    if (index == -1) {
      throw Exception('Note not found: ${updatedNote.id}');
    }

    notes[index] = updatedNote;
    await _saveAll(notes);
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------
  Future<void> delete(String id) async {
    final notes = await getAll();
    notes.removeWhere((n) => n.id == id);
    await _saveAll(notes);
  }

  // ------------------------------------------------------------
  // Internal helper: persist the full list back to prefs.
  // ------------------------------------------------------------
  Future<void> _saveAll(List<DashboardNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(notes.map((n) => n.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
