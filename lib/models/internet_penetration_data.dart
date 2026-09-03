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

  static double _numOrZero(dynamic value) {
    if (value is num) return value.toDouble();
    return 0.0;
  }

  factory InternetPenetrationData.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    final date = rawDate == null ? null : DateTime.tryParse(rawDate.toString());
    if (date == null) {
      throw FormatException(
        'InternetPenetrationData: missing/invalid date "$rawDate"',
      );
    }

    return InternetPenetrationData(
      date: date,
      fbbActual: _numOrZero(json['fbb_actual']),
      mbbActual: _numOrZero(json['mbb_actual']),
      mcActual: _numOrZero(json['mc_actual']),
      ptvActual: _numOrZero(json['ptv_actual']),
      fbbRate: _numOrZero(json['fbb_rate']),
      mbbRate: _numOrZero(json['mbb_rate']),
      mcRate: _numOrZero(json['mc_rate']),
      ptvRate: _numOrZero(json['ptv_rate']),
    );
  }
}
