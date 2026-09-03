class DashboardNote {
  final String id;
  String title;
  String category;
  String? highlightValue;
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
    final rawId = json['id'];
    if (rawId is! String || rawId.isEmpty) {
      throw FormatException('DashboardNote: missing/invalid id "$rawId"');
    }

    final rawTitle = json['title'];
    if (rawTitle is! String || rawTitle.trim().isEmpty) {
      throw FormatException('DashboardNote: missing/invalid title "$rawTitle"');
    }

    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final updatedAt = DateTime.tryParse(json['updatedAt']?.toString() ?? '');

    return DashboardNote(
      id: rawId,
      title: rawTitle,
      category: DashboardNote.categories.contains(json['category'])
          ? json['category'] as String
          : 'General',
      highlightValue: (json['highlightValue'] as String?)?.trim().isEmpty ==
          true
          ? null
          : json['highlightValue'] as String?,
      note: json['note'] as String? ?? '',

      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
