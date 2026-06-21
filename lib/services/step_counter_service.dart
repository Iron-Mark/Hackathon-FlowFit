import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sensor_batch.dart';
import 'phone_data_listener.dart';
import 'step_detector.dart';

/// Service for counting steps using accelerometer data
///
/// Uses a peak detection algorithm on accelerometer magnitude to detect steps.
/// The algorithm detects peaks in the acceleration signal that correspond to footfalls.
class StepCounterService {
  final PhoneDataListener _phoneDataListener;
  final StepDetector _stepDetector;

  // Stream for step updates
  final StreamController<int> _stepController =
      StreamController<int>.broadcast();
  StreamSubscription<SensorBatch>? _sensorSubscription;

  StepCounterService(this._phoneDataListener, {StepDetector? stepDetector})
    : _stepDetector = stepDetector ?? StepDetector();

  /// Stream of step count updates
  Stream<int> get stepStream => _stepController.stream;

  /// Current total step count
  int get totalSteps => _stepDetector.totalSteps;

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
    _stepDetector.reset();
    _stepController.add(_stepDetector.totalSteps);
    debugPrint('🔄 StepCounter: Steps reset to 0');
  }

  /// Processes a batch of sensor data to detect steps
  void _processSensorBatch(SensorBatch batch) {
    for (final sample in batch.samples) {
      if (sample.length >= 3) {
        final accX = sample[0];
        final accY = sample[1];
        final accZ = sample[2];

        if (_stepDetector.processSample(accX, accY, accZ)) {
          _stepController.add(_stepDetector.totalSteps);
          debugPrint(
            '👣 StepCounter: Step detected! Total: ${_stepDetector.totalSteps}',
          );
        }
      }
    }
  }

  /// Disposes resources
  void dispose() {
    _sensorSubscription?.cancel();
    _stepController.close();
  }
}
