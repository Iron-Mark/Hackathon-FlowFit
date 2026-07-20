import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flowfit/features/activity_classifier/platform/tflite_activity_classifier.dart';
import 'package:flowfit/features/activity_classifier/presentation/providers.dart';
import 'package:flowfit/models/heart_rate_data.dart';
import 'package:flowfit/services/sensors/phone_data_listener.dart';

/// AI continuous-detection pipeline for the active running screen.
///
/// Owns the 320-sample sensor buffer, the detection timer scheduling, and the
/// watch heart-rate and sensor-batch subscriptions. The screen shell resolves
/// the Riverpod dependencies and hands them in; [RunningActivityDetection.new]
/// takes a `readViewModel` callback that returns null once the shell is
/// unmounted so a detection pass is skipped instead of touching a disposed
/// ref.
class RunningActivityDetection {
  RunningActivityDetection({
    required TFLiteActivityClassifier classifier,
    required PhoneDataListener phoneDataListener,
    required ActivityClassifierViewModel? Function() readViewModel,
    required void Function(HeartRateData heartRateData) onHeartRate,
  }) : _classifier = classifier,
       _phoneDataListener = phoneDataListener,
       _readViewModel = readViewModel,
       _onHeartRate = onHeartRate;

  final TFLiteActivityClassifier _classifier;
  final PhoneDataListener _phoneDataListener;
  final ActivityClassifierViewModel? Function() _readViewModel;
  final void Function(HeartRateData heartRateData) _onHeartRate;

  // Sensor data collection for AI
  StreamSubscription? _sensorSubscription;
  StreamSubscription? _heartRateSubscription;
  final List<List<double>> _sensorBuffer = [];
  Timer? _detectionTimer;
  static const int _windowSize = 320;

  Future<void> start() async {
    // Start listening for watch data FIRST — before model loading
    await _phoneDataListener.startListening();

    // Subscribe to real-time heart rate from watch immediately (independent of AI model)
    _heartRateSubscription = _phoneDataListener.heartRateStream.listen(
      _onHeartRate,
      onError: (error) {
        debugPrint('❌ Heart rate stream error: $error');
      },
    );

    // Load AI model — HR display continues even if this fails
    try {
      if (!_classifier.isLoaded) {
        await _classifier.loadModel();
      }
    } catch (e) {
      debugPrint('⚠️ AI model load failed (HR still active): $e');
      return;
    }

    // Subscribe to sensor batches from watch (includes accelerometer + heart rate)
    _sensorSubscription = _phoneDataListener.sensorBatchStream.listen((
      sensorBatch,
    ) {
      // Add all samples from the batch to our buffer
      for (final sample in sensorBatch.samples) {
        if (sample.length == 4) {
          _sensorBuffer.add(sample);

          // Keep only last 320 samples
          if (_sensorBuffer.length > _windowSize) {
            _sensorBuffer.removeAt(0);
          }
        }
      }

      // Run inference when we have enough data (>= 320 samples)
      if (_sensorBuffer.length >= _windowSize) {
        _runDetection();
      }
    });

    // Schedule first detection as backup
    _scheduleNextDetection(10);
  }

  void _scheduleNextDetection(int seconds) {
    _detectionTimer?.cancel();
    _detectionTimer = Timer(Duration(seconds: seconds), () {
      _runDetection();
    });
  }

  Future<void> _runDetection() async {
    if (_sensorBuffer.length < _windowSize) {
      debugPrint(
        '🔴 Buffer not ready: ${_sensorBuffer.length}/$_windowSize samples',
      );
      _scheduleNextDetection(5);
      return;
    }

    try {
      debugPrint(
        '🟢 Running AI detection with ${_sensorBuffer.length} samples',
      );
      // _runDetection is invoked from Timer and stream callbacks across async
      // gaps; the shell's readViewModel callback returns null once its
      // ConsumerState is disposed, so skip this pass instead of reading a
      // disposed ref.
      final viewModel = _readViewModel();
      if (viewModel == null) return;
      final bufferCopy = List<List<double>>.from(
        _sensorBuffer.take(_windowSize),
      );
      await viewModel.classify(bufferCopy);
      debugPrint('✅ AI detection completed');

      // Schedule next detection
      _scheduleNextDetection(15);
    } catch (e) {
      debugPrint('❌ Detection failed: $e');
      _scheduleNextDetection(10);
    }
  }

  void dispose() {
    _sensorSubscription?.cancel();
    _heartRateSubscription?.cancel();
    _detectionTimer?.cancel();
  }
}
