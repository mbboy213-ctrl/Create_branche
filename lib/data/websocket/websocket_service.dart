import 'dart:async';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/constants/app_constants.dart';
import '../models/sensor_data.dart';
import '../database/database_helper.dart';

enum ConnectionStatus { disconnected, connecting, connected, reconnecting, error }

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<SensorData> _dataController = StreamController.broadcast();
  StreamController<ConnectionStatus> _statusController = StreamController.broadcast();
  StreamController<String> _rawController = StreamController.broadcast();

  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  bool _shouldReconnect = true;
  String _url = AppConstants.defaultWebSocketUrl;
  ConnectionStatus _status = ConnectionStatus.disconnected;

  final DatabaseHelper _db = DatabaseHelper();

  Stream<SensorData> get dataStream => _dataController.stream;
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  Stream<String> get rawStream => _rawController.stream;
  ConnectionStatus get status => _status;
  String get url => _url;

  void _setStatus(ConnectionStatus s) {
    _status = s;
    _statusController.add(s);
  }

  Future<void> connect(String url) async {
    _url = url;
    _shouldReconnect = true;
    _reconnectAttempts = 0;
    await _connect();
  }

  Future<void> _connect() async {
    _setStatus(ConnectionStatus.connecting);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));
      await _channel!.ready;
      _setStatus(ConnectionStatus.connected);
      _reconnectAttempts = 0;
      _startPingTimer();

      _channel!.stream.listen(
        (message) {
          final raw = message.toString();
          _rawController.add(raw);
          final data = SensorData.fromRaw(raw);
          _dataController.add(data);
          _db.insertSensorData(data);
        },
        onError: (error) {
          _setStatus(ConnectionStatus.error);
          _scheduleReconnect();
        },
        onDone: () {
          if (_shouldReconnect) {
            _setStatus(ConnectionStatus.reconnecting);
            _scheduleReconnect();
          } else {
            _setStatus(ConnectionStatus.disconnected);
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      _setStatus(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(
      Duration(seconds: AppConstants.pingIntervalSeconds),
      (_) => sendMessage('ping'),
    );
  }

  void _scheduleReconnect() {
    _pingTimer?.cancel();
    if (!_shouldReconnect) return;
    if (_reconnectAttempts >= AppConstants.reconnectMaxAttempts) {
      _setStatus(ConnectionStatus.error);
      return;
    }
    final delay = min(
      AppConstants.reconnectInitialDelayMs * pow(2, _reconnectAttempts).toInt(),
      AppConstants.reconnectMaxDelayMs,
    );
    _reconnectAttempts++;
    _reconnectTimer = Timer(Duration(milliseconds: delay), _connect);
  }

  void sendMessage(String message) {
    if (_status == ConnectionStatus.connected) {
      try {
        _channel?.sink.add(message);
      } catch (_) {}
    }
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _setStatus(ConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _dataController.close();
    _statusController.close();
    _rawController.close();
  }
}
