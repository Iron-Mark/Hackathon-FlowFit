import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';
import 'wear_heart_rate_screen.dart';

class WearDashboard extends StatelessWidget {
  final WearShape shape;
  final WearMode mode;

  const WearDashboard({super.key, required this.shape, required this.mode});

  @override
  Widget build(BuildContext context) {
    if (mode == WearMode.ambient) {
      return _buildAmbient();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'FlowFit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildButton(
              context,
              icon: Icons.favorite,
              label: 'Heart Rate',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      width: 140,
      height: 64,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AmbientMode(
                builder: (context, liveMode, _) =>
                    WearHeartRateScreen(shape: shape, mode: liveMode),
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbient() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              color: Colors.white.withValues(alpha: 0.3),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'FlowFit',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
