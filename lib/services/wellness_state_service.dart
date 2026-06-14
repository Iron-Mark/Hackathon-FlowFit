import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/wellness_state.dart';
import '../models/heart_rate_data.dart';
import '../models/sensor_batch.dart';
import 'phone_data_listener.dart';

/// Service for detecting wellness state from biometric data
///
/// Analyzes heart rate and accelerometer data to determine if user is
/// in CALM, STRESS, or CARDIO state with hysteresis filtering.
class WellnessStateService {
  final PhoneDataListener _phoneDataListener;

  // State detection thresholds
  static const int _stressHeartRateThreshold = 100; // BPM
  static const int _calmHeartRateThreshold = 90; // BPM
  static const double _lowMotionThreshold = 0.5; // m/s²
  static const double _highMotionThreshold = 2.0; // m/s²

  // Hysteresis durations (in seconds)
  static const int _calmToStressDuration = 30;
  static const int _cardioToStressDuration = 300; // 5 minutes
  static const int _cardioToCalmDuration = 120; // 2 minutes
  static const int _stressToCalmDuration = 60; // 1 minute

  // Data buffers
  final Queue<int> _heartRateBuffer = Queue();
  final Queue<double> _motionBuffer = Queue();
  static const int _heartRateBufferSize = 30; // 30 seconds
  static const int _motionBufferSize = 320; // 10 seconds at 32Hz

  // State management
  WellnessState _currentState = WellnessState.unknown;
  DateTime? _stateStartTime;
  DateTime? _lastCardioTime;
  final StreamController<WellnessStateData> _stateController =
      StreamController<WellnessStateData>.broadcast();

  // Subscriptions
  StreamSubscription<HeartRateData>? _hrSubscription;
  StreamSubscription<SensorBatch>? _sensorSubscription;
  Timer? _detectionTimer;

  bool _isMonitoring = false;

  WellnessStateService(this._phoneDataListener);

  /// Stream of wellness state changes
  Stream<WellnessStateData> get stateStream => _stateController.stream;

  /// Current wellness state
  WellnessState get currentState => _currentState;

  /// Whether monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Starts wellness monitoring
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    debugPrint('🏥 WellnessStateService: Starting monitoring...');
    _isMonitoring = true;
    _currentState = WellnessState.unknown;
    _stateStartTime = DateTime.now();

    // Subscribe to heart rate stream from PhoneDataListener (data comes from watch via phone)
    _hrSubscription = _phoneDataListener.heartRateStream.listen(
      (hrData) {
        if (hrData.bpm != null) {
          debugPrint(
            '💓 WellnessStateService: Received HR: ${hrData.bpm} BPM, adding to buffer (current size: ${_heartRateBuffer.length})',
          );
          _addHeartRateData(hrData.bpm!);
        } else {
          debugPrint(
            '⚠️ WellnessStateService: Received HR with null BPM, status: ${hrData.status}',
          );
        }
      },
      onError: (error) {
        debugPrint('❌ WellnessStateService: HR stream error: $error');
      },
    );

    // Subscribe to sensor batch stream from PhoneDataListener
    _sensorSubscription = _phoneDataListener.sensorBatchStream.listen(
      (batch) {
        debugPrint(
          '📊 WellnessStateService: Received sensor batch with ${batch.sampleCount} samples, adding to buffer (current size: ${_motionBuffer.length})',
        );
        _addSensorBatch(batch);
      },
      onError: (error) {
        debugPrint('❌ WellnessStateService: Sensor batch stream error: $error');
      },
    );

