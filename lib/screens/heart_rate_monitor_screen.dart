import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/providers.dart';

/// Example screen showing how to use Riverpod providers
///
/// This demonstrates the clean architecture with Riverpod state management.
class HeartRateMonitorScreen extends ConsumerWidget {
  const HeartRateMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the heart rate stream
    final heartRateAsync = ref.watch(currentHeartRateProvider);

    // Watch the tracking state
    final isTracking = ref.watch(heartRateTrackingStateProvider);

    // Watch the connection state
    final connectionAsync = ref.watch(watchConnectionStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Rate Monitor'),
        actions: [
          // Connection indicator
          connectionAsync.when(
            data: (isConnected) => Icon(
              isConnected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
              color: isConnected ? Colors.green : Colors.grey,
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Icon(Icons.error, color: Colors.red),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Heart rate display
            heartRateAsync.when(
              data: (heartRateData) => _buildHeartRateDisplay(heartRateData),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),

            const SizedBox(height: 40),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: isTracking
                      ? null
                      : () => ref
                            .read(heartRateTrackingStateProvider.notifier)
                            .startTracking(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: !isTracking
                      ? null
                      : () => ref
                            .read(heartRateTrackingStateProvider.notifier)
                            .stopTracking(),
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRateDisplay(HeartRateData data) {
    return Column(
      children: [
        // BPM display
        Text(
          data.bpm?.toString() ?? '--',
          style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
        ),
        const Text('BPM', style: TextStyle(fontSize: 24, color: Colors.grey)),

        const SizedBox(height: 20),

        // Status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(data.status),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            data.status.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // IBI count
        Text(
          'IBI Values: ${data.ibiValues.length}',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Color _getStatusColor(HeartRateStatus status) {
    switch (status) {
      case HeartRateStatus.active:
        return Colors.green;
      case HeartRateStatus.inactive:
        return Colors.grey;
      case HeartRateStatus.error:
        return Colors.red;
    }
  }
}
