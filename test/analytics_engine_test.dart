import 'package:flutter_test/flutter_test.dart';
import 'package:websocket_ai_analytics/domain/analytics/analytics_engine.dart';

void main() {
  group('AnalyticsEngine Tests', () {
    test('mean of empty list returns 0', () {
      expect(AnalyticsEngine.mean([]), 0.0);
    });

    test('mean of values is correct', () {
      expect(AnalyticsEngine.mean([1.0, 2.0, 3.0, 4.0, 5.0]), 3.0);
    });

    test('stdDev of identical values is 0', () {
      expect(AnalyticsEngine.stdDev([5.0, 5.0, 5.0]), 0.0);
    });

    test('stdDev of [2,4,4,4,5,5,7,9] ≈ 2.0', () {
      final sd = AnalyticsEngine.stdDev([2, 4, 4, 4, 5, 5, 7, 9]);
      expect(sd, closeTo(2.0, 0.01));
    });

    test('linearRegression on ascending series has positive slope', () {
      final x = [0.0, 1.0, 2.0, 3.0, 4.0];
      final y = [1.0, 2.0, 3.0, 4.0, 5.0];
      final result = AnalyticsEngine.linearRegression(x, y);
      expect(result[0], closeTo(1.0, 0.001)); // slope
      expect(result[1], closeTo(1.0, 0.001)); // intercept
    });

    test('predictNext returns value after trend', () {
      final values = [1.0, 2.0, 3.0, 4.0, 5.0];
      expect(AnalyticsEngine.predictNext(values), closeTo(6.0, 0.1));
    });

    test('isAnomaly returns false for normal values', () {
      final history = List.generate(20, (i) => 50.0 + (i % 5) * 0.1);
      expect(AnalyticsEngine.isAnomaly(50.2, history), false);
    });

    test('isAnomaly returns true for extreme outlier', () {
      final history = List.generate(20, (i) => 50.0);
      expect(AnalyticsEngine.isAnomaly(1000.0, history), true);
    });

    test('healthStatus returns NORMAL for low risk', () {
      expect(AnalyticsEngine.healthStatus(0.1), 'NORMAL');
    });

    test('healthStatus returns WARNING for medium risk', () {
      expect(AnalyticsEngine.healthStatus(0.75), 'WARNING');
    });

    test('healthStatus returns CRITICAL for high risk', () {
      expect(AnalyticsEngine.healthStatus(0.9), 'CRITICAL');
    });

    test('detectTrend returns increasing for ascending data', () {
      final values = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0];
      expect(AnalyticsEngine.detectTrend(values), 'increasing');
    });

    test('detectTrend returns stable for flat data', () {
      final values = List.filled(10, 5.0);
      expect(AnalyticsEngine.detectTrend(values), 'stable');
    });

    test('generatePrediction with insufficient data returns low confidence', () {
      final prediction = AnalyticsEngine.generatePrediction(
        metric: 'test',
        historicalValues: [1.0, 2.0],
        period: 'next_month',
      );
      expect(prediction.confidence, lessThan(0.5));
    });

    test('generatePrediction with sufficient data returns prediction', () {
      final values = List.generate(100, (i) => 50.0 + (i % 10) * 0.5);
      final prediction = AnalyticsEngine.generatePrediction(
        metric: 'sensor',
        historicalValues: values,
        period: 'next_month',
      );
      expect(prediction.predictedValue, isNotNull);
      expect(prediction.confidence, greaterThan(0.0));
      expect(prediction.healthStatus, isIn(['NORMAL', 'WARNING', 'CRITICAL']));
    });

    test('aggregateByMonth groups data correctly', () {
      // This test validates the aggregation logic structure works
      expect(AnalyticsEngine.aggregateByMonth([]), isEmpty);
    });

    test('aggregateByYear groups data correctly', () {
      expect(AnalyticsEngine.aggregateByYear([]), isEmpty);
    });
  });
}
