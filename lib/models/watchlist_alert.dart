enum WatchlistDirection { above, below }

class WatchlistAlert {
  final String id;
  String metricKey;
  String metricLabel;
  double threshold;
  WatchlistDirection direction;
  final DateTime createdAt;
  DateTime updatedAt;

  WatchlistAlert({
    required this.id,
    required this.metricKey,
    required this.metricLabel,
    required this.threshold,
    required this.direction,
    required this.createdAt,
    required this.updatedAt,
  });

  static const List<String> metricKeys = ['fbbRate', 'mbbRate', 'mcRate', 'ptvRate'];

  static String labelFor(String key) {
    switch (key) {
      case 'fbbRate':
        return 'Fixed Broadband';
      case 'mbbRate':
        return 'Mobile Broadband';
      case 'mcRate':
        return 'Mobile Cellular';
      case 'ptvRate':
        return 'Pay TV';
      default:
        return key;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'metricKey': metricKey,
    'metricLabel': metricLabel,
    'threshold': threshold,
    'direction': direction.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory WatchlistAlert.fromJson(Map<String, dynamic> json) => WatchlistAlert(
    id: json['id'] as String,
    metricKey: json['metricKey'] as String,
    metricLabel: json['metricLabel'] as String,
    threshold: (json['threshold'] as num).toDouble(),
    direction: WatchlistDirection.values.firstWhere(
          (d) => d.name == json['direction'],
      orElse: () => WatchlistDirection.above,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}