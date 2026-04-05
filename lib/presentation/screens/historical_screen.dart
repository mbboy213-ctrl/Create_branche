import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/providers/analytics_provider.dart';

class HistoricalScreen extends StatefulWidget {
  const HistoricalScreen({super.key});

  @override
  State<HistoricalScreen> createState() => _HistoricalScreenState();
}

class _HistoricalScreenState extends State<HistoricalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historical Analysis'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Monthly'),
            Tab(icon: Icon(Icons.calendar_today_rounded), text: 'Yearly'),
          ],
        ),
        actions: [
          Consumer<AnalyticsProvider>(
            builder: (_, analytics, __) => IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: analytics.refreshData,
            ),
          ),
        ],
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, analytics, _) {
          if (analytics.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tab,
            children: [
              _MonthlyView(analytics: analytics),
              _YearlyView(analytics: analytics),
            ],
          );
        },
      ),
    );
  }
}

class _MonthlyView extends StatelessWidget {
  final AnalyticsProvider analytics;
  const _MonthlyView({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final monthly = analytics.monthlyAverages;
    if (monthly.isEmpty) {
      return const _EmptyState(message: 'No monthly data yet.\nConnect and stream data to populate history.');
    }

    final sortedKeys = monthly.keys.toList()..sort();
    final values = sortedKeys.map((k) => monthly[k]!).toList();
    final maxVal = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('Monthly Averages (${monthly.length} months)'),
        const SizedBox(height: 8),
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.2,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= sortedKeys.length) return const SizedBox.shrink();
                      final parts = sortedKeys[idx].split('-');
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          parts.length >= 2 ? '${parts[1]}/${parts[0].substring(2)}' : sortedKeys[idx],
                          style: const TextStyle(fontSize: 9),
                        ),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (v, meta) =>
                        Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 9)),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
              ),
              barGroups: List.generate(
                sortedKeys.length,
                (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionTitle('Monthly Data Table'),
        const SizedBox(height: 8),
        _DataTable(
          keys: sortedKeys.reversed.toList(),
          values: sortedKeys.reversed.map((k) => monthly[k]!).toList(),
          keyLabel: 'Month',
          valueLabel: 'Average Value',
        ),
      ],
    );
  }
}

class _YearlyView extends StatelessWidget {
  final AnalyticsProvider analytics;
  const _YearlyView({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final yearly = analytics.yearlyAverages;
    if (yearly.isEmpty) {
      return const _EmptyState(message: 'No yearly data yet.\nConnect and stream data to accumulate yearly history.');
    }

    final sortedKeys = yearly.keys.toList()..sort();
    final values = sortedKeys.map((k) => yearly[k]!).toList();
    final maxVal = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('Yearly Averages (${yearly.length} years)'),
        const SizedBox(height: 8),
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.2,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= sortedKeys.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(sortedKeys[idx], style: const TextStyle(fontSize: 10)),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (v, meta) =>
                        Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 9)),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
              ),
              barGroups: List.generate(
                sortedKeys.length,
                (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [AppColors.primaryDark, AppColors.primaryLight],
                      ),
                      width: 24,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionTitle('Year-over-Year Comparison'),
        const SizedBox(height: 8),
        if (values.length >= 2) _YearComparisonRow(
          keys: sortedKeys,
          values: values,
        ),
        const SizedBox(height: 16),
        _DataTable(
          keys: sortedKeys.reversed.toList(),
          values: sortedKeys.reversed.map((k) => yearly[k]!).toList(),
          keyLabel: 'Year',
          valueLabel: 'Average Value',
        ),
      ],
    );
  }
}

class _YearComparisonRow extends StatelessWidget {
  final List<String> keys;
  final List<double> values;
  const _YearComparisonRow({required this.keys, required this.values});

  @override
  Widget build(BuildContext context) {
    final changes = <Widget>[];
    for (int i = 1; i < values.length; i++) {
      final change = values[i] - values[i - 1];
      final pct = values[i - 1] != 0 ? (change / values[i - 1] * 100) : 0.0;
      final color = change >= 0 ? AppColors.statusNormal : AppColors.statusCritical;
      changes.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text('${keys[i - 1]} → ${keys[i]}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: changes);
  }
}

class _DataTable extends StatelessWidget {
  final List<String> keys;
  final List<double> values;
  final String keyLabel;
  final String valueLabel;
  const _DataTable({
    required this.keys,
    required this.values,
    required this.keyLabel,
    required this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: DataTable(
        columnSpacing: 24,
        columns: [
          DataColumn(label: Text(keyLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(valueLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: List.generate(
          keys.length,
          (i) => DataRow(cells: [
            DataCell(Text(keys[i])),
            DataCell(Text(values[i].toStringAsFixed(4))),
          ]),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
