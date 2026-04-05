class AppConstants {
  // WebSocket
  static const String defaultWebSocketUrl = 'wss://echo.websocket.org';
  static const int reconnectInitialDelayMs = 1000;
  static const int reconnectMaxDelayMs = 30000;
  static const int reconnectMaxAttempts = 10;
  static const int pingIntervalSeconds = 30;

  // Database
  static const String dbName = 'ai_analytics.db';
  static const int dbVersion = 1;
  static const String tableData = 'sensor_data';
  static const String tableModels = 'ml_models';

  // Analytics
  static const int minDataPointsForTraining = 50;
  static const int predictionWindowDays = 30;
  static const double anomalyThresholdZ = 2.5;
  static const double warningThreshold = 0.7;
  static const double criticalThreshold = 0.85;

  // UI
  static const double borderRadius = 16.0;
  static const double cardPadding = 16.0;
  static const int chartAnimationDurationMs = 800;

  // Health Status Labels
  static const String statusNormal = 'NORMAL';
  static const String statusWarning = 'WARNING';
  static const String statusCritical = 'CRITICAL';

  // Export
  static const String csvExportPrefix = 'analytics_export';
  static const String pdfExportPrefix = 'analytics_report';
}
