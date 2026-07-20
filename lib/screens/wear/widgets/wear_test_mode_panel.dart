import 'package:flutter/material.dart';

import 'package:flowfit/screens/wear/wear_colors.dart';

/// Test mode toggle button
/// Requirements: 8.5
class WearTestModeToggle extends StatelessWidget {
  const WearTestModeToggle({
    super.key,
    required this.isTestMode,
    required this.onPressed,
  });

  final bool isTestMode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48, // WCAG 2.1 Level AA: minimum 48dp touch target
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: isTestMode ? WearColors.teal : Colors.grey.shade800,
          foregroundColor: Colors.white,
        ),
        icon: Icon(
          isTestMode ? Icons.bug_report : Icons.bug_report_outlined,
          size: 20,
        ),
      ),
    );
  }
}

/// Test mode display showing real-time sensor values
/// Requirements: 8.5, 11.2
class WearTestModeDisplay extends StatelessWidget {
  const WearTestModeDisplay({super.key, required this.data});

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WearColors.teal.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WearColors.teal, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Mode',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: WearColors.teal,
            ),
          ),
          const SizedBox(height: 8),
          // Heart rate
          _buildTestModeRow(
            'HR',
            data?['heartRate']?.toString() ?? '--',
            'bpm',
          ),
          const SizedBox(height: 4),
          // Accelerometer X
          _buildTestModeRow(
            'Acc X',
            data?['accelerometerX'] != null
                ? (data!['accelerometerX'] as double).toStringAsFixed(2)
                : '--',
            'm/s²',
          ),
          const SizedBox(height: 4),
          // Accelerometer Y
          _buildTestModeRow(
            'Acc Y',
            data?['accelerometerY'] != null
                ? (data!['accelerometerY'] as double).toStringAsFixed(2)
                : '--',
            'm/s²',
          ),
          const SizedBox(height: 4),
          // Accelerometer Z
          _buildTestModeRow(
            'Acc Z',
            data?['accelerometerZ'] != null
                ? (data!['accelerometerZ'] as double).toStringAsFixed(2)
                : '--',
            'm/s²',
          ),
          const SizedBox(height: 4),
          // Buffer size
          _buildTestModeRow(
            'Buffer',
            '${data?['bufferSize'] ?? 0}/32',
            'samples',
          ),
          const SizedBox(height: 4),
          // Time since last transmission
          _buildTestModeRow(
            'Last TX',
            data?['timeSinceLastTransmission'] != null
                ? '${(data!['timeSinceLastTransmission'] as int) ~/ 1000}'
                : '--',
            's ago',
          ),
        ],
      ),
    );
  }

  /// Helper widget to build a test mode data row
  /// Requirements: 8.5
  Widget _buildTestModeRow(String label, String value, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        Text(
          '$value $unit',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
