import 'package:flutter/material.dart';

import 'package:flowfit/screens/wear/wear_colors.dart';

/// Sensor status indicator showing heart rate and accelerometer status
/// Meets WCAG requirements: minimum 14sp font, color + icon for status
class WearSensorStatusRow extends StatelessWidget {
  const WearSensorStatusRow({
    super.key,
    required this.transmissionAnimation,
    required this.bpm,
    required this.isMonitoring,
    required this.isSimulatedHeartRate,
    required this.isAccelerometerActive,
  });

  final Animation<double> transmissionAnimation;
  final int? bpm;
  final bool isMonitoring;
  final bool isSimulatedHeartRate;
  final bool isAccelerometerActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Heart rate indicator
        Icon(
          Icons.favorite,
          color: isMonitoring ? Colors.red : Colors.grey,
          size: 24,
        ),
        const SizedBox(width: 4),
        Text(
          bpm != null ? '$bpm' : '--',
          style: const TextStyle(
            fontSize: 18, // Meets minimum 14sp requirement
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        // Accelerometer indicator with animation
        AnimatedBuilder(
          animation: transmissionAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: transmissionAnimation.value,
              child: Icon(
                Icons.sensors,
                color: isSimulatedHeartRate
                    ? WearColors.teal
                    : isAccelerometerActive
                    ? WearColors.primaryBlue
                    : Colors.grey,
                size: 24,
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        Text(
          isSimulatedHeartRate
              ? 'Sim'
              : (isAccelerometerActive ? 'Active' : 'Off'),
          style: const TextStyle(
            fontSize: 14, // Meets minimum 14sp requirement
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Large BPM display with pulse animation while monitoring
class WearBpmDisplay extends StatelessWidget {
  const WearBpmDisplay({
    super.key,
    required this.pulseAnimation,
    required this.bpm,
    required this.isMonitoring,
    required this.showServiceUnavailableNote,
  });

  final Animation<double> pulseAnimation;
  final int? bpm;
  final bool isMonitoring;
  final bool showServiceUnavailableNote;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isMonitoring ? pulseAnimation.value : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!showServiceUnavailableNote) ...[
                Icon(
                  Icons.favorite,
                  color: isMonitoring ? Colors.red : Colors.grey.shade700,
                  size: 32,
                ),
                const SizedBox(height: 8),
              ],
              Text(
                bpm != null ? '$bpm' : '--',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'BPM',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                  letterSpacing: 0,
                ),
              ),
              if (showServiceUnavailableNote) ...[
                const SizedBox(height: 2),
                const SizedBox(
                  width: 180,
                  child: Text(
                    'Samsung Health service unavailable',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: WearColors.teal),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Dimmed BPM readout for ambient mode
class WearAmbientDisplay extends StatelessWidget {
  const WearAmbientDisplay({super.key, required this.bpm});

  final int? bpm;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.favorite, color: Colors.white24, size: 24),
        const SizedBox(height: 8),
        Text(
          bpm != null ? '$bpm' : '--',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white24,
          ),
        ),
        const Text(
          'BPM',
          style: TextStyle(fontSize: 14, color: Colors.white10),
        ),
      ],
    );
  }
}

/// Status indicator with color-coded states
/// Uses teal for success states, errorRed for errors, primaryBlue for ready
/// Requirements: 4.1, 4.4, 4.5
class WearStatusIndicator extends StatelessWidget {
  const WearStatusIndicator({
    super.key,
    required this.statusMessage,
    required this.isConnected,
    required this.isMonitoring,
  });

  final String statusMessage;
  final bool isConnected;
  final bool isMonitoring;

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.grey;

    // Determine status color based on state
    if (statusMessage == 'Sent!' ||
        statusMessage == 'Active' ||
        statusMessage == 'Simulated') {
      // Success states use teal (Requirements: 4.4)
      statusColor = WearColors.teal;
    } else if (statusMessage.contains('Error') ||
        statusMessage.contains('Failed') ||
        statusMessage.contains('denied') ||
        statusMessage.contains('unavailable')) {
      // Error states use errorRed (Requirements: 4.5)
      statusColor = WearColors.errorRed;
    } else if (isConnected && isMonitoring) {
      // Active monitoring uses teal (Requirements: 4.4)
      statusColor = WearColors.teal;
    } else if (isConnected) {
      // Ready state uses primaryBlue (Requirements: 4.1)
      statusColor = WearColors.primaryBlue;
    } else {
      // Disconnected/unknown uses grey
      statusColor = Colors.grey;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(height: 2),
        Text(
          statusMessage,
          style: TextStyle(fontSize: 10, color: statusColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
