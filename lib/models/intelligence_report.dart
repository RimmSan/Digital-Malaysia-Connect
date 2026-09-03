class IntelligenceReport {
  final String id;

  String title;

  String stateA;
  String? stateB;

  String reportType;

  String insight;
  String note;

  final DateTime createdAt;
  DateTime updatedAt;

  IntelligenceReport({
    required this.id,
    required this.title,
    required this.stateA,
    this.stateB,
    required this.reportType,
    required this.insight,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  IntelligenceReport copyWith({
    String? title,
    String? stateA,
    String? stateB,
    bool clearStateB = false,
    String? reportType,
    String? insight,
    String? note,
    DateTime? updatedAt,
  }) {
    return IntelligenceReport(
      id: id,
      title: title ?? this.title,
      stateA: stateA ?? this.stateA,
      stateB: clearStateB ? null : (stateB ?? this.stateB),
      reportType: reportType ?? this.reportType,
      insight: insight ?? this.insight,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'stateA': stateA,
      'stateB': stateB,
      'reportType': reportType,
      'insight': insight,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory IntelligenceReport.fromJson(Map<String, dynamic> json) {
    return IntelligenceReport(
      id: json['id'] as String,
      title: json['title'] as String,
      stateA: json['stateA'] as String,
      stateB: json['stateB'] as String?,
      reportType: json['reportType'] as String,
      insight: json['insight'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}