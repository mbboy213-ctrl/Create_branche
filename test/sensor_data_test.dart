import 'package:flutter_test/flutter_test.dart';
import 'package:websocket_ai_analytics/data/models/sensor_data.dart';

void main() {
  group('SensorData Model Tests', () {
    test('fromJson parses valid JSON', () {
      final json = {
        'id': 'test-1',
        'timestamp': '2024-01-01T12:00:00.000',
        'value': 42.5,
        'metric': 'temperature',
      };
      final data = SensorData.fromJson(json);
      expect(data.id, 'test-1');
      expect(data.value, 42.5);
      expect(data.metric, 'temperature');
    });

    test('fromJson handles missing value gracefully', () {
      final json = {'id': 'test-2', 'metric': 'pressure'};
      final data = SensorData.fromJson(json);
      expect(data.value, 0.0);
    });

    test('fromRaw handles valid JSON string', () {
      const raw = '{"id":"r1","value":10.0,"metric":"speed"}';
      final data = SensorData.fromRaw(raw);
      expect(data.value, 10.0);
    });

    test('fromRaw handles invalid JSON string gracefully', () {
      const raw = 'not valid json';
      final data = SensorData.fromRaw(raw);
      expect(data.metric, 'raw');
    });

    test('toMap and fromMap roundtrip', () {
      final original = SensorData(
        id: 'abc',
        timestamp: DateTime(2024, 6, 15, 10, 30, 0),
        value: 99.99,
        metric: 'voltage',
        rawData: {'key': 'val'},
      );
      final map = original.toMap();
      final restored = SensorData.fromMap(map);
      expect(restored.id, original.id);
      expect(restored.value, original.value);
      expect(restored.metric, original.metric);
    });
  });
}
