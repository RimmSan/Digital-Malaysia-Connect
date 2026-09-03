class TrendPrediction {
  final double predictedNextValue;
  final double slopePerPeriod;
  final bool isRising;
  final List<double> forecastSeries;

  const TrendPrediction({
    required this.predictedNextValue,
    required this.slopePerPeriod,
    required this.isRising,
    required this.forecastSeries,
  });
}

class TrendPredictor {
  static TrendPrediction? predictNext(List<double> values, {int periodsAhead = 1}) {
    final n = values.length;
    if (n < 2 || periodsAhead < 1) return null;

    final xs = List<double>.generate(n, (i) => i.toDouble());
    final xMean = xs.reduce((a, b) => a + b) / n;
    final yMean = values.reduce((a, b) => a + b) / n;

    double numerator = 0;
    double denominator = 0;
    for (int i = 0; i < n; i++) {
      numerator += (xs[i] - xMean) * (values[i] - yMean);
      denominator += (xs[i] - xMean) * (xs[i] - xMean);
    }
    if (denominator == 0) return null;

    final slope = numerator / denominator;
    final intercept = yMean - slope * xMean;
    final forecast = List<double>.generate(periodsAhead, (i) => slope * (n + i) + intercept);

    return TrendPrediction(
      predictedNextValue: forecast.first,
      slopePerPeriod: slope,
      isRising: slope >= 0,
      forecastSeries: forecast,
    );
  }
}