class PopulationData {
  final String age;
  final String sex;
  final DateTime date;
  final String ethnicity;
  final double population;

  PopulationData({
    required this.age,
    required this.sex,
    required this.date,
    required this.ethnicity,
    required this.population,
  });

  factory PopulationData.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    final date = rawDate == null ? null : DateTime.tryParse(rawDate.toString());
    if (date == null) {
      throw FormatException('PopulationData: missing/invalid date "$rawDate"');
    }

    final rawPopulation = json['population'];
    if (rawPopulation is! num) {
      throw FormatException(
        'PopulationData: missing/invalid population "$rawPopulation"',
      );
    }

    return PopulationData(
      age: (json['age'] as String?) ?? 'unknown',
      sex: (json['sex'] as String?) ?? 'unknown',
      date: date,
      ethnicity: (json['ethnicity'] as String?) ?? 'unknown',
      population: rawPopulation.toDouble(),
    );
  }
}
