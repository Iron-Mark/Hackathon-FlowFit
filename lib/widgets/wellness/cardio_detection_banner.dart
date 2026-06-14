import 'package:flutter/material.dart';

/// Banner displayed when cardio activity is detected
class CardioDetectionBanner extends StatelessWidget {
  final int heartRate;
  final Function(String activityType) onStartWorkout;
  final VoidCallback onDismiss;

  const CardioDetectionBanner({
    super.key,
    required this.heartRate,
    required this.onStartWorkout,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFEF4444)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('💪', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Exercise detected! Keep it up!',
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Heart Rate: $heartRate BPM',
                        style: const TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, color: Colors.white),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Start tracking this workout?',
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActivityButton(
                    icon: Icons.directions_run,
                    label: 'Run',
                    onTap: () => onStartWorkout('running'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActivityButton(
                    icon: Icons.directions_walk,
                    label: 'Walk',
                    onTap: () => onStartWorkout('walking'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActivityButton(
                    icon: Icons.directions_bike,
                    label: 'Cycle',
                    onTap: () => onStartWorkout('cycling'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
              ),
              child: const Text(
                'No Thanks',
                style: TextStyle(fontFamily: 'GeneralSans'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size(0, 48),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
