import 'dart:math';

typedef StepDetectorClock = DateTime Function();

/// Detects walking/running steps from acceleration magnitude peaks.
///
/// This keeps the core algorithm deterministic and shared by both phone-only
/// accelerometer counting and watch sensor-batch counting.
class StepDetector {
  static const double stepThreshold = 11.0;
  static const double peakThreshold = 13.0;
  static const int minTimeBetweenStepsMs = 200;

  final StepDetectorClock _clock;

  int _totalSteps = 0;
  DateTime? _lastStepTime;
  double _lastMagnitude = 0.0;
  bool _isPeakDetected = false;

  StepDetector({StepDetectorClock? clock}) : _clock = clock ?? DateTime.now;

  int get totalSteps => _totalSteps;

  void reset() {
    _totalSteps = 0;
    _lastStepTime = null;
    _lastMagnitude = 0.0;
    _isPeakDetected = false;
  }

  bool processSample(double accX, double accY, double accZ) {
    final magnitude = sqrt(accX * accX + accY * accY + accZ * accZ);
    return processMagnitude(magnitude);
  }

  bool processMagnitude(double magnitude) {
    final now = _clock();
    var detected = false;

    if (_lastStepTime == null ||
        now.difference(_lastStepTime!).inMilliseconds >=
            minTimeBetweenStepsMs) {
      if (magnitude > peakThreshold &&
          _lastMagnitude < magnitude &&
          !_isPeakDetected) {
        _isPeakDetected = true;
      }

      if (_isPeakDetected &&
          magnitude < stepThreshold &&
          _lastMagnitude > magnitude) {
        _totalSteps++;
        _lastStepTime = now;
        _isPeakDetected = false;
        detected = true;
      }
    }

    _lastMagnitude = magnitude;
    return detected;
  }
}
