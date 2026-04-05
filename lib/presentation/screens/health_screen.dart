import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/providers/analytics_provider.dart';
import '../../domain/providers/websocket_provider.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health & Alerts'),
      ),
      body: Consumer2<AnalyticsProvider, WebSocketProvider>(
        builder: (context, analytics, ws, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HealthGauge(
                status: analytics.currentHealthStatus,
                riskScore: analytics.currentRiskScore,
              ),
              const SizedBox(height: 16),
              _SystemMetricsCard(analytics: analytics, ws: ws),
              const SizedBox(height: 16),
              _ActiveAlertsCard(analytics: analytics),
              const SizedBox(height: 16),
              _PredictiveAlertsCard(analytics: analytics),
            ],
          );
        },
      ),
    );
  }
}

class _HealthGauge extends StatelessWidget {
  final String status;
  final double riskScore;
  const _HealthGauge({required this.status, required this.riskScore});

  @override
  Widget build(BuildContext context) {
    final (color, icon, message) = switch (status) {
      'CRITICAL' => (
          AppColors.statusCritical,
          Icons.dangerous_rounded,
          'Critical: Immediate attention required!'
        ),
      'WARNING' => (
          AppColors.statusWarning,
          Icons.warning_amber_rounded,
          'Warning: Monitor closely'
        ),
      _ => (
          AppColors.statusNormal,
          Icons.check_circle_rounded,
          'System operating normally'
        ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, color: color, size: 50),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Risk Score', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      '${(riskScore * 100).toStringAsFixed(1)}%',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: riskScore,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemMetricsCard extends StatelessWidget {
  final AnalyticsProvider analytics;
  final WebSocketProvider ws;
  const _SystemMetricsCard({required this.analytics, required this.ws});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.monitor_heart_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('System Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _MetricRow(
              label: 'Connection Status',
              value: ws.status.name.toUpperCase(),
              color: ws.isConnected ? AppColors.statusNormal : AppColors.statusCritical,
            ),
            _MetricRow(
              label: 'Data Points',
              value: analytics.totalDataPoints.toString(),
              color: AppColors.primary,
            ),
            _MetricRow(
              label: 'Message Rate',
              value: '${ws.messagesPerSecond.toStringAsFixed(1)} msg/s',
              color: AppColors.accent,
            ),
            _MetricRow(
              label: 'Current Trend',
              value: analytics.currentTrend.toUpperCase(),
              color: analytics.currentTrend == 'stable'
                  ? AppColors.statusNormal
                  : AppColors.statusWarning,
            ),
            _MetricRow(
              label: 'Active Predictions',
              value: analytics.predictions.length.toString(),
              color: AppColors.primaryLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveAlertsCard extends StatelessWidget {
  final AnalyticsProvider analytics;
  const _ActiveAlertsCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final report = analytics.latestReport;
    final anomalies = report?.anomalies ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: AppColors.statusWarning),
                const SizedBox(width: 8),
                const Text('Active Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (anomalies.isNotEmpty)
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.statusCritical,
                    child: Text(
                      anomalies.length.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (anomalies.isEmpty)
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.statusNormal, size: 18),
                  SizedBox(width: 8),
                  Text('No active alerts', style: TextStyle(color: AppColors.statusNormal)),
                ],
              )
            else
              ...anomalies.take(5).map((a) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.statusCritical.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.statusCritical.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.statusCritical, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(a, style: const TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _PredictiveAlertsCard extends StatelessWidget {
  final AnalyticsProvider analytics;
  const _PredictiveAlertsCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final predictions = analytics.predictions;
    final warnings = predictions.where((p) => p.healthStatus != 'NORMAL').toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule_send_rounded, color: AppColors.accent),
                SizedBox(width: 8),
                Text('Predictive Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (warnings.isEmpty)
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.statusNormal, size: 18),
                  SizedBox(width: 8),
                  Text('No predicted alerts', style: TextStyle(color: AppColors.statusNormal)),
                ],
              )
            else
              ...warnings.map((p) {
                final color = p.healthStatus == 'CRITICAL'
                    ? AppColors.statusCritical
                    : AppColors.statusWarning;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: color, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${p.period == 'next_month' ? 'Next Month' : 'Next Year'}: ${p.healthStatus}',
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Predicted: ${p.predictedValue.toStringAsFixed(2)} | Risk: ${(p.riskScore * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
