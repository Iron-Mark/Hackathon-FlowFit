import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/watch_bridge.dart';
import '../../models/heart_rate_data.dart';
import '../../models/sensor_status.dart';

/// Watch-side UI for Galaxy Watch 6
/// Displays live heart rate data being captured from the watch sensors
/// This runs on the watch itself and shows what the user sees on their wrist
class HeartRateWatchScreen extends StatefulWidget {
  const HeartRateWatchScreen({super.key, this.watchBridge});

  final WatchBridgeService? watchBridge;

  @override
  State<HeartRateWatchScreen> createState() => _HeartRateWatchScreenState();
}

class _HeartRateWatchScreenState extends State<HeartRateWatchScreen> {
  late final WatchBridgeService _watchBridge;
  late final bool _ownsWatchBridge;

  StreamSubscription<HeartRateData>? _heartRateSubscription;
  Timer? _pulseResetTimer;
  HeartRateData? _currentHeartRate;
  String? _errorMessage;
  bool _isStarting = false;
  bool _isTracking = false;

  // Animation controller for pulsing heart icon
  bool _isPulsing = false;

  @override
  void initState() {
    super.initState();
    _watchBridge = widget.watchBridge ?? WatchBridgeService();
    _ownsWatchBridge = widget.watchBridge == null;
    _startTracking();
  }

  @override
  void dispose() {
    _pulseResetTimer?.cancel();
    unawaited(
      _stopTracking(updateUi: false)
          .catchError((Object error) {
            debugPrint('Error stopping tracking: $error');
          })
          .whenComplete(() {
            if (_ownsWatchBridge) {
              _watchBridge.dispose();
            }
          }),
    );
    super.dispose();
  }

  Future<void> _startTracking() async {
    if (_isStarting) return;

    setState(() {
      _errorMessage = null;
      _isStarting = true;
    });

    try {
      final started = await _watchBridge.startHeartRateTracking();

      if (!mounted) return;

      if (!started) {
        setState(() {
          _isStarting = false;
          _isTracking = false;
          _errorMessage =
              'Heart rate sensor is unavailable. Check permission and retry.';
        });
        return;
      }

      await _heartRateSubscription?.cancel();

      _heartRateSubscription = _watchBridge.heartRateStream.listen(
        (heartRateData) {
          if (!mounted) return;
          setState(() {
            _currentHeartRate = heartRateData;
            _errorMessage = null;
          });
          if (heartRateData.status == SensorStatus.active) {
            _triggerPulse();
          }
        },
        onError: (Object error) {
          debugPrint('Heart rate stream error: $error');
          if (!mounted) return;
          setState(() {
            _isTracking = false;
            _errorMessage =
                'Heart rate stream stopped. Check sensor permission and retry.';
          });
        },
      );

      setState(() {
        _isStarting = false;
        _isTracking = true;
      });
    } catch (e) {
      debugPrint('Error starting tracking: $e');
      if (!mounted) return;
      setState(() {
        _isStarting = false;
        _isTracking = false;
        _errorMessage =
            'Could not start heart rate tracking. Check sensor permission and retry.';
      });
    }
  }

  Future<void> _stopTracking({bool updateUi = true}) async {
    await _heartRateSubscription?.cancel();
    _heartRateSubscription = null;
    await _watchBridge.stopHeartRateTracking();
    if (!updateUi || !mounted) return;
    setState(() {
      _isTracking = false;
      _isStarting = false;
    });
  }

  void _triggerPulse() {
    if (!mounted) return;
    _pulseResetTimer?.cancel();
    setState(() {
      _isPulsing = true;
    });

    _pulseResetTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isPulsing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing heart icon
                AnimatedScale(
                  scale: _isPulsing ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: Icon(
                    Icons.favorite,
                    size: 60,
                    color: _isTracking ? Colors.red : Colors.grey,
                  ),
                ),

                const SizedBox(height: 20),

                // Large BPM display
                Text(
                  '${_currentHeartRate?.bpm ?? '--'}',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                // BPM label
                const Text(
                  'BPM',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),

                const SizedBox(height: 20),

                // Status indicator
                _buildStatusDot(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildErrorDisplay(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ElevatedButton.icon(
              onPressed: _isStarting ? null : _startTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 15),
              label: const Text('Retry', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot() {
    final status = _currentHeartRate?.status ?? SensorStatus.inactive;

    Color dotColor;
    String label;
    if (_errorMessage != null) {
      dotColor = Colors.red;
      label = 'ERROR';
    } else if (_isStarting) {
      dotColor = Colors.orange;
      label = 'STARTING';
    } else if (_currentHeartRate == null && _isTracking) {
      dotColor = Colors.green;
      label = 'TRACKING';
    } else {
      switch (status) {
        case SensorStatus.active:
          dotColor = Colors.green;
          label = 'TRACKING';
          break;
        case SensorStatus.inactive:
          dotColor = Colors.grey;
          label = 'INACTIVE';
          break;
        case SensorStatus.error:
          dotColor = Colors.red;
          label = 'ERROR';
          break;
        case SensorStatus.unavailable:
          dotColor = Colors.orange;
          label = 'UNAVAILABLE';
          break;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: dotColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
