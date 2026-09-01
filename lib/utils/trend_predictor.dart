// ============================================================
// TREND PREDICTOR
// ------------------------------------------------------------
// Powers the "Digital Trend Prediction" additional feature for
// the Connectivity Analytics module. Uses ordinary least-squares
// linear regression over the selected metric's historical values
// to project the next period. Intentionally simple (no external
// ML package needed) but gives a genuine data-driven forecast
// rather than a hardcoded guess.
// ============================================================

class TrendPrediction {
  final double predictedNextValue;
  final double slopePerPeriod;
  final bool isRising;

  const TrendPrediction({
    required this.predictedNextValue,
    required this.slopePerPeriod,
    required this.isRising,
  });
}

class TrendPredictor {
  /// [values] should be ordered oldest -> newest.
  /// Returns null if there isn't enough data to fit a line.
  static TrendPrediction? predictNext(List<double> values) {
    final n = values.length;
    if (n < 2) return null;

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

    final nextX = n.toDouble(); // next period index
    final predicted = slope * nextX + intercept;

    return TrendPrediction(
      predictedNextValue: predicted,
      slopePerPeriod: slope,
      isRising: slope >= 0,
    );
  }
}
