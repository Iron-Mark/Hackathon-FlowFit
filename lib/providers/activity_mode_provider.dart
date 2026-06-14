import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../features/activity_classifier/platform/tflite_activity_classifier.dart';

/// Activity mode detected by the model
enum ActivityMode {
  stress,
  cardio,
  calm, // Renamed from "strength" to "calm" for better UX
}

/// State for activity mode detection
class ActivityModeState {
  final ActivityMode? currentMode;
  final double? confidence;
  final bool isDetecting;
  final String? error;
  final List<double>? probabilities; // [stress, cardio, calm]

  ActivityModeState({
    this.currentMode,
    this.confidence,
    this.isDetecting = false,
    this.error,
    this.probabilities,
  });

  ActivityModeState copyWith({
    ActivityMode? currentMode,
    double? confidence,
    bool? isDetecting,
    String? error,
    List<double>? probabilities,
  }) {
    return ActivityModeState(
      currentMode: currentMode ?? this.currentMode,
      confidence: confidence ?? this.confidence,
      isDetecting: isDetecting ?? this.isDetecting,
      error: error,
      probabilities: probabilities ?? this.probabilities,
    );
  }
}

/// Provider for activity mode detection using TensorFlow Lite
class ActivityModeNotifier extends StateNotifier<ActivityModeState> {
  final TFLiteActivityClassifier _classifier;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  List<List<double>> _sensorBuffer = [];
  int? _currentHeartRate;
  Timer? _detectionTimer;
  bool _isContinuousMode = false;

  ActivityModeNotifier(this._classifier) : super(ActivityModeState());

  /// Start continuous activity mode detection
  /// Automatically runs inference every 15 seconds
  Future<void> startContinuousDetection({int? heartRate}) async {
    if (_isContinuousMode) return;

    _isContinuousMode = true;
    _currentHeartRate = heartRate ?? 75;
    _sensorBuffer = [];

    try {
      // Load model if not already loaded
      if (!_classifier.isLoaded) {
        await _classifier.loadModel();
      }

      // Start collecting accelerometer data
      _accelSubscription = accelerometerEventStream().listen((event) {
        _addSensorData(event);
      });

      // Run first detection after 10 seconds
      _scheduleNextDetection(10);
    } catch (e) {
      state = ActivityModeState(
        isDetecting: false,
        error: 'Failed to start detection: $e',
      );
      _isContinuousMode = false;
    }
  }

  /// Schedule next detection
  void _scheduleNextDetection(int seconds) {
    _detectionTimer?.cancel();
    _detectionTimer = Timer(Duration(seconds: seconds), () {
      if (_isContinuousMode) {
        _runDetection();
      }
    });
  }

  /// Start detecting activity mode (single detection)
  /// Collects sensor data for 10 seconds then runs inference
  Future<void> startDetection({int? heartRate}) async {
    if (state.isDetecting) return;

    state = ActivityModeState(isDetecting: true);
    _currentHeartRate = heartRate ?? 75; // Default HR if not available
    _sensorBuffer = [];

    try {
      // Load model if not already loaded
      if (!_classifier.isLoaded) {
        await _classifier.loadModel();
      }

      // Start collecting accelerometer data
      _accelSubscription = accelerometerEventStream().listen((event) {
        _addSensorData(event);
      });

      // Run detection after 10 seconds of data collection
      _detectionTimer = Timer(const Duration(seconds: 10), () {
        _runDetection();
      });
    } catch (e) {
      state = ActivityModeState(
        isDetecting: false,
        error: 'Failed to start detection: $e',
      );
    }
  }

  /// Add sensor data to buffer
  void _addSensorData(AccelerometerEvent event) {
    // Add [accX, accY, accZ, bpm] to buffer
    _sensorBuffer.add([
      event.x,
      event.y,
      event.z,
      _currentHeartRate?.toDouble() ?? 75.0,
    ]);

    // Keep only last 320 samples (model input size)
    if (_sensorBuffer.length > 320) {
      _sensorBuffer = _sensorBuffer.sublist(_sensorBuffer.length - 320);
    }
  }

  /// Run TensorFlow Lite inference
  Future<void> _runDetection() async {
    if (_sensorBuffer.length < 320) {
      // Not enough data yet, schedule retry
      if (_isContinuousMode) {
        _scheduleNextDetection(5);
      } else {
        state = ActivityModeState(
          isDetecting: false,
          error:
              'Not enough sensor data collected (${_sensorBuffer.length}/320)',
        );
      }
      return;
    }

    try {
      // Run model inference
      final probabilities = await _classifier.predict(_sensorBuffer);

      // Find the mode with highest probability
      final maxIndex = probabilities.indexOf(
        probabilities.reduce((a, b) => a > b ? a : b),
      );

      final mode = ActivityMode.values[maxIndex];
      final confidence = probabilities[maxIndex];

      state = ActivityModeState(
        currentMode: mode,
        confidence: confidence,
        isDetecting: false,
        probabilities: probabilities,
      );

      // Schedule next detection in continuous mode
      if (_isContinuousMode) {
        _scheduleNextDetection(15); // Run every 15 seconds
      }
    } catch (e) {
      state = ActivityModeState(
        isDetecting: false,
        error: 'Detection failed: $e',
      );

      // Retry in continuous mode
      if (_isContinuousMode) {
        _scheduleNextDetection(10);
      }
    }
  }

  /// Stop detection
  void stopDetection() {
    _isContinuousMode = false;
    _accelSubscription?.cancel();
    _detectionTimer?.cancel();
    _sensorBuffer = [];
    state = ActivityModeState();
  }

  /// Update heart rate for next detection
  void updateHeartRate(int heartRate) {
    _currentHeartRate = heartRate;
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    _detectionTimer?.cancel();
    super.dispose();
  }
}

/// Provider for activity mode detection
/// Note: This uses a separate TFLite classifier instance for real-time detection
/// The main app's classifier is used for the activity tracking feature
final activityModeProvider =
    StateNotifierProvider<ActivityModeNotifier, ActivityModeState>((ref) {
      // Create a dedicated classifier instance for continuous mode detection
      final classifier = TFLiteActivityClassifier();
      return ActivityModeNotifier(classifier);
    });
