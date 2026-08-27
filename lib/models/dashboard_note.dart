// ============================================================
// DASHBOARD NOTE MODEL
// ------------------------------------------------------------
// Represents a personal, locally-saved "insight" that the user
// pins to their dashboard. It doubles as:
//   - a bookmarked/pinned indicator (title + highlightValue), and
//   - a freeform note about something they noticed in the data.
// This is fully user-owned data (not from the government API),
// which is what makes CRUD possible for this module.
// ============================================================

class DashboardNote {
  final String id;
  String title;
  String category; // 'Population' | 'Internet' | 'Domains' | 'General'
  String? highlightValue; // optional pinned stat, e.g. "95.4%"
  String note;
  final DateTime createdAt;
  DateTime updatedAt;

  DashboardNote({
    required this.id,
    required this.title,
    required this.category,
    this.highlightValue,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  static const List<String> categories = [
    'Population',
    'Internet',
    'Domains',
    'General',
  ];

  DashboardNote copyWith({
    String? title,
    String? category,
    String? highlightValue,
    bool clearHighlightValue = false,
    String? note,
    DateTime? updatedAt,
  }) {
    return DashboardNote(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      highlightValue: clearHighlightValue
          ? null
          : (highlightValue ?? this.highlightValue),
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'highlightValue': highlightValue,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DashboardNote.fromJson(Map<String, dynamic> json) {
    return DashboardNote(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String? ?? 'General',
      highlightValue: json['highlightValue'] as String?,
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
