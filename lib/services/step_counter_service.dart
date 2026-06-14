import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/sensor_batch.dart';
import 'phone_data_listener.dart';

/// Service for counting steps using accelerometer data
///
/// Uses a peak detection algorithm on accelerometer magnitude to detect steps.
/// The algorithm detects peaks in the acceleration signal that correspond to footfalls.
class StepCounterService {
  final PhoneDataListener _phoneDataListener;

  // Step detection parameters
  static const double _stepThreshold =
      11.0; // m/s² - minimum acceleration for a step
  static const double _peakThreshold = 13.0; // m/s² - clear peak detection
  static const int _minTimeBetweenSteps =
      200; // milliseconds - prevents double counting

  // State tracking
  int _totalSteps = 0;
  DateTime? _lastStepTime;
  double _lastMagnitude = 0.0;
  bool _isPeakDetected = false;

  // Stream for step updates
  final StreamController<int> _stepController =
      StreamController<int>.broadcast();
  StreamSubscription<SensorBatch>? _sensorSubscription;

  StepCounterService(this._phoneDataListener);

  /// Stream of step count updates
  Stream<int> get stepStream => _stepController.stream;

  /// Current total step count
  int get totalSteps => _totalSteps;

  /// Starts step counting
  Future<void> startCounting() async {
    debugPrint('👟 StepCounter: Starting step counting...');

    // Subscribe to sensor batch stream
    _sensorSubscription = _phoneDataListener.sensorBatchStream.listen(
      (batch) => _processSensorBatch(batch),
      onError: (error) {
        debugPrint('❌ StepCounter: Error receiving sensor data: $error');
      },
    );

    debugPrint('✅ StepCounter: Step counting started');
  }

  /// Stops step counting
  Future<void> stopCounting() async {
    await _sensorSubscription?.cancel();
    _sensorSubscription = null;
    debugPrint('🛑 StepCounter: Step counting stopped');
  }

  /// Resets step count to zero
  void resetSteps() {
    _totalSteps = 0;
    _lastStepTime = null;
    _lastMagnitude = 0.0;
    _isPeakDetected = false;
    _stepController.add(_totalSteps);
    debugPrint('🔄 StepCounter: Steps reset to 0');
  }

  /// Processes a batch of sensor data to detect steps
  void _processSensorBatch(SensorBatch batch) {
    for (final sample in batch.samples) {
      if (sample.length >= 3) {
        final accX = sample[0];
        final accY = sample[1];
        final accZ = sample[2];

        // Calculate acceleration magnitude
        final magnitude = sqrt(accX * accX + accY * accY + accZ * accZ);

        // Detect step using peak detection algorithm
        _detectStep(magnitude);

        _lastMagnitude = magnitude;
      }
    }
  }

  /// Detects a step using peak detection algorithm
  void _detectStep(double magnitude) {
    final now = DateTime.now();

    // Check if enough time has passed since last step (prevents double counting)
    if (_lastStepTime != null) {
      final timeSinceLastStep = now.difference(_lastStepTime!).inMilliseconds;
      if (timeSinceLastStep < _minTimeBetweenSteps) {
        return;
      }
    }

    // Peak detection: current magnitude is high and was rising
    if (magnitude > _peakThreshold &&
        _lastMagnitude < magnitude &&
        !_isPeakDetected) {
      // Peak detected
      _isPeakDetected = true;
    }

    // Step confirmed: magnitude drops below threshold after peak
    if (_isPeakDetected &&
        magnitude < _stepThreshold &&
        _lastMagnitude > magnitude) {
      _totalSteps++;
      _lastStepTime = now;
      _isPeakDetected = false;

      // Emit step count update
      _stepController.add(_totalSteps);

      debugPrint('👣 StepCounter: Step detected! Total: $_totalSteps');
    }
  }

  /// Disposes resources
  void dispose() {
    _sensorSubscription?.cancel();
    _stepController.close();
  }
}
