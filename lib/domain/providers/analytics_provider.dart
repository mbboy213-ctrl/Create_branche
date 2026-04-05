import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/sensor_data.dart';
import '../../data/models/prediction.dart';
import '../../data/models/analytics_report.dart';
import '../analytics/analytics_engine.dart';
import '../providers/websocket_provider.dart';
import '../../core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

class AnalyticsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final _uuid = const Uuid();

  List<SensorData> _historicalData = [];
  List<Prediction> _predictions = [];
  AnalyticsReport? _latestReport;
  Map<String, double> _monthlyAverages = {};
  Map<String, double> _yearlyAverages = {};
  bool _isLoading = false;
  String _currentHealthStatus = AppConstants.statusNormal;
  double _currentRiskScore = 0.0;
  String _currentTrend = 'stable';
  int _totalDataPoints = 0;
  Timer? _refreshTimer;

  List<SensorData> get historicalData => _historicalData;
  List<Prediction> get predictions => _predictions;
  AnalyticsReport? get latestReport => _latestReport;
  Map<String, double> get monthlyAverages => _monthlyAverages;
  Map<String, double> get yearlyAverages => _yearlyAverages;
  bool get isLoading => _isLoading;
  String get currentHealthStatus => _currentHealthStatus;
  double get currentRiskScore => _currentRiskScore;
  String get currentTrend => _currentTrend;
  int get totalDataPoints => _totalDataPoints;

  AnalyticsProvider() {
    _initialize();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) => _refresh());
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();
    await _loadFromDb();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refresh() async {
    await _loadFromDb();
    _generatePredictions();
    notifyListeners();
  }

  void updateFromWebSocket(WebSocketProvider wsProvider) {
    if (wsProvider.recentData.isNotEmpty) {
      _analyzeRealtime(wsProvider.recentData);
    }
  }

  Future<void> _loadFromDb() async {
    _historicalData = await _db.getAllData(limit: 5000);
    _totalDataPoints = await _db.getDataCount();
    _monthlyAverages = await _db.getMonthlyAverages('sensor');
    _yearlyAverages = await _db.getYearlyAverages('sensor');
    _generatePredictions();
  }

  void _analyzeRealtime(List<SensorData> recentData) {
    final values = _historicalData.map((d) => d.value).toList();
    if (values.isEmpty) return;

    final current = recentData.first.value;
    _currentRiskScore = AnalyticsEngine.riskScore(current, values);
    _currentHealthStatus = AnalyticsEngine.healthStatus(_currentRiskScore);
    _currentTrend = AnalyticsEngine.detectTrend(values.take(100).toList());

    _generateReport(recentData, values);
    notifyListeners();
  }

  void _generatePredictions() {
    final values = _historicalData.map((d) => d.value).toList();
    if (values.length < 3) return;

    _predictions = [
      AnalyticsEngine.generatePrediction(
        metric: 'sensor',
        historicalValues: values,
        period: 'next_month',
      ),
      AnalyticsEngine.generatePrediction(
        metric: 'sensor',
        historicalValues: values,
        period: 'next_year',
      ),
    ];
  }

  void _generateReport(List<SensorData> recent, List<double> all) {
    if (all.isEmpty) return;
    final anomalies = recent
        .where((d) => AnalyticsEngine.isAnomaly(d.value, all))
        .map((d) => 'Value ${d.value.toStringAsFixed(2)} at ${d.timestamp}')
        .toList();

    _latestReport = AnalyticsReport(
      id: _uuid.v4(),
      generatedAt: DateTime.now(),
      reportType: 'realtime',
      averageValue: AnalyticsEngine.mean(all),
      maxValue: all.reduce((a, b) => a > b ? a : b),
      minValue: all.reduce((a, b) => a < b ? a : b),
      stdDeviation: AnalyticsEngine.stdDev(all),
      dataPointCount: all.length,
      healthStatus: _currentHealthStatus,
      riskScore: _currentRiskScore,
      anomalies: anomalies,
      monthlyAverages: _monthlyAverages,
      yearlyAverages: _yearlyAverages,
    );
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    await _loadFromDb();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _db.clearAllData();
    _historicalData.clear();
    _predictions.clear();
    _latestReport = null;
    _monthlyAverages.clear();
    _yearlyAverages.clear();
    _totalDataPoints = 0;
    notifyListeners();
  }

  List<double> getRecentValues(int count) {
    return _historicalData.take(count).map((d) => d.value).toList().reversed.toList();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
