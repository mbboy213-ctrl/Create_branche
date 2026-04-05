import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';

class MiniChart extends StatelessWidget {
  final List<double> values;
  final Color? color;
  final double height;

  const MiniChart({
    super.key,
    required this.values,
    this.color,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height);

    final chartColor = color ?? AppColors.accent;
    final spots = List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range == 0 ? 1.0 : range * 0.1;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: chartColor,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    chartColor.withOpacity(0.3),
                    chartColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
