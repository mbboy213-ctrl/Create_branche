import 'dart:math' as math;
import '../../data/models/sensor_data.dart';
import '../../data/models/prediction.dart';
import '../../core/constants/app_constants.dart';

class AnalyticsEngine {
  // Compute mean of a value list
  static double mean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  // Compute standard deviation
  static double stdDev(List<double> values) {
    if (values.length < 2) return 0.0;
    final m = mean(values);
    final variance = values.map((v) => math.pow(v - m, 2)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }

  // Linear regression: returns [slope, intercept]
  static List<double> linearRegression(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 2) return [0.0, mean(y)];
    final n = x.length.toDouble();
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(x.length, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((v) => v * v).reduce((a, b) => a + b);
    final denom = (n * sumX2 - sumX * sumX);
    if (denom == 0) return [0.0, mean(y)];
    final slope = (n * sumXY - sumX * sumY) / denom;
    final intercept = (sumY - slope * sumX) / n;
    return [slope, intercept];
  }

  // Predict next value using linear regression
  static double predictNext(List<double> values) {
    if (values.isEmpty) return 0.0;
    final x = List.generate(values.length, (i) => i.toDouble());
    final reg = linearRegression(x, values);
    return reg[0] * values.length + reg[1];
  }

  // Detect anomaly using Z-score
  static bool isAnomaly(double value, List<double> history) {
    if (history.length < 5) return false;
    final m = mean(history);
    final sd = stdDev(history);
    if (sd == 0) return false;
    final z = (value - m).abs() / sd;
    return z > AppConstants.anomalyThresholdZ;
  }

  // Compute Z-score
  static double zScore(double value, List<double> history) {
    if (history.length < 2) return 0.0;
    final m = mean(history);
    final sd = stdDev(history);
    if (sd == 0) return 0.0;
    return (value - m).abs() / sd;
  }

  // Compute risk score [0.0, 1.0]
  static double riskScore(double value, List<double> history) {
    if (history.isEmpty) return 0.0;
    final z = zScore(value, history);
    return math.min(z / (AppConstants.anomalyThresholdZ * 2), 1.0);
  }

  // Determine health status from risk score
  static String healthStatus(double risk) {
    if (risk >= AppConstants.criticalThreshold) return AppConstants.statusCritical;
    if (risk >= AppConstants.warningThreshold) return AppConstants.statusWarning;
    return AppConstants.statusNormal;
  }

  // Generate prediction for a given period
  static Prediction generatePrediction({
    required String metric,
    required List<double> historicalValues,
    required String period, // 'next_month' | 'next_year'
    double? currentValue,
  }) {
    if (historicalValues.length < 3) {
      return Prediction(
        metric: metric,
        predictedValue: historicalValues.isNotEmpty ? mean(historicalValues) : 0.0,
        confidence: 0.1,
        period: period,
        healthStatus: AppConstants.statusNormal,
        riskScore: 0.0,
        isAnomaly: false,
        reasoning: 'Insufficient data for prediction',
        generatedAt: DateTime.now(),
      );
    }

    final predicted = predictNext(historicalValues);
    final m = mean(historicalValues);
    final sd = stdDev(historicalValues);
    final risk = currentValue != null ? riskScore(currentValue, historicalValues) : riskScore(predicted, historicalValues);
    final status = healthStatus(risk);
    final anomaly = currentValue != null ? isAnomaly(currentValue, historicalValues) : isAnomaly(predicted, historicalValues);

    // Confidence based on data volume and variance
    final coeffVariation = m != 0 ? sd / m.abs() : 1.0;
    final dataFactor = math.min(historicalValues.length / 100.0, 1.0);
    final confidence = math.max(0.1, dataFactor * (1.0 - math.min(coeffVariation, 1.0)));

    final reasoning = _buildReasoning(metric, predicted, m, sd, risk, status, anomaly, period);

    return Prediction(
      metric: metric,
      predictedValue: predicted,
      confidence: confidence,
      period: period,
      healthStatus: status,
      riskScore: risk,
      isAnomaly: anomaly,
      reasoning: reasoning,
      generatedAt: DateTime.now(),
    );
  }

  static String _buildReasoning(
    String metric,
    double predicted,
    double mean,
    double sd,
    double risk,
    String status,
    bool anomaly,
    String period,
  ) {
    final buf = StringBuffer();
    buf.write('Metric: $metric | ');
    buf.write('Predicted: ${predicted.toStringAsFixed(2)} | ');
    buf.write('Historical mean: ${mean.toStringAsFixed(2)} ± ${sd.toStringAsFixed(2)} | ');
    buf.write('Risk: ${(risk * 100).toStringAsFixed(1)}% | ');
    buf.write('Status: $status | ');
    if (anomaly) buf.write('⚠️ Anomaly detected | ');
    buf.write('Period: $period');
    return buf.toString();
  }

  // Aggregate data by month for chart
  static Map<String, double> aggregateByMonth(List<SensorData> data) {
    final Map<String, List<double>> grouped = {};
    for (final d in data) {
      final key = '${d.timestamp.year}-${d.timestamp.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(d.value);
    }
    return grouped.map((k, v) => MapEntry(k, mean(v)));
  }

  // Aggregate data by year for chart
  static Map<String, double> aggregateByYear(List<SensorData> data) {
    final Map<String, List<double>> grouped = {};
    for (final d in data) {
      final key = d.timestamp.year.toString();
      grouped.putIfAbsent(key, () => []).add(d.value);
    }
    return grouped.map((k, v) => MapEntry(k, mean(v)));
  }

  // Detect trend: positive, negative, or stable
  static String detectTrend(List<double> values) {
    if (values.length < 3) return 'stable';
    final x = List.generate(values.length, (i) => i.toDouble());
    final reg = linearRegression(x, values);
    final slope = reg[0];
    final threshold = stdDev(values) * 0.05;
    if (slope > threshold) return 'increasing';
    if (slope < -threshold) return 'decreasing';
    return 'stable';
  }
}
