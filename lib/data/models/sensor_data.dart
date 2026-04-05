import 'dart:convert';

class SensorData {
  final String id;
  final DateTime timestamp;
  final double value;
  final String metric;
  final Map<String, dynamic> rawData;

  SensorData({
    required this.id,
    required this.timestamp,
    required this.value,
    required this.metric,
    required this.rawData,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    double parsedValue = 0.0;
    if (json['value'] != null) {
      parsedValue = (json['value'] as num).toDouble();
    } else if (json['data'] != null && json['data'] is num) {
      parsedValue = (json['data'] as num).toDouble();
    }
    return SensorData(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      value: parsedValue,
      metric: json['metric']?.toString() ?? 'sensor',
      rawData: json,
    );
  }

  factory SensorData.fromRaw(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SensorData.fromJson(json);
    } catch (_) {
      return SensorData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        value: 0.0,
        metric: 'raw',
        rawData: {'raw': raw},
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'value': value,
      'metric': metric,
      'raw_data': jsonEncode(rawData),
    };
  }

  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      value: (map['value'] as num).toDouble(),
      metric: map['metric'] as String,
      rawData: jsonDecode(map['raw_data'] as String) as Map<String, dynamic>,
    );
  }
}
