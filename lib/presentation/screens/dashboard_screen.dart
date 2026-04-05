import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/providers/websocket_provider.dart';
import '../../domain/providers/analytics_provider.dart';
import '../../domain/providers/settings_provider.dart';
import '../../data/websocket/websocket_service.dart';
import '../../data/models/prediction.dart';
import '../widgets/status_card.dart';
import '../widgets/health_indicator.dart';
import '../widgets/mini_chart.dart';
import 'realtime_screen.dart';
import 'historical_screen.dart';
import 'analytics_screen.dart';
import 'health_screen.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    _DashboardHome(),
    RealtimeScreen(),
    HistoricalScreen(),
    AnalyticsScreen(),
    HealthScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoConnect());
  }

  void _autoConnect() {
    final settings = context.read<SettingsProvider>();
    final ws = context.read<WebSocketProvider>();
    if (settings.autoConnect && ws.status == ConnectionStatus.disconnected) {
      ws.connect(settings.wsUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.wifi_rounded), label: 'Live'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: 'History'),
          NavigationDestination(icon: Icon(Icons.psychology_rounded), label: 'AI'),
          NavigationDestination(icon: Icon(Icons.health_and_safety_rounded), label: 'Health'),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer2<WebSocketProvider, AnalyticsProvider>(
        builder: (context, ws, analytics, _) {
          return RefreshIndicator(
            onRefresh: analytics.refreshData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ConnectionBanner(ws: ws),
                const SizedBox(height: 16),
                _StatsRow(ws: ws, analytics: analytics),
                const SizedBox(height: 16),
                HealthIndicatorCard(
                  status: analytics.currentHealthStatus,
                  riskScore: analytics.currentRiskScore,
                  trend: analytics.currentTrend,
                ),
                const SizedBox(height: 16),
                _LiveDataCard(ws: ws),
                const SizedBox(height: 16),
                _PredictionSummaryCard(analytics: analytics),
                const SizedBox(height: 16),
                _QuickActionsCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  final WebSocketProvider ws;
  const _ConnectionBanner({required this.ws});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (ws.status) {
      ConnectionStatus.connected => (AppColors.statusNormal, Icons.wifi_rounded, 'Connected'),
      ConnectionStatus.connecting => (AppColors.statusWarning, Icons.wifi_tethering_rounded, 'Connecting...'),
      ConnectionStatus.reconnecting => (AppColors.statusWarning, Icons.wifi_tethering_error_rounded, 'Reconnecting...'),
      ConnectionStatus.error => (AppColors.statusCritical, Icons.wifi_off_rounded, 'Connection Error'),
      _ => (Colors.grey, Icons.wifi_off_rounded, 'Disconnected'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (ws.isConnected) ...[
            Text(
              '${ws.messagesPerSecond.toStringAsFixed(1)} msg/s',
              style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
            ),
          ],
          const SizedBox(width: 8),
          _ConnectButton(ws: ws),
        ],
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  final WebSocketProvider ws;
  const _ConnectButton({required this.ws});

  @override
  Widget build(BuildContext context) {
    if (ws.isConnected) {
      return TextButton(
        onPressed: ws.disconnect,
        child: const Text('Disconnect', style: TextStyle(color: AppColors.statusCritical)),
      );
    }
    return TextButton(
      onPressed: () {
        final settings = context.read<SettingsProvider>();
        ws.connect(settings.wsUrl);
      },
      child: const Text('Connect', style: TextStyle(color: AppColors.primary)),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final WebSocketProvider ws;
  final AnalyticsProvider analytics;
  const _StatsRow({required this.ws, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatusCard(
            title: 'Total Data',
            value: analytics.totalDataPoints.toString(),
            icon: Icons.storage_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatusCard(
            title: 'Messages',
            value: ws.messageCount.toString(),
            icon: Icons.message_rounded,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatusCard(
            title: 'Predictions',
            value: analytics.predictions.length.toString(),
            icon: Icons.psychology_rounded,
            color: AppColors.primaryLight,
          ),
        ),
      ],
    );
  }
}

class _LiveDataCard extends StatelessWidget {
  final WebSocketProvider ws;
  const _LiveDataCard({required this.ws});

  @override
  Widget build(BuildContext context) {
    final latest = ws.latestData;
    final values = ws.recentData.take(30).map((d) => d.value).toList().reversed.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sensors_rounded, color: AppColors.accent),
                const SizedBox(width: 8),
                const Text('Live Data Stream',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (ws.isConnected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.statusNormal,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (latest != null) ...[
              Text(
                latest.value.toStringAsFixed(4),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              Text(
                'Metric: ${latest.metric} | ${latest.timestamp}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ] else
              Text('No data yet', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 12),
            if (values.isNotEmpty) MiniChart(values: values),
          ],
        ),
      ),
    );
  }
}

class _PredictionSummaryCard extends StatelessWidget {
  final AnalyticsProvider analytics;
  const _PredictionSummaryCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final predictions = analytics.predictions;
    if (predictions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.psychology_rounded, size: 40, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'Collecting data for AI predictions...',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('AI Predictions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...predictions.map((p) => _PredictionTile(prediction: p)),
          ],
        ),
      ),
    );
  }
}

class _PredictionTile extends StatelessWidget {
  final Prediction prediction;
  const _PredictionTile({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final color = switch (prediction.healthStatus) {
      'CRITICAL' => AppColors.statusCritical,
      'WARNING' => AppColors.statusWarning,
      _ => AppColors.statusNormal,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            prediction.period == 'next_month' ? Icons.calendar_month_rounded : Icons.calendar_today_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prediction.period == 'next_month' ? 'Next Month' : 'Next Year',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  'Predicted: ${prediction.predictedValue.toStringAsFixed(2)} | ${(prediction.confidence * 100).toStringAsFixed(0)}% confidence',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              prediction.healthStatus,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionChip(
                  label: 'View Live',
                  icon: Icons.wifi_rounded,
                  onTap: () {},
                ),
                _ActionChip(
                  label: 'Reports',
                  icon: Icons.file_download_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  ),
                ),
                _ActionChip(
                  label: 'Settings',
                  icon: Icons.settings_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
