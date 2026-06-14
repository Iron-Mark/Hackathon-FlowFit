import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wellness_state.dart';
import '../../providers/wellness_state_provider.dart';

/// Debug panel for testing wellness tracker functionality
class WellnessDebugPanel extends ConsumerStatefulWidget {
  const WellnessDebugPanel({super.key});

  @override
  ConsumerState<WellnessDebugPanel> createState() => _WellnessDebugPanelState();
}

class _WellnessDebugPanelState extends ConsumerState<WellnessDebugPanel> {
  bool _isExpanded = false;
  int _mockHeartRate = 75;
  double _mockMotion = 0.3;

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return Positioned(
        bottom: 80,
        right: 16,
        child: FloatingActionButton(
          mini: true,
          onPressed: () => setState(() => _isExpanded = true),
          backgroundColor: Colors.purple,
          child: const Icon(Icons.bug_report, size: 20),
        ),
      );
    }

    final wellnessState = ref.watch(wellnessStateProvider);

    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.purple[900],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Debug Panel',
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _isExpanded = false),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current State Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current State: ${wellnessState.state.displayName}',
                    style: const TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'HR: ${wellnessState.heartRate ?? "--"} BPM',
                    style: const TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Motion: ${wellnessState.motionMagnitude?.toStringAsFixed(2) ?? "--"} m/s²',
                    style: const TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Confidence: ${(wellnessState.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Mock State Override',
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Mock State Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMockButton('CALM', WellnessState.calm, Colors.green),
                _buildMockButton('STRESS', WellnessState.stress, Colors.orange),
                _buildMockButton('CARDIO', WellnessState.cardio, Colors.red),
              ],
            ),

            const SizedBox(height: 16),

            // Mock Sensor Data
            const Text(
              'Mock Sensor Data',
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HR: $_mockHeartRate BPM',
                        style: const TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      Slider(
                        value: _mockHeartRate.toDouble(),
                        min: 50,
                        max: 180,
                        divisions: 130,
                        activeColor: Colors.red,
                        inactiveColor: Colors.white.withValues(alpha: 0.3),
                        onChanged: (value) {
                          setState(() => _mockHeartRate = value.toInt());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Motion: ${_mockMotion.toStringAsFixed(1)} m/s²',
                        style: const TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      Slider(
                        value: _mockMotion,
                        min: 0,
                        max: 5,
                        divisions: 50,
                        activeColor: Colors.blue,
                        inactiveColor: Colors.white.withValues(alpha: 0.3),
                        onChanged: (value) {
                          setState(() => _mockMotion = value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Test Scenarios
            const Text(
              'Test Scenarios',
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildScenarioButton(
                  'Stress',
                  () => _simulateScenario(120, 0.3),
                ),
                _buildScenarioButton(
                  'Exercise',
                  () => _simulateScenario(150, 3.5),
                ),
                _buildScenarioButton('Calm', () => _simulateScenario(70, 0.2)),
                _buildScenarioButton(
                  'Watch Disconnect',
                  () => _simulateWatchDisconnect(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockButton(String label, WellnessState state, Color color) {
    return ElevatedButton(
      onPressed: () {
        final service = ref.read(wellnessStateServiceProvider);
        service.setMockState(state);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildScenarioButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'GeneralSans', fontSize: 10),
      ),
    );
  }

  void _simulateScenario(int hr, double motion) {
    setState(() {
      _mockHeartRate = hr;
      _mockMotion = motion;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Simulating: HR=$hr BPM, Motion=${motion.toStringAsFixed(1)} m/s²',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _simulateWatchDisconnect() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulating watch disconnection...'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
