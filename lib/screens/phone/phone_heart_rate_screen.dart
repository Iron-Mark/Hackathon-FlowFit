import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/tracked_data.dart';
import '../../models/heart_rate_data.dart';
import '../../models/sensor_batch.dart';
import '../../models/sensor_status.dart';
import '../../services/phone_data_listener.dart';

/// Screen for displaying heart rate data received from Galaxy Watch
/// Shows real-time BPM, IBI values, and connection status
class PhoneHeartRateScreen extends StatefulWidget {
  const PhoneHeartRateScreen({super.key});

  @override
  State<PhoneHeartRateScreen> createState() => _PhoneHeartRateScreenState();
}

class _PhoneHeartRateScreenState extends State<PhoneHeartRateScreen> {
  final PhoneDataListener _dataListener = PhoneDataListener();

  final List<TrackedData> _receivedData = [];
  StreamSubscription<HeartRateData>? _subscription;
  StreamSubscription<SensorBatch>? _sensorBatchSubscription;
  bool _isConnected = false;
  DateTime? _lastDataTime;
  bool _isStartingListener = true;
  bool _listenerStarted = false;
  String? _listenerError;

  // Test mode state
  bool _isTestMode = false;
  SensorBatch? _lastSensorBatch;
  int _totalBatchesReceived = 0;

  @override
  void initState() {
    super.initState();
    _listenToWatchData();
    _listenToSensorBatches();
    _startWatchListener();
  }

  Future<void> _startWatchListener() async {
    setState(() {
      _isStartingListener = true;
      _listenerError = null;
    });

    final started = await _dataListener.startListening();
    if (!mounted) return;

    setState(() {
      _isStartingListener = false;
      _listenerStarted = started;
      _listenerError = started
          ? null
          : 'Could not start phone watch listener. Check Bluetooth and Wear OS connection, then retry.';
    });
  }

  void _listenToWatchData() {
    _subscription = _dataListener.heartRateStream.listen(
      (heartRateData) {
        setState(() {
          _isConnected = true;
          _lastDataTime = DateTime.now();

          // Convert to TrackedData for display (only if bpm is available)
          if (heartRateData.bpm != null) {
            final ibiValues = heartRateData.ibiValues;
            final hrv = ibiValues.length >= 2
                ? TrackedData.calculateHRV(ibiValues)
                : 0.0;

            final trackedData = TrackedData(
              hr: heartRateData.bpm!,
              ibiValues: ibiValues,
              hrv: hrv,
              spo2: 0, // Not available from watch yet
              timestamp: heartRateData.timestamp,
              status: heartRateData.status == SensorStatus.active
                  ? SensorStatus.active
                  : SensorStatus.inactive,
            );

            _receivedData.add(trackedData);

            // Keep only last 100 readings
            if (_receivedData.length > 100) {
              _receivedData.removeAt(0);
            }
          }
        });
      },
      onError: (error) {
        debugPrint('Error receiving watch data: $error');
        if (!mounted) return;
        setState(() {
          _isConnected = false;
          _isStartingListener = false;
          _listenerStarted = false;
          _listenerError =
              'Watch data stream stopped. Check Bluetooth and Wear OS connection, then retry.';
        });
      },
    );
  }

