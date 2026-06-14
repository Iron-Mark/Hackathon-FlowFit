import 'package:flutter/material.dart';
import '../services/watch_bridge.dart';
import '../widgets/permission_status_widget.dart';

/// Screen that demonstrates permission state UI updates
/// Shows current permission status and provides controls for permission management
class SensorPermissionScreen extends StatefulWidget {
  const SensorPermissionScreen({super.key});

  @override
  State<SensorPermissionScreen> createState() => _SensorPermissionScreenState();
}

class _SensorPermissionScreenState extends State<SensorPermissionScreen> {
  late final WatchBridgeService _watchBridge;

  @override
  void initState() {
    super.initState();
    _watchBridge = WatchBridgeService();
  }

  @override
  void dispose() {
    _watchBridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Permissions'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Body Sensor Permission',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'FlowFit needs access to your body sensors to track heart rate and other health metrics from your Galaxy Watch.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            PermissionStatusWidget(
              watchBridge: _watchBridge,
              showOpenSettingsButton: true,
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'What we track:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              Icons.favorite,
              'Heart Rate',
              'Real-time heart rate monitoring during activities',
              Colors.red,
            ),
            _buildFeatureItem(
              Icons.directions_walk,
              'Activity Tracking',
              'Track steps, distance, and calories burned',
              Colors.green,
            ),
            _buildFeatureItem(
              Icons.fitness_center,
              'Workout Sessions',
              'Monitor performance during workouts',
              Colors.orange,
            ),
            _buildFeatureItem(
              Icons.nightlight,
              'Sleep Tracking',
              'Analyze sleep quality and patterns',
              Colors.purple,
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Your privacy matters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Your health data is stored securely and never shared without your explicit consent. You can revoke permissions at any time in your device settings.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
