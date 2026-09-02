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
    // date and registrations are load-bearing for every dashboard
    // calculation that touches this dataset - if either is missing
    // or malformed, throw so ApiService skips just this one record
    // instead of silently treating it as zero/today.
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
      // domain/series are only used for display/grouping - fall back
      // to a safe placeholder rather than dropping the whole record.
      domain: (json['domain'] as String?) ?? 'Unknown',
      series: (json['series'] as String?) ?? 'Unknown',
      registrations: rawRegistrations.toInt(),
    );
  }
}
