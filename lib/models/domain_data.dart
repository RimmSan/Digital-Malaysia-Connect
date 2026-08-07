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
    return DomainData(
      date: DateTime.parse(json['date']),
      domain: json['domain'],
      series: json['series'],
      registrations: json['registrations'],
    );
  }
}