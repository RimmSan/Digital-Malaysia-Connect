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
    final rawState = json['state'];
    if (rawState is! String || rawState.trim().isEmpty) {
      throw FormatException('StatePopulationData: missing/invalid state "$rawState"');
    }

    final rawDate = json['date'];
    final date = rawDate == null ? null : DateTime.tryParse(rawDate.toString());
    if (date == null) {
      throw FormatException(
        'StatePopulationData: missing/invalid date "$rawDate"',
      );
    }

    final rawPopulation = json['population'];
    if (rawPopulation is! num) {
      throw FormatException(
        'StatePopulationData: missing/invalid population "$rawPopulation"',
      );
    }

    return StatePopulationData(
      state: rawState,
      date: date,
      population: rawPopulation.toDouble(),
    );
  }
}
