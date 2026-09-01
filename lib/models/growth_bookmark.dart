class GrowthBookmark {
  final String id;
  String label;
  int snapshotValue; // now mutable — editable for testing
  final DateTime savedAt;

  GrowthBookmark({
    required this.id,
    required this.label,
    required this.snapshotValue,
    required this.savedAt,
  });

  GrowthBookmark copyWith({String? label, int? snapshotValue}) {
    return GrowthBookmark(
      id: id,
      label: label ?? this.label,
      snapshotValue: snapshotValue ?? this.snapshotValue,
      savedAt: savedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'snapshotValue': snapshotValue,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory GrowthBookmark.fromJson(Map<String, dynamic> json) {
    return GrowthBookmark(
      id: json['id'] as String,
      label: json['label'] as String,
      snapshotValue: json['snapshotValue'] as int,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}