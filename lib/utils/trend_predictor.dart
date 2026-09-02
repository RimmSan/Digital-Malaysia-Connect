// ============================================================
// TREND PREDICTOR
// ------------------------------------------------------------
// Powers the "Digital Trend Prediction" additional feature for
// the Connectivity Analytics module. Uses ordinary least-squares
// linear regression over the selected metric's historical values
// to project future periods. Intentionally simple (no external
// ML package needed) but gives a genuine data-driven forecast
// rather than a hardcoded guess.
// ============================================================

class TrendPrediction {
  final double predictedNextValue;
  final double slopePerPeriod;
  final bool isRising;

  /// Forecasted values for periods 1..N ahead of the last known
  /// period, in order (index 0 = next period, index 1 = the one
  /// after that, etc).
  final List<double> forecastSeries;

  const TrendPrediction({
    required this.predictedNextValue,
    required this.slopePerPeriod,
    required this.isRising,
    required this.forecastSeries,
  });
}

class TrendPredictor {
  /// [values] should be ordered oldest -> newest.
  /// [periodsAhead] controls how many future points to forecast
  /// (default 1, matching the original single-quarter prediction).
  /// Returns null if there isn't enough data to fit a line.
  static TrendPrediction? predictNext(
      List<double> values, {
        int periodsAhead = 1,
      }) {
    final n = values.length;
    if (n < 2 || periodsAhead < 1) return null;

    // x = 0, 1, 2, ... n-1 (period index)
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

    final forecast = List<double>.generate(periodsAhead, (i) {
      final futureX = (n + i).toDouble(); // period index n, n+1, ...
      return slope * futureX + intercept;
    });

    return TrendPrediction(
      predictedNextValue: forecast.first,
      slopePerPeriod: slope,
      isRising: slope >= 0,
      forecastSeries: forecast,
    );
  }
}