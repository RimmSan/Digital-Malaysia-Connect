import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/growth_bookmark.dart';

class GrowthBookmarkService {
  static const String _storageKey = 'growth_bookmarks_v1';

  Future<List<GrowthBookmark>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(raw);
    final bookmarks = decoded
        .map((e) => GrowthBookmark.fromJson(e as Map<String, dynamic>))
        .toList();

    bookmarks.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return bookmarks;
  }

  Future<void> create(GrowthBookmark bookmark) async {
    final bookmarks = await getAll();
    bookmarks.insert(0, bookmark);
    await _saveAll(bookmarks);
  }

  Future<void> update(GrowthBookmark updated) async {
    final bookmarks = await getAll();
    final index = bookmarks.indexWhere((b) => b.id == updated.id);

    if (index == -1) {
      throw Exception('Bookmark not found: ${updated.id}');
    }

    bookmarks[index] = updated;
    await _saveAll(bookmarks);
  }

  Future<void> delete(String id) async {
    final bookmarks = await getAll();
    bookmarks.removeWhere((b) => b.id == id);
    await _saveAll(bookmarks);
  }

  Future<void> _saveAll(List<GrowthBookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(bookmarks.map((b) => b.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}