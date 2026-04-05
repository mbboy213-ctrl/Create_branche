import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/providers/websocket_provider.dart';
import '../../domain/providers/settings_provider.dart';
import '../../data/websocket/websocket_service.dart';
import '../../data/models/sensor_data.dart';

class RealtimeScreen extends StatefulWidget {
  const RealtimeScreen({super.key});

  @override
  State<RealtimeScreen> createState() => _RealtimeScreenState();
}

class _RealtimeScreenState extends State<RealtimeScreen> {
  bool _showRaw = false;
  final _msgController = TextEditingController();

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Data Stream'),
        actions: [
          IconButton(
            icon: Icon(_showRaw ? Icons.bar_chart_rounded : Icons.code_rounded),
            onPressed: () => setState(() => _showRaw = !_showRaw),
            tooltip: _showRaw ? 'Show Chart' : 'Show Raw',
          ),
          Consumer<WebSocketProvider>(
            builder: (_, ws, __) => IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: ws.clearData,
              tooltip: 'Clear Data',
            ),
          ),
        ],
      ),
      body: Consumer<WebSocketProvider>(
        builder: (context, ws, _) {
          return Column(
            children: [
              _ConnectionBar(ws: ws),
              Expanded(
                child: _showRaw ? _RawMessageList(ws: ws) : _ChartView(ws: ws),
              ),
              _SendMessageBar(ws: ws, controller: _msgController),
            ],
          );
        },
      ),
    );
  }
}

class _ConnectionBar extends StatelessWidget {
  final WebSocketProvider ws;
  const _ConnectionBar({required this.ws});

  @override
  Widget build(BuildContext context) {
    final color = ws.isConnected ? AppColors.statusNormal : AppColors.statusCritical;
    return Container(
      color: color.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: ws.isConnected
                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6, spreadRadius: 2)]
                  : [],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            ws.isConnected ? 'Live: ${ws.connectedUrl}' : 'Not connected',
            style: TextStyle(fontSize: 12, color: color),
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            '${ws.messageCount} messages | ${ws.messagesPerSecond.toStringAsFixed(1)}/s',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _ChartView extends StatelessWidget {
  final WebSocketProvider ws;
  const _ChartView({required this.ws});

  @override
  Widget build(BuildContext context) {
    final data = ws.recentData.take(50).toList().reversed.toList();
    if (data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off_rounded, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('Waiting for data...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final spots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i].value),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (v) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (v, meta) => Text(
                        v.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _DataStats(data: data),
        ],
      ),
    );
  }
}

class _DataStats extends StatelessWidget {
  final List<SensorData> data;
  const _DataStats({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final values = data.map((d) => d.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem('Min', min.toStringAsFixed(3), Colors.blue),
        _StatItem('Avg', avg.toStringAsFixed(3), AppColors.accent),
        _StatItem('Max', max.toStringAsFixed(3), AppColors.statusWarning),
        _StatItem('Count', data.length.toString(), AppColors.primary),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _RawMessageList extends StatelessWidget {
  final WebSocketProvider ws;
  const _RawMessageList({required this.ws});

  @override
  Widget build(BuildContext context) {
    final messages = ws.rawMessages;
    if (messages.isEmpty) {
      return const Center(child: Text('No messages yet', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: messages.length,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text('[$i]', style: const TextStyle(color: Colors.grey, fontSize: 10)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                messages[i],
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendMessageBar extends StatelessWidget {
  final WebSocketProvider ws;
  final TextEditingController controller;
  const _SendMessageBar({required this.ws, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Send message...',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (msg) {
                ws.sendMessage(msg);
                controller.clear();
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send_rounded),
            onPressed: () {
              ws.sendMessage(controller.text);
              controller.clear();
            },
          ),
        ],
      ),
    );
  }
}
