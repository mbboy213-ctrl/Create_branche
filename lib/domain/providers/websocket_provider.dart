import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/websocket/websocket_service.dart';
import '../../data/models/sensor_data.dart';

class WebSocketProvider extends ChangeNotifier {
  final WebSocketService _service = WebSocketService();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  final List<SensorData> _recentData = [];
  final List<String> _rawMessages = [];
  String _connectedUrl = '';
  int _messageCount = 0;
  DateTime? _lastMessageTime;
  double _messagesPerSecond = 0.0;
  Timer? _mpsTimer;
  int _mpsCounter = 0;

  StreamSubscription? _dataSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _rawSub;

  static const int maxRecentData = 200;
  static const int maxRawMessages = 100;

  ConnectionStatus get status => _status;
  List<SensorData> get recentData => List.unmodifiable(_recentData);
  List<String> get rawMessages => List.unmodifiable(_rawMessages);
  String get connectedUrl => _connectedUrl;
  int get messageCount => _messageCount;
  DateTime? get lastMessageTime => _lastMessageTime;
  double get messagesPerSecond => _messagesPerSecond;
  bool get isConnected => _status == ConnectionStatus.connected;

  WebSocketProvider() {
    _statusSub = _service.statusStream.listen((s) {
      _status = s;
      notifyListeners();
    });

    _dataSub = _service.dataStream.listen((data) {
      _recentData.insert(0, data);
      if (_recentData.length > maxRecentData) _recentData.removeLast();
      _messageCount++;
      _mpsCounter++;
      _lastMessageTime = DateTime.now();
      notifyListeners();
    });

    _rawSub = _service.rawStream.listen((raw) {
      _rawMessages.insert(0, raw);
      if (_rawMessages.length > maxRawMessages) _rawMessages.removeLast();
    });

    _mpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _messagesPerSecond = _mpsCounter.toDouble();
      _mpsCounter = 0;
      if (_messagesPerSecond > 0) notifyListeners();
    });
  }

  Future<void> connect(String url) async {
    _connectedUrl = url;
    await _service.connect(url);
  }

  void disconnect() {
    _service.disconnect();
  }

  void sendMessage(String msg) {
    _service.sendMessage(msg);
  }

  void clearData() {
    _recentData.clear();
    _rawMessages.clear();
    _messageCount = 0;
    notifyListeners();
  }

  SensorData? get latestData => _recentData.isNotEmpty ? _recentData.first : null;

  @override
  void dispose() {
    _dataSub?.cancel();
    _statusSub?.cancel();
    _rawSub?.cancel();
    _mpsTimer?.cancel();
    _service.dispose();
    super.dispose();
  }
}
