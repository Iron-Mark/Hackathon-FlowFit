import 'package:flutter/material.dart';
import '../services/watch_bridge.dart';
import '../models/heart_rate_data.dart';
import '../models/permission_status.dart';

/// Example widget showing how to use Samsung Health Sensor integration
/// This can be integrated into your wear_dashboard.dart or activity_tracker.dart
class HeartRateExample extends StatefulWidget {
  const HeartRateExample({super.key});

  @override
  State<HeartRateExample> createState() => _HeartRateExampleState();
}

class _HeartRateExampleState extends State<HeartRateExample> {
  final WatchBridgeService _watchBridge = WatchBridgeService();

  bool _isConnected = false;
  bool _isTracking = false;
  HeartRateData? _latestHeartRate;
  String _statusMessage = 'Not connected';

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    try {
      final permissionStatus = await _watchBridge.checkBodySensorPermission();
      if (permissionStatus != PermissionStatus.granted) {
        setState(() {
          _statusMessage = 'Permission required';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _requestPermission() async {
    try {
      final granted = await _watchBridge.requestBodySensorPermission();
      setState(() {
        _statusMessage = granted ? 'Permission granted' : 'Permission denied';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Permission error: $e';
      });
    }
  }

  Future<void> _connect() async {
    try {
      setState(() {
        _statusMessage = 'Checking permissions...';
      });

      // Check and request permission first
      final permissionStatus = await _watchBridge.checkPermission();
      if (permissionStatus != 'granted') {
        final granted = await _watchBridge.requestPermission();
        if (!granted) {
          setState(() {
            _statusMessage = 'Permission denied';
          });
          return;
        }
      }

      setState(() {
        _statusMessage = 'Connecting...';
      });

      final connected = await _watchBridge.connectToWatch();
      setState(() {
        _isConnected = connected;
        _statusMessage = connected ? 'Connected' : 'Connection failed';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Connection error: $e';
      });
    }
  }

  Future<void> _startTracking() async {
    if (!_isConnected) {
      setState(() {
        _statusMessage = 'Not connected';
      });
      return;
    }

    try {
      final started = await _watchBridge.startHeartRateTracking();
      if (started) {
        setState(() {
          _isTracking = true;
          _statusMessage = 'Tracking...';
        });

        // Listen to heart rate stream
        _watchBridge.heartRateStream.listen(
          (heartRateData) {
            setState(() {
              _latestHeartRate = heartRateData;
              _statusMessage = 'Receiving data';
            });
          },
          onError: (error) {
            setState(() {
              _statusMessage = 'Stream error: $error';
            });
          },
        );
      } else {
        setState(() {
          _statusMessage = 'Failed to start tracking';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Tracking error: $e';
      });
    }
  }

  Future<void> _stopTracking() async {
    try {
      await _watchBridge.stopHeartRateTracking();
      setState(() {
        _isTracking = false;
        _statusMessage = 'Tracking stopped';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Stop error: $e';
      });
    }
  }

  Future<void> _disconnect() async {
    try {
      await _watchBridge.disconnectFromWatch();
      setState(() {
        _isConnected = false;
        _isTracking = false;
        _latestHeartRate = null;
        _statusMessage = 'Disconnected';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Disconnect error: $e';
      });
    }
  }

  @override
  void dispose() {
    _watchBridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Heart rate display
            if (_latestHeartRate != null && _latestHeartRate!.bpm != null)
              Text(
                '${_latestHeartRate!.bpm}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              const Text(
                '--',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),

            const SizedBox(height: 8),

            const Text('BPM', style: TextStyle(fontSize: 16)),

            const SizedBox(height: 16),

            // IBI values (if available)
            if (_latestHeartRate != null &&
                _latestHeartRate!.ibiValues.isNotEmpty)
              Text(
                'IBI: ${_latestHeartRate!.ibiValues.length} values',
                style: const TextStyle(fontSize: 12),
              ),

            const SizedBox(height: 8),

            // Status message
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Control buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _requestPermission,
                  child: const Text('Permission'),
                ),
                ElevatedButton(
                  onPressed: _isConnected ? null : _connect,
                  child: const Text('Connect'),
                ),
                ElevatedButton(
                  onPressed: _isConnected && !_isTracking
                      ? _startTracking
                      : null,
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: _isTracking ? _stopTracking : null,
                  child: const Text('Stop'),
                ),
                ElevatedButton(
                  onPressed: _isConnected ? _disconnect : null,
                  child: const Text('Disconnect'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
