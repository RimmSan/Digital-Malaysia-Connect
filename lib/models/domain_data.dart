class DomainData {
  final DateTime date;
  final String domain;
  final String series;
  final int registrations;

  DomainData({
    required this.date,
    required this.domain,
    required this.series,
    required this.registrations,
  });

  factory DomainData.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    final date = rawDate == null ? null : DateTime.tryParse(rawDate.toString());
    if (date == null) {
      throw FormatException('DomainData: missing/invalid date "$rawDate"');
    }

    final rawRegistrations = json['registrations'];
    if (rawRegistrations is! num) {
      throw FormatException(
        'DomainData: missing/invalid registrations "$rawRegistrations"',
      );
    }

    return DomainData(
      date: date,
      domain: (json['domain'] as String?) ?? 'Unknown',
      series: (json['series'] as String?) ?? 'Unknown',
      registrations: rawRegistrations.toInt(),
    );
  }
}
