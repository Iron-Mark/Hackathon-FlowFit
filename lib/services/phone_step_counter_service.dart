import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'step_detector.dart';

/// Service for counting steps using the phone's native accelerometer
///
/// Uses a peak detection algorithm on accelerometer magnitude to detect steps.
/// This service reads directly from the phone's accelerometer sensor.
class PhoneStepCounterService {
  final StepDetector _stepDetector;

  // Stream for step updates
  final StreamController<int> _stepController =
      StreamController<int>.broadcast();
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  PhoneStepCounterService({StepDetector? stepDetector})
    : _stepDetector = stepDetector ?? StepDetector();

  /// Stream of step count updates
  Stream<int> get stepStream => _stepController.stream;

  /// Current total step count
  int get totalSteps => _stepDetector.totalSteps;

  /// Starts step counting using phone's accelerometer
  Future<void> startCounting() async {
    debugPrint(
      '👟 PhoneStepCounter: Starting step counting from phone accelerometer...',
    );

    // Subscribe to phone's accelerometer stream
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        if (_stepDetector.processSample(event.x, event.y, event.z)) {
          _stepController.add(_stepDetector.totalSteps);
          debugPrint(
            '👣 PhoneStepCounter: Step detected! '
            'Total: ${_stepDetector.totalSteps}',
          );
        }
      },
      onError: (error) {
        debugPrint('❌ PhoneStepCounter: Error reading accelerometer: $error');
      },
    );

    debugPrint('✅ PhoneStepCounter: Step counting started from phone');
  }

  /// Stops step counting
  Future<void> stopCounting() async {
    await _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    debugPrint('🛑 PhoneStepCounter: Step counting stopped');
  }

  /// Resets step count to zero
  void resetSteps() {
    _stepDetector.reset();
    _stepController.add(_stepDetector.totalSteps);
    debugPrint('🔄 PhoneStepCounter: Steps reset to 0');
  }

  /// Disposes resources
  void dispose() {
    _accelerometerSubscription?.cancel();
    _stepController.close();
  }
}
