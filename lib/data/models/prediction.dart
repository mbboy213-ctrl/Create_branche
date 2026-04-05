class Prediction {
  final String metric;
  final double predictedValue;
  final double confidence;
  final String period; // 'next_month' | 'next_year'
  final String healthStatus; // 'NORMAL' | 'WARNING' | 'CRITICAL'
  final double riskScore;
  final bool isAnomaly;
  final String reasoning;
  final DateTime generatedAt;

  Prediction({
    required this.metric,
    required this.predictedValue,
    required this.confidence,
    required this.period,
    required this.healthStatus,
    required this.riskScore,
    required this.isAnomaly,
    required this.reasoning,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'metric': metric,
      'predicted_value': predictedValue,
      'confidence': confidence,
      'period': period,
      'health_status': healthStatus,
      'risk_score': riskScore,
      'is_anomaly': isAnomaly ? 1 : 0,
      'reasoning': reasoning,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  factory Prediction.fromMap(Map<String, dynamic> map) {
    return Prediction(
      metric: map['metric'] as String,
      predictedValue: (map['predicted_value'] as num).toDouble(),
      confidence: (map['confidence'] as num).toDouble(),
      period: map['period'] as String,
      healthStatus: map['health_status'] as String,
      riskScore: (map['risk_score'] as num).toDouble(),
      isAnomaly: (map['is_anomaly'] as int) == 1,
      reasoning: map['reasoning'] as String,
      generatedAt: DateTime.parse(map['generated_at'] as String),
    );
  }
}
