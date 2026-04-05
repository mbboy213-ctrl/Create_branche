import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class HealthIndicatorCard extends StatelessWidget {
  final String status;
  final double riskScore;
  final String trend;

  const HealthIndicatorCard({
    super.key,
    required this.status,
    required this.riskScore,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      'CRITICAL' => (AppColors.statusCritical, Icons.dangerous_rounded),
      'WARNING' => (AppColors.statusWarning, Icons.warning_amber_rounded),
      _ => (AppColors.statusNormal, Icons.check_circle_rounded),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Health: $status',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: riskScore,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Risk: ${(riskScore * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const Spacer(),
                      Text(
                        'Trend: $trend',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
