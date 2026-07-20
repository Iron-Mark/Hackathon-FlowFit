import 'package:flutter/material.dart';

import 'package:flowfit/features/activity_classifier/presentation/watch_data_listener.dart';

/// Pure-display card summarizing the tracker's sensor sources, heart rate
/// connection state, and inference buffer fill level.
class TrackerStatusCard extends StatelessWidget {
  const TrackerStatusCard({
    super.key,
    required this.accelSource,
    required this.bpmSource,
    required this.pluginAvailable,
    required this.currentBpmValue,
    required this.simulatedHr,
    required this.bufferLength,
    required this.windowSize,
  });

  final AccelSource accelSource;
  final BpmSource bpmSource;
  final bool pluginAvailable;
  final int? currentBpmValue;
  final double simulatedHr;
  final int bufferLength;
  final int windowSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Accelerometer Status
          Row(
            children: [
              Icon(
                accelSource == AccelSource.watch
                    ? Icons.watch
                    : accelSource == AccelSource.phone
                    ? Icons.phone_android
                    : Icons.science,
                color: accelSource == AccelSource.watch
                    ? Colors.green
                    : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  accelSource == AccelSource.watch
                      ? 'Accelerometer: Watch'
                      : accelSource == AccelSource.phone
                      ? 'Accelerometer: Phone'
                      : 'Accelerometer: Simulated',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Heart Rate Status
          if (bpmSource == BpmSource.plugin) ...[
            Row(
              children: [
                Icon(
                  pluginAvailable ? Icons.check_circle : Icons.error,
                  color: pluginAvailable ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pluginAvailable
                        ? 'Heart Rate: Plugin connected'
                        : 'Heart Rate: Plugin not connected',
                    style: TextStyle(
                      color: pluginAvailable ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (bpmSource == BpmSource.watch) ...[
            Row(
              children: [
                Icon(
                  currentBpmValue != null
                      ? Icons.check_circle
                      : Icons.watch_off,
                  color: currentBpmValue != null ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentBpmValue != null
                        ? 'Heart Rate: Watch connected'
                        : 'Heart Rate: Waiting for watch...',
                    style: TextStyle(
                      color: currentBpmValue != null
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (bpmSource == BpmSource.simulation) ...[
            Row(
              children: [
                const Icon(Icons.science, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Heart Rate: Simulated (${simulatedHr.round()} BPM)',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Buffer status
          Row(
            children: [
              Icon(
                bufferLength == windowSize
                    ? Icons.check_circle
                    : Icons.hourglass_empty,
                color: bufferLength == windowSize
                    ? Colors.green
                    : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Buffer: $bufferLength/$windowSize samples',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),

          // Watch integration tip
          if (accelSource == AccelSource.watch ||
              bpmSource == BpmSource.watch) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      accelSource == AccelSource.watch
                          ? 'Using complete sensor batch from watch (accel + HR)'
                          : 'Using watch heart rate only',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
