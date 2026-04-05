import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/providers/analytics_provider.dart';
import '../../domain/providers/websocket_provider.dart';
import '../../domain/analytics/analytics_engine.dart';
import '../../data/models/prediction.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analytics Engine'),
        actions: [
          Consumer<AnalyticsProvider>(
            builder: (_, analytics, __) => IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: analytics.refreshData,
            ),
          ),
        ],
      ),
      body: Consumer2<AnalyticsProvider, WebSocketProvider>(
        builder: (context, analytics, ws, _) {
          if (analytics.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ModelStatusCard(analytics: analytics),
              const SizedBox(height: 16),
              _PredictionsCard(analytics: analytics),
              const SizedBox(height: 16),
              _TrendAnalysisCard(analytics: analytics),
              const SizedBox(height: 16),
              _AnomalyDetectionCard(analytics: analytics, ws: ws),
              const SizedBox(height: 16),
              _StatisticsCard(analytics: analytics),
            ],
          );
        },
      ),
    );
  }
}

class _ModelStatusCard extends StatelessWidget {
  final AnalyticsProvider analytics;
  const _ModelStatusCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final dataPoints = analytics.totalDataPoints;
    final hasEnough = dataPoints >= 50;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_rounded,
                  color: hasEnough ? AppColors.primary : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text('AI Model Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (hasEnough ? AppColors.statusNormal : AppColors.statusWarning).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasEnough ? 'TRAINED' : 'TRAINING',
                    style: TextStyle(
                      color: hasEnough ? AppColors.statusNormal : AppColors.statusWarning,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (dataPoints / 50.0).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                hasEnough ? AppColors.statusNormal : AppColors.statusWarning,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasEnough
                  ? '✅ Model trained on $dataPoints data points'
                  : '⏳ $dataPoints / 50 data points (need more for training)',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _PredictionsCard extends StatelessWidget {
  final AnalyticsProvider analytics;
  const _PredictionsCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final predictions = analytics.predictions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up_rounded, color: AppColors.accent),
                SizedBox(width: 8),
                Text('Predictive Forecasting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (predictions.isEmpty)
              const Text(
                'Not enough historical data for predictions.\nNeed at least 3 data points.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...predictions.map((p) => _PredictionDetailCard(prediction: p)),
          ],
        ),
      ),
    );
  }
}

class _PredictionDetailCard extends StatelessWidget {
  final Prediction prediction;
  const _PredictionDetailCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final color = switch (prediction.healthStatus) {
      'CRITICAL' => AppColors.statusCritical,
      'WARNING' => AppColors.statusWarning,
      _ => AppColors.statusNormal,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                prediction.period == 'next_month'
                    ? Icons.calendar_month_rounded
                    : Icons.calendar_today_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                prediction.period == 'next_month' ? '📅 Next Month Forecast' : '📆 Next Year Forecast',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              const Spacer(),
              _StatusBadge(status: prediction.healthStatus, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MetricBox('Predicted', prediction.predictedValue.toStringAsFixed(3), color),
              const SizedBox(width: 8),
              _MetricBox('Confidence', '${(prediction.confidence * 100).toStringAsFixed(0)}%', AppColors.accent),
              const SizedBox(width: 8),
              _MetricBox('Risk', '${(prediction.riskScore * 100).toStringAsFixed(0)}%',
                  prediction.riskScore > 0.7 ? AppColors.statusCritical : AppColors.statusWarning),
            ],
          ),
          if (prediction.isAnomaly) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.statusCritical.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.statusCritical, size: 16),
                  SizedBox(width: 6),
                  Text('Anomaly Detected', style: TextStyle(color: AppColors.statusCritical, fontSize: 12)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            prediction.reasoning,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(status,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _TrendAnalysisCard extends StatelessWidget {
  final AnalyticsProvider analytics;
  const _TrendAnalysisCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final trend = analytics.currentTrend;
    final (icon, color, label) = switch (trend) {
      'increasing' => (Icons.trending_up_rounded, AppColors.statusWarning, 'Increasing Trend'),
      'decreasing' => (Icons.trending_down_rounded, Colors.blue, 'Decreasing Trend'),
      _ => (Icons.trending_flat_rounded, AppColors.statusNormal, 'Stable Trend'),
    };

    final values = analytics.getRecentValues(50);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                const Text('Trend Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 14),
                      const SizedBox(width: 4),
                      Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (values.length >= 2)
              SizedBox(
                height: 100,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i])),
                        isCurved: true,
                        color: color,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: color.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Text('Collecting trend data...', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

class _AnomalyDetectionCard extends StatelessWidget {
  final AnalyticsProvider analytics;
  final WebSocketProvider ws;
  const _AnomalyDetectionCard({required this.analytics, required this.ws});

  @override
  Widget build(BuildContext context) {
    final historicalValues = analytics.getRecentValues(200);
    final recentData = ws.recentData.take(20).toList();

    final anomalies = historicalValues.isNotEmpty
        ? recentData.where((d) => AnalyticsEngine.isAnomaly(d.value, historicalValues)).toList()
        : [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radar_rounded, color: AppColors.statusCritical),
                const SizedBox(width: 8),
                const Text('Anomaly Detection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: anomalies.isEmpty
                        ? AppColors.statusNormal.withOpacity(0.15)
                        : AppColors.statusCritical.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${anomalies.length} anomalies',
                    style: TextStyle(
                      color: anomalies.isEmpty ? AppColors.statusNormal : AppColors.statusCritical,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (anomalies.isEmpty)
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.statusNormal, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    historicalValues.isEmpty
                        ? 'Waiting for baseline data...'
                        : 'No anomalies detected in recent data',
                    style: const TextStyle(color: AppColors.statusNormal),
                  ),
                ],
              )
            else
              ...anomalies.map((d) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.statusCritical.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_rounded, color: AppColors.statusCritical, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Value: ${d.value.toStringAsFixed(4)} | Z=${AnalyticsEngine.zScore(d.value, historicalValues).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12),
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

class _StatisticsCard extends StatelessWidget {
  final AnalyticsProvider analytics;
  const _StatisticsCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final report = analytics.latestReport;
    if (report == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.bar_chart_rounded, size: 40, color: Colors.grey),
              const SizedBox(height: 8),
              Text('No statistics yet', style: TextStyle(color: Colors.grey.shade500)),
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
                Icon(Icons.bar_chart_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Statistical Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _StatRow('Average', report.averageValue.toStringAsFixed(4)),
            _StatRow('Maximum', report.maxValue.toStringAsFixed(4)),
            _StatRow('Minimum', report.minValue.toStringAsFixed(4)),
            _StatRow('Std Deviation', report.stdDeviation.toStringAsFixed(4)),
            _StatRow('Data Points', report.dataPointCount.toString()),
            _StatRow('Risk Score', '${(report.riskScore * 100).toStringAsFixed(1)}%'),
            _StatRow('Anomalies Found', report.anomalies.length.toString()),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
