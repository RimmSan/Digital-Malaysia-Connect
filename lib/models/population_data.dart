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
    return PopulationData(
      age: json['age'],
      sex: json['sex'],
      date: DateTime.parse(json['date']),
      ethnicity: json['ethnicity'],
      population: (json['population'] as num).toDouble(),
    );
  }
}