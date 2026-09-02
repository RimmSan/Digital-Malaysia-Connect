import 'package:flutter/material.dart';

// ============================================================
// PREDICTION SPARKLINE CHART
// ------------------------------------------------------------
// Like SparklineChart, but draws two segments:
//   - historical values: solid line + filled area (same look
//     as the existing SparklineChart used elsewhere in the app)
//   - forecast values: dashed line continuing on from the last
//     historical point, in a lighter/different color, with
//     hollow dots instead of a filled dot.
// No external chart package - CustomPainter only, consistent
// with the rest of the app's charting approach.
// ============================================================

class PredictionSparklineChart extends StatelessWidget {
  final List<double> historicalValues;
  final List<double> forecastValues;
  final Color historicalColor;
  final Color forecastColor;
  final double height;

  const PredictionSparklineChart({
    super.key,
    required this.historicalValues,
    required this.forecastValues,
    required this.historicalColor,
    required this.forecastColor,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    if (historicalValues.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Not enough data to chart',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _PredictionPainter(
          historicalValues: historicalValues,
          forecastValues: forecastValues,
          historicalColor: historicalColor,
          forecastColor: forecastColor,
        ),
      ),
    );
  }
}

class _PredictionPainter extends CustomPainter {
  final List<double> historicalValues;
  final List<double> forecastValues;
  final Color historicalColor;
  final Color forecastColor;

  _PredictionPainter({
    required this.historicalValues,
    required this.forecastValues,
    required this.historicalColor,
    required this.forecastColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final allValues = [...historicalValues, ...forecastValues];
    final minValue = allValues.reduce((a, b) => a < b ? a : b);
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 0.0001
        ? 1.0
        : (maxValue - minValue);

    // Total number of points along the x-axis, historical + forecast,
    // sharing one continuous scale so the forecast visually continues
    // from where the historical line ends.
    final totalPoints = historicalValues.length + forecastValues.length;
    final stepX = size.width / (totalPoints - 1);

    Offset pointAt(int globalIndex, double value) {
      final normalized = (value - minValue) / range;
      final x = stepX * globalIndex;
      final y = size.height - (normalized * size.height);
      return Offset(x, y);
    }

    // ---- Historical segment (solid line + filled area) ----
    final historicalPoints = <Offset>[
      for (int i = 0; i < historicalValues.length; i++)
        pointAt(i, historicalValues[i]),
    ];

    final historicalPath = Path()..moveTo(historicalPoints[0].dx, historicalPoints[0].dy);
    for (int i = 1; i < historicalPoints.length; i++) {
      historicalPath.lineTo(historicalPoints[i].dx, historicalPoints[i].dy);
    }

    final fillPath = Path.from(historicalPath)
      ..lineTo(historicalPoints.last.dx, size.height)
      ..lineTo(historicalPoints.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = historicalColor.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      historicalPath,
      Paint()
        ..color = historicalColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Highlight the last real (historical) point.
    canvas.drawCircle(historicalPoints.last, 3.5, Paint()..color = historicalColor);
    canvas.drawCircle(
      historicalPoints.last,
      6,
      Paint()
        ..color = historicalColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );

    // ---- Forecast segment (dashed line continuing on) ----
    if (forecastValues.isNotEmpty) {
      final forecastPoints = <Offset>[
        historicalPoints.last, // start exactly where history ends
        for (int i = 0; i < forecastValues.length; i++)
          pointAt(historicalValues.length + i, forecastValues[i]),
      ];

      final dashPaint = Paint()
        ..color = forecastColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < forecastPoints.length - 1; i++) {
        _drawDashedLine(canvas, forecastPoints[i], forecastPoints[i + 1], dashPaint);
      }

      // Hollow dots for each forecasted point (skip the shared start point).
      for (int i = 1; i < forecastPoints.length; i++) {
        canvas.drawCircle(
          forecastPoints[i],
          3.5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          forecastPoints[i],
          3.5,
          Paint()
            ..color = forecastColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 5.0;
    const gapLength = 4.0;

    final totalDistance = (end - start).distance;
    if (totalDistance == 0) return;

    final direction = (end - start) / totalDistance;
    double covered = 0;

    while (covered < totalDistance) {
      final segmentEnd = (covered + dashLength).clamp(0, totalDistance);
      final from = start + direction * covered;
      final to = start + direction * segmentEnd.toDouble();
      canvas.drawLine(from, to, paint);
      covered += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _PredictionPainter oldDelegate) {
    return oldDelegate.historicalValues != historicalValues ||
        oldDelegate.forecastValues != forecastValues ||
        oldDelegate.historicalColor != historicalColor ||
        oldDelegate.forecastColor != forecastColor;
  }
}
