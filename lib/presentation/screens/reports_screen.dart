import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/constants/app_colors.dart';
import '../../domain/providers/analytics_provider.dart';
import '../../domain/providers/websocket_provider.dart';
import '../../core/utils/date_utils.dart' as AppDate;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Export')),
      body: Consumer2<AnalyticsProvider, WebSocketProvider>(
        builder: (context, analytics, ws, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ReportSummaryCard(analytics: analytics, ws: ws),
              const SizedBox(height: 16),
              _ExportCard(
                exporting: _exporting,
                onExportCsv: () => _exportCsv(context, analytics),
                onExportPdf: () => _exportPdf(context, analytics),
              ),
              const SizedBox(height: 16),
              _DataBreakdownCard(analytics: analytics),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, AnalyticsProvider analytics) async {
    setState(() => _exporting = true);
    try {
      final data = analytics.historicalData;
      final rows = [
        ['ID', 'Timestamp', 'Value', 'Metric'],
        ...data.map((d) => [d.id, d.timestamp.toIso8601String(), d.value.toString(), d.metric]),
      ];
      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/analytics_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'AI Analytics CSV Export');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf(BuildContext context, AnalyticsProvider analytics) async {
    setState(() => _exporting = true);
    try {
      final pdf = pw.Document();
      final report = analytics.latestReport;
      final predictions = analytics.predictions;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('AI Analytics Report',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Generated: ${AppDate.AppDateUtils.formatTimestamp(DateTime.now())}'),
            pw.SizedBox(height: 16),
            if (report != null) ...[
              pw.Header(level: 1, child: pw.Text('Statistical Summary')),
              pw.Table.fromTextArray(
                data: [
                  ['Metric', 'Value'],
                  ['Total Data Points', report.dataPointCount.toString()],
                  ['Average', report.averageValue.toStringAsFixed(4)],
                  ['Maximum', report.maxValue.toStringAsFixed(4)],
                  ['Minimum', report.minValue.toStringAsFixed(4)],
                  ['Std Deviation', report.stdDeviation.toStringAsFixed(4)],
                  ['Health Status', report.healthStatus],
                  ['Risk Score', '${(report.riskScore * 100).toStringAsFixed(1)}%'],
                  ['Anomalies Detected', report.anomalies.length.toString()],
                ],
              ),
              pw.SizedBox(height: 16),
            ],
            if (predictions.isNotEmpty) ...[
              pw.Header(level: 1, child: pw.Text('AI Predictions')),
              pw.Table.fromTextArray(
                data: [
                  ['Period', 'Predicted Value', 'Confidence', 'Health', 'Risk'],
                  ...predictions.map((p) => [
                        p.period == 'next_month' ? 'Next Month' : 'Next Year',
                        p.predictedValue.toStringAsFixed(4),
                        '${(p.confidence * 100).toStringAsFixed(0)}%',
                        p.healthStatus,
                        '${(p.riskScore * 100).toStringAsFixed(1)}%',
                      ]),
                ],
              ),
            ],
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/analytics_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'AI Analytics PDF Report');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class _ReportSummaryCard extends StatelessWidget {
  final AnalyticsProvider analytics;
  final WebSocketProvider ws;
  const _ReportSummaryCard({required this.analytics, required this.ws});

  @override
  Widget build(BuildContext context) {
    final report = analytics.latestReport;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assessment_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Report Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  AppDate.AppDateUtils.formatTimestamp(DateTime.now()),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SummaryGrid(analytics: analytics, ws: ws),
            if (report != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatusChip(label: 'Health: ${report.healthStatus}', color: _healthColor(report.healthStatus)),
                  const SizedBox(width: 8),
                  _StatusChip(label: '${report.anomalies.length} Anomalies', color: AppColors.statusWarning),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _healthColor(String status) => switch (status) {
        'CRITICAL' => AppColors.statusCritical,
        'WARNING' => AppColors.statusWarning,
        _ => AppColors.statusNormal,
      };
}

class _SummaryGrid extends StatelessWidget {
  final AnalyticsProvider analytics;
  final WebSocketProvider ws;
  const _SummaryGrid({required this.analytics, required this.ws});

  @override
  Widget build(BuildContext context) {
    final report = analytics.latestReport;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _GridMetric('Data Points', analytics.totalDataPoints.toString(), AppColors.primary),
        _GridMetric('Messages', ws.messageCount.toString(), AppColors.accent),
        _GridMetric('Avg Value', report?.averageValue.toStringAsFixed(3) ?? 'N/A', AppColors.primaryLight),
        _GridMetric('Predictions', analytics.predictions.length.toString(), AppColors.statusNormal),
      ],
    );
  }
}

class _GridMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _GridMetric(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _ExportCard extends StatelessWidget {
  final bool exporting;
  final VoidCallback onExportCsv;
  final VoidCallback onExportPdf;
  const _ExportCard({required this.exporting, required this.onExportCsv, required this.onExportPdf});

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
                Icon(Icons.file_download_rounded, color: AppColors.accent),
                SizedBox(width: 8),
                Text('Export Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (exporting)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.table_chart_rounded),
                      label: const Text('Export CSV'),
                      onPressed: onExportCsv,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusNormal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Export PDF'),
                      onPressed: onExportPdf,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusCritical,
                        foregroundColor: Colors.white,
                      ),
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

class _DataBreakdownCard extends StatelessWidget {
  final AnalyticsProvider analytics;
  const _DataBreakdownCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final monthly = analytics.monthlyAverages;
    final yearly = analytics.yearlyAverages;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Data Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _StatRow('Monthly records', monthly.length.toString()),
            _StatRow('Yearly records', yearly.length.toString()),
            _StatRow('Total data points', analytics.totalDataPoints.toString()),
            _StatRow('Current trend', analytics.currentTrend),
            _StatRow('Health status', analytics.currentHealthStatus),
            _StatRow('Risk score', '${(analytics.currentRiskScore * 100).toStringAsFixed(1)}%'),
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
