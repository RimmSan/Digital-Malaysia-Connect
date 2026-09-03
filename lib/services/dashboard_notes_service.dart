import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_note.dart';

class DashboardNotesService {
  static const String _storageKey = 'dashboard_notes_v1';
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

    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  Future<void> create(DashboardNote note) async {
    final notes = await getAll();
    notes.insert(0, note);
    await _saveAll(notes);
  }

  Future<void> update(DashboardNote updatedNote) async {
    final notes = await getAll();
    final index = notes.indexWhere((n) => n.id == updatedNote.id);

    if (index == -1) {
      throw Exception('Note not found: ${updatedNote.id}');
    }

    notes[index] = updatedNote;
    await _saveAll(notes);
  }
  Future<void> delete(String id) async {
    final notes = await getAll();
    notes.removeWhere((n) => n.id == id);
    await _saveAll(notes);
  }

  Future<void> _saveAll(List<DashboardNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(notes.map((n) => n.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
