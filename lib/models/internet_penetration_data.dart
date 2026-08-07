class InternetPenetrationData {
  final DateTime date;
  final double fbbActual;
  final double mbbActual;
  final double mcActual;
  final double ptvActual;
  final double fbbRate;
  final double mbbRate;
  final double mcRate;
  final double ptvRate;

  InternetPenetrationData({
    required this.date,
    required this.fbbActual,
    required this.mbbActual,
    required this.mcActual,
    required this.ptvActual,
    required this.fbbRate,
    required this.mbbRate,
    required this.mcRate,
    required this.ptvRate,
  });

  factory InternetPenetrationData.fromJson(Map<String, dynamic> json) {
    return InternetPenetrationData(
      date: DateTime.parse(json['date']),
      fbbActual: (json['fbb_actual'] as num).toDouble(),
      mbbActual: (json['mbb_actual'] as num).toDouble(),
      mcActual: (json['mc_actual'] as num).toDouble(),
      ptvActual: (json['ptv_actual'] as num).toDouble(),
      fbbRate: (json['fbb_rate'] as num).toDouble(),
      mbbRate: (json['mbb_rate'] as num).toDouble(),
      mcRate: (json['mc_rate'] as num).toDouble(),
      ptvRate: (json['ptv_rate'] as num).toDouble(),
    );
  }
}