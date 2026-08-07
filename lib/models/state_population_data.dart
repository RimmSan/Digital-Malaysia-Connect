class StatePopulationData {
  final String state;
  final DateTime date;
  final double population;

  StatePopulationData({
    required this.state,
    required this.date,
    required this.population,
  });

  factory StatePopulationData.fromJson(Map<String, dynamic> json) {
    return StatePopulationData(
      state: json['state'],
      date: DateTime.parse(json['date']),
      population: (json['population'] as num).toDouble(),
    );
  }
}