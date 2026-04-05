# 📱 WebSocket AI Analytics — Flutter Mobile App

A professional, production-ready Flutter mobile application for **iOS and Android** featuring real-time WebSocket data streaming, AI/ML predictive analytics, historical data storage, and comprehensive dashboards.

---

## 🚀 Features

### 1. WebSocket Real-Time Data Integration
- Connect to any WebSocket API for continuous live data streaming
- Auto-reconnection with **exponential backoff** strategy
- Real-time connection status monitoring and indicators
- Robust error handling and graceful recovery

### 2. Data Storage & Historical Tracking
- Local **SQLite** database (via `sqflite`) for persistent data storage
- Save all incoming WebSocket data with precise timestamps
- Accumulate historical data across months and years
- Advanced comparisons: **month-to-month**, **year-to-year**
- Intelligent data management and configurable retention

### 3. AI/ML Predictive Analytics Engine
- **Linear regression** for trend-based forecasting
- Real-time anomaly detection using **Z-score analysis**
- Predictive forecasting for **next month** and **next year**
- Trend analysis (increasing / decreasing / stable)
- Confidence scoring for all predictions
- Risk assessment and health scoring system

### 4. Intelligent Decision Making System
- Compare real-time data with historical patterns
- Predict future system health: **Normal / Warning / Critical**
- Automatic damage/anomaly detection
- Generate predictive alerts and notifications
- Configurable thresholds

### 5. Professional Enterprise UI/UX
- **Material Design 3** with custom enterprise color palette
- Dark/Light/System theme support
- Smooth animations (splash, transitions, indicators)
- Modern glassmorphism and gradient effects

### 6. Comprehensive Analytics Dashboard
- Real-time data visualization with **live updating charts** (`fl_chart`)
- Historical data comparison (monthly and yearly bar charts)
- Predictive forecast displays with confidence indicators
- Health status visualization (Green/Yellow/Red)
- AI decision reports and risk assessments

### 7. Export Functionality
- **PDF report** generation with analytics summary
- **CSV export** for all historical sensor data
- Share via system share sheet

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── constants/
│   │   ├── app_constants.dart         # App-wide constants
│   │   └── app_colors.dart            # Color palette
│   └── utils/
│       └── date_utils.dart            # Date formatting utilities
├── data/
│   ├── models/
│   │   ├── sensor_data.dart           # Data model
│   │   ├── prediction.dart            # Prediction model
│   │   └── analytics_report.dart      # Report model
│   ├── database/
│   │   └── database_helper.dart       # SQLite database helper
│   └── websocket/
│       └── websocket_service.dart     # WebSocket service with reconnect
├── domain/
│   ├── analytics/
│   │   └── analytics_engine.dart      # AI/ML analytics engine
│   └── providers/
│       ├── websocket_provider.dart    # WebSocket state management
│       ├── analytics_provider.dart    # Analytics state management
│       └── settings_provider.dart    # Settings state management
└── presentation/
    ├── screens/
    │   ├── splash_screen.dart         # Animated splash screen
    │   ├── dashboard_screen.dart      # Main dashboard
    │   ├── realtime_screen.dart       # Live data stream
    │   ├── historical_screen.dart     # Historical analysis
    │   ├── analytics_screen.dart      # AI analytics & predictions
    │   ├── health_screen.dart         # Health & alerts
    │   ├── settings_screen.dart       # App settings
    │   └── reports_screen.dart        # Export & reports
    └── widgets/
        ├── status_card.dart           # Metric status card
        ├── health_indicator.dart      # Health indicator widget
        └── mini_chart.dart            # Mini sparkline chart
```

---

## 🛠 Tech Stack

| Category | Package |
|----------|---------|
| Framework | Flutter (Dart) |
| State Management | `provider ^6.1.1` |
| WebSocket | `web_socket_channel ^2.4.0` |
| Database | `sqflite ^2.3.0` |
| Charts | `fl_chart ^0.66.2` |
| PDF Export | `pdf ^3.10.8` |
| CSV Export | `csv ^6.0.0` |
| Share | `share_plus ^7.2.2` |
| Preferences | `shared_preferences ^2.2.2` |
| Utilities | `uuid`, `intl`, `path_provider` |

---

## ⚙️ Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.10.0
- Dart ≥ 3.0.0
- Android Studio / Xcode

### Installation

```bash
# Clone the repository
git clone https://github.com/mbboy213-ctrl/Create_branche.git
cd Create_branche

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run

# Build release APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

### Configuration

In the **Settings** screen (or `lib/domain/providers/settings_provider.dart`), configure:

- `wsUrl` — Your WebSocket server URL (default: `wss://echo.websocket.org` for testing)
- `dataRetentionDays` — How long to keep historical data (30–730 days)
- `autoConnect` — Auto-connect on app launch
- Theme mode (Light / Dark / System)

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/analytics_engine_test.dart
flutter test test/sensor_data_test.dart
```

Tests cover:
- `AnalyticsEngine`: mean, std deviation, linear regression, anomaly detection, health status, predictions
- `SensorData`: JSON parsing, roundtrip serialization, error handling

---

## 📊 Analytics Algorithm

The AI engine uses pure Dart (no external ML dependency required):

1. **Data Collection** — All WebSocket messages are stored in SQLite with timestamps
2. **Baseline Computation** — Historical mean and standard deviation computed over all data
3. **Anomaly Detection** — Z-score threshold of 2.5σ flags anomalies
4. **Linear Regression** — Least squares fit on time-indexed values to forecast future values
5. **Confidence Scoring** — Based on data volume and coefficient of variation
6. **Risk Assessment** — Normalized risk score [0, 1] mapped to NORMAL/WARNING/CRITICAL

---

## 📱 Screenshots

| Screen | Description |
|--------|-------------|
| Splash | Animated logo with gradient background |
| Dashboard | Overview with health, predictions, live data |
| Live Stream | Real-time chart or raw message view |
| Historical | Monthly/yearly bar charts with data tables |
| AI Analytics | Predictions, trend analysis, anomaly detection |
| Health | Gauge, system metrics, active alerts |
| Settings | URL config, theme, data retention |
| Reports | PDF/CSV export with summary |

---

## 🏗 Architecture

This app follows **Clean Architecture with MVVM**:

- **Data Layer** — Models, SQLite, WebSocket service
- **Domain Layer** — Analytics engine, Provider state management
- **Presentation Layer** — Screens, Widgets

State is managed via **Provider** with `ChangeNotifier`. The `AnalyticsProvider` is updated via `ChangeNotifierProxyProvider` whenever new WebSocket data arrives.

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.