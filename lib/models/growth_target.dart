// ============================================================
// GROWTH TARGET MODEL
// ------------------------------------------------------------
// Represents a user-created .MY domain growth milestone.
// "Achieved" is NOT stored — it's computed live by comparing
// targetValue against the current cumulative registrations,
// so it updates automatically the moment new data arrives.
// ============================================================

class GrowthTarget {
  final String id;
  String label;
  int targetValue; // cumulative .MY registrations to reach
  DateTime deadline;
  final DateTime createdAt;
  DateTime updatedAt;

  GrowthTarget({
    required this.id,
    required this.label,
    required this.targetValue,
    required this.deadline,
    required this.createdAt,
    required this.updatedAt,
  });

  GrowthTarget copyWith({
    String? label,
    int? targetValue,
    DateTime? deadline,
    DateTime? updatedAt,
  }) {
    return GrowthTarget(
      id: id,
      label: label ?? this.label,
      targetValue: targetValue ?? this.targetValue,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'targetValue': targetValue,
      'deadline': deadline.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GrowthTarget.fromJson(Map<String, dynamic> json) {
    return GrowthTarget(
      id: json['id'] as String,
      label: json['label'] as String,
      targetValue: json['targetValue'] as int,
      deadline: DateTime.parse(json['deadline'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}