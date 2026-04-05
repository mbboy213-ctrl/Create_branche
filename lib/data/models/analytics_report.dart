class AnalyticsReport {
  final String id;
  final DateTime generatedAt;
  final String reportType; // 'monthly' | 'yearly' | 'realtime'
  final double averageValue;
  final double maxValue;
  final double minValue;
  final double stdDeviation;
  final int dataPointCount;
  final String healthStatus;
  final double riskScore;
  final List<String> anomalies;
  final Map<String, double> monthlyAverages;
  final Map<String, double> yearlyAverages;

  AnalyticsReport({
    required this.id,
    required this.generatedAt,
    required this.reportType,
    required this.averageValue,
    required this.maxValue,
    required this.minValue,
    required this.stdDeviation,
    required this.dataPointCount,
    required this.healthStatus,
    required this.riskScore,
    required this.anomalies,
    required this.monthlyAverages,
    required this.yearlyAverages,
  });
}
