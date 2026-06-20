import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

class WorkoutScreen extends StatefulWidget {
  final WearShape shape;
  final WearMode mode;

  const WorkoutScreen({super.key, required this.shape, required this.mode});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  bool _isTracking = false;
  int _duration = 0;
  int _heartRate = 72;
  int _calories = 0;
  Timer? _trackingTimer;

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAmbient = widget.mode == WearMode.ambient;
    final isRound = widget.shape == WearShape.round;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: EdgeInsets.all(isRound ? 20 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!isAmbient) ...[
                _buildWorkoutStats(),
                const SizedBox(height: 24),
                _buildControlButton(),
              ] else ...[
                _buildAmbientView(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutStats() {
    return Column(
      children: [
        Text(
          _formatDuration(_duration),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatColumn(Icons.favorite, '$_heartRate', 'BPM'),
            _buildStatColumn(Icons.local_fire_department, '$_calories', 'Cal'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.orange),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildControlButton() {
    return SizedBox(
      width: 120,
      height: 120,
      child: ElevatedButton(
        onPressed: _toggleTracking,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isTracking ? Colors.red : Colors.green,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isTracking ? Icons.stop : Icons.play_arrow, size: 42),
            const SizedBox(height: 4),
            Text(
              _isTracking ? 'Stop' : 'Start',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatDuration(_duration),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '$_heartRate BPM',
          style: TextStyle(fontSize: 16, color: Colors.grey[400]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _toggleTracking() {
    if (_isTracking) {
      _trackingTimer?.cancel();
      setState(() {
        _isTracking = false;
        _heartRate = 72;
      });
      return;
    }

    _trackingTimer?.cancel();
    setState(() {
      _isTracking = true;
      _duration = 0;
      _calories = 0;
      _heartRate = 96;
    });

    _trackingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _duration += 1;
        _heartRate = 96 + (_duration % 8);
        _calories = (_duration / 60 * 6).round();
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