  void _listenToSensorBatches() {
    _sensorBatchSubscription = _dataListener.sensorBatchStream.listen(
      (batchData) {
        setState(() {
          _lastSensorBatch = batchData;
          _totalBatchesReceived++;
          _isConnected = true;
          _lastDataTime = DateTime.now();
        });

        debugPrint(
          '📦 Received sensor batch: ${batchData.sampleCount} samples',
        );
      },
      onError: (error) {
        debugPrint('Error receiving sensor batch: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _sensorBatchSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch Heart Rate Data'),
        actions: [
          // Test mode toggle
          IconButton(
            onPressed: () {
              setState(() {
                _isTestMode = !_isTestMode;
              });
            },
            icon: Icon(
              _isTestMode ? Icons.bug_report : Icons.bug_report_outlined,
            ),
            tooltip: 'Test Mode',
          ),
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.watch : Icons.watch_off,
                  color: _isConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isTestMode || _receivedData.isNotEmpty
          ? _buildDataList()
          : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _listenerStarted ? Icons.watch : Icons.watch_off,
            size: 80,
            color: _listenerStarted ? Colors.green[400] : Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            _isStartingListener
                ? 'Starting watch listener...'
                : _listenerStarted
                ? 'Listening for watch data'
                : 'Watch listener is not active',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _listenerError ?? 'Start heart rate tracking on your watch',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
          if (_isStartingListener) ...[
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ] else if (!_listenerStarted) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _startWatchListener,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataList() {
    // Show most recent data first
    final reversedData = _receivedData.reversed.toList();
    final latestData = reversedData.isNotEmpty ? reversedData.first : null;

    return Column(
      children: [
        // Test mode display
        if (_isTestMode) ...[_buildTestModeDisplay(), const Divider()],

        // Large BPM display at top
        if (latestData != null) _buildLatestBpmCard(latestData),

        // Data freshness indicator
        if (_lastDataTime != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Last updated: ${_formatTimestamp(_lastDataTime!)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),

        const Divider(),

        // List of all readings
        if (!_isTestMode)
          Expanded(
            child: ListView.builder(
              itemCount: reversedData.length,
              itemBuilder: (context, index) {
                final data = reversedData[index];
                return _buildDataTile(data, index == 0);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLatestBpmCard(TrackedData data) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Current Heart Rate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${data.hr}',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'BPM',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            if (data.ibiValues.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'IBI: ${data.ibiValues.take(5).join(", ")}${data.ibiValues.length > 5 ? "..." : ""} ms',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataTile(TrackedData data, bool isLatest) {
    return ListTile(
      leading: Icon(Icons.favorite, color: isLatest ? Colors.red : Colors.grey),
      title: Text(
        'HR: ${data.hr} bpm',
        style: TextStyle(
          fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: data.ibiValues.isNotEmpty
          ? Text(
              'IBI: ${data.ibiValues.take(4).join(", ")}${data.ibiValues.length > 4 ? "..." : ""} ms',
            )
          : const Text('No IBI data'),
      trailing: isLatest
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Latest',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTestModeDisplay() {
    final batch = _lastSensorBatch;

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bug_report, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Test Mode - Sensor Batch Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (batch != null) ...[
              _buildTestRow('Total Batches Received', '$_totalBatchesReceived'),
              _buildTestRow('Sample Count', '${batch.sampleCount}'),
              _buildTestRow(
                'Heart Rate',
                '${batch.samples.isNotEmpty ? batch.samples[0][3].toInt() : '--'} bpm',
              ),
              _buildTestRow('Sample Rate', '32 Hz'),
              _buildTestRow('Timestamp', '${batch.timestamp}'),
              const SizedBox(height: 12),
              const Text(
                'Accelerometer Samples (first 3):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              if (batch.samples.isNotEmpty) ...[
                ..._buildAccelerometerSamplesFromBatch(batch),
              ] else
                const Text(
                  'No accelerometer data',
                  style: TextStyle(color: Colors.grey),
                ),
            ] else
              const Text(
                'No sensor batch received yet',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAccelerometerSamplesFromBatch(SensorBatch batch) {
    final widgets = <Widget>[];
    final samplesToShow = batch.samples.take(3).toList();

    for (var i = 0; i < samplesToShow.length; i++) {
      final sample = samplesToShow[i];
      if (sample.length >= 4) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              'Sample ${i + 1}: X=${sample[0].toStringAsFixed(2)}, '
              'Y=${sample[1].toStringAsFixed(2)}, '
              'Z=${sample[2].toStringAsFixed(2)} m/s², '
              'BPM=${sample[3].toInt()}',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.black87,
              ),
            ),
          ),
        );
      }
    }

    if (batch.samples.length > 3) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '... and ${batch.samples.length - 3} more samples',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
