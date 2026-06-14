import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Service for counting steps using the phone's native accelerometer
///
/// Uses a peak detection algorithm on accelerometer magnitude to detect steps.
/// This service reads directly from the phone's accelerometer sensor.
class PhoneStepCounterService {
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
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  /// Stream of step count updates
  Stream<int> get stepStream => _stepController.stream;

  /// Current total step count
  int get totalSteps => _totalSteps;

  /// Starts step counting using phone's accelerometer
  Future<void> startCounting() async {
    debugPrint(
      '👟 PhoneStepCounter: Starting step counting from phone accelerometer...',
    );

    // Subscribe to phone's accelerometer stream
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        // Calculate acceleration magnitude
        final magnitude = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );

        // Detect step using peak detection algorithm
        _detectStep(magnitude);

        _lastMagnitude = magnitude;
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
    _totalSteps = 0;
    _lastStepTime = null;
    _lastMagnitude = 0.0;
    _isPeakDetected = false;
    _stepController.add(_totalSteps);
    debugPrint('🔄 PhoneStepCounter: Steps reset to 0');
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

      debugPrint('👣 PhoneStepCounter: Step detected! Total: $_totalSteps');
    }
  }

  /// Disposes resources
  void dispose() {
    _accelerometerSubscription?.cancel();
    _stepController.close();
  }
}