    // Run state detection every 5 seconds (not every second to reduce log spam)
    _detectionTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _detectState();
    });

    debugPrint('✅ WellnessStateService: Monitoring started successfully');
  }

  /// Stops wellness monitoring
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    await _hrSubscription?.cancel();
    await _sensorSubscription?.cancel();
    _detectionTimer?.cancel();

    _heartRateBuffer.clear();
    _motionBuffer.clear();
  }

  /// Adds heart rate data to buffer
  void _addHeartRateData(int bpm) {
    // Validate heart rate range
    if (bpm < 40 || bpm > 220) return;

    _heartRateBuffer.add(bpm);
    if (_heartRateBuffer.length > _heartRateBufferSize) {
      _heartRateBuffer.removeFirst();
    }
  }

  /// Adds sensor batch data to buffer
  void _addSensorBatch(SensorBatch batch) {
    for (final sample in batch.samples) {
      if (sample.length >= 3) {
        final accX = sample[0];
        final accY = sample[1];
        final accZ = sample[2];

        // Calculate motion magnitude
        final magnitude = _calculateMotionMagnitude(accX, accY, accZ);
        _motionBuffer.add(magnitude);

        if (_motionBuffer.length > _motionBufferSize) {
          _motionBuffer.removeFirst();
        }
      }
    }
  }

  /// Calculates motion magnitude from accelerometer data
  double _calculateMotionMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  /// Detects current wellness state
  void _detectState() {
    if (_heartRateBuffer.isEmpty || _motionBuffer.isEmpty) {
      debugPrint(
        '! WellnessStateService: Buffers empty - HR: ${_heartRateBuffer.length}, Motion: ${_motionBuffer.length}',
      );
      return;
    }

    // Calculate average heart rate
    final avgHeartRate =
        _heartRateBuffer.reduce((a, b) => a + b) / _heartRateBuffer.length;

    // Calculate average motion magnitude
    final avgMotion =
        _motionBuffer.reduce((a, b) => a + b) / _motionBuffer.length;

    debugPrint(
      '📈 WellnessStateService: Detection - HR: ${avgHeartRate.toStringAsFixed(1)} BPM, Motion: ${avgMotion.toStringAsFixed(2)} m/s², Current State: $_currentState',
    );

    // Determine new state based on rules
    final newState = _determineState(avgHeartRate.round(), avgMotion);

    // Apply hysteresis filter
    if (_shouldTransitionTo(newState)) {
      debugPrint(
        '🔄 WellnessStateService: State transition: $_currentState → $newState',
      );
      _transitionToState(newState, avgHeartRate.round(), avgMotion);
    }
  }

  /// Determines state based on heart rate and motion
  WellnessState _determineState(int heartRate, double motion) {
    // Priority 1: CARDIO (high HR + high motion)
    if (heartRate > _stressHeartRateThreshold &&
        motion > _highMotionThreshold) {
      return WellnessState.cardio;
    }

    // Priority 2: STRESS (high HR + low motion)
    if (heartRate > _stressHeartRateThreshold && motion < _lowMotionThreshold) {
      return WellnessState.stress;
    }

    // Priority 3: CALM (low HR)
    if (heartRate < _calmHeartRateThreshold) {
      return WellnessState.calm;
    }

    // Default: maintain current state
    return _currentState;
  }

  /// Checks if should transition to new state (hysteresis filter)
  bool _shouldTransitionTo(WellnessState newState) {
    if (newState == _currentState) return false;

    final now = DateTime.now();
    final timeInCurrentState = _stateStartTime != null
        ? now.difference(_stateStartTime!).inSeconds
        : 0;

    // Apply transition rules
    switch (_currentState) {
      case WellnessState.calm:
        if (newState == WellnessState.stress) {
          return timeInCurrentState >= _calmToStressDuration;
        }
        if (newState == WellnessState.cardio) {
          return true; // Immediate transition
        }
        break;

      case WellnessState.cardio:
        _lastCardioTime = now;
        if (newState == WellnessState.stress) {
          // Check if enough time passed since cardio
          final timeSinceCardio = _lastCardioTime != null
              ? now.difference(_lastCardioTime!).inSeconds
              : 0;
          return timeSinceCardio >= _cardioToStressDuration;
        }
        if (newState == WellnessState.calm) {
          return timeInCurrentState >= _cardioToCalmDuration;
        }
        break;

      case WellnessState.stress:
        if (newState == WellnessState.calm) {
          return timeInCurrentState >= _stressToCalmDuration;
        }
        if (newState == WellnessState.cardio) {
          return true; // Immediate transition
        }
        break;

      case WellnessState.unknown:
        return true; // Always transition from unknown
    }

    return false;
  }

  /// Transitions to new state
  void _transitionToState(
    WellnessState newState,
    int heartRate,
    double motion,
  ) {
    _currentState = newState;
    _stateStartTime = DateTime.now();

    final stateData = WellnessStateData(
      state: newState,
      timestamp: DateTime.now(),
      heartRate: heartRate,
      motionMagnitude: motion,
      confidence: _calculateConfidence(heartRate, motion),
    );

    _stateController.add(stateData);
  }

  /// Calculates confidence score for state detection
  double _calculateConfidence(int heartRate, double motion) {
    // Simple confidence calculation based on how clearly the data matches the state
    switch (_currentState) {
      case WellnessState.stress:
        // High confidence if HR is well above threshold and motion is well below
        final hrConfidence = (heartRate - _stressHeartRateThreshold) / 20.0;
        final motionConfidence =
            (_lowMotionThreshold - motion) / _lowMotionThreshold;
        return ((hrConfidence + motionConfidence) / 2).clamp(0.0, 1.0);

      case WellnessState.cardio:
        // High confidence if both HR and motion are well above thresholds
        final hrConfidence = (heartRate - _stressHeartRateThreshold) / 40.0;
        final motionConfidence = (motion - _highMotionThreshold) / 3.0;
        return ((hrConfidence + motionConfidence) / 2).clamp(0.0, 1.0);

      case WellnessState.calm:
        // High confidence if HR is well below threshold
        final hrConfidence = (_calmHeartRateThreshold - heartRate) / 20.0;
        return hrConfidence.clamp(0.0, 1.0);

      case WellnessState.unknown:
        return 0.0;
    }
  }

  /// Sets mock state for testing
  void setMockState(WellnessState state) {
    _transitionToState(state, 75, 0.3);
  }

  /// Disposes resources
  void dispose() {
    stopMonitoring();
    _stateController.close();
  }
}
