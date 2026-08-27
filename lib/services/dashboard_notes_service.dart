import 'dart:convert';
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

    final List<dynamic> decoded = jsonDecode(raw);
    final notes = decoded
        .map((e) => DashboardNote.fromJson(e as Map<String, dynamic>))
        .toList();

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
