import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service for heart rate monitoring during workouts
class HeartRateService {
  StreamSubscription? _hrSubscription;
  final StreamController<int> _heartRateController =
      StreamController<int>.broadcast();

  int? _currentHeartRate;
  int? _maxHeartRate;
  final List<int> _heartRateHistory = [];
  final Map<String, int> _heartRateZones = {
    'zone1': 0, // 50-60% max HR
    'zone2': 0, // 60-70% max HR
    'zone3': 0, // 70-80% max HR
    'zone4': 0, // 80-90% max HR
    'zone5': 0, // 90-100% max HR
  };

  /// Stream of heart rate updates
  Stream<int> get heartRateStream => _heartRateController.stream;

  /// Current heart rate
  int? get currentHeartRate => _currentHeartRate;

  /// Maximum heart rate recorded
  int? get maxHeartRate => _maxHeartRate;

  /// Average heart rate
  int? get avgHeartRate {
    if (_heartRateHistory.isEmpty) return null;
    return _heartRateHistory.reduce((a, b) => a + b) ~/
        _heartRateHistory.length;
  }

  /// Heart rate zones (zone name -> seconds spent)
  Map<String, int> get heartRateZones => Map.from(_heartRateZones);

  /// Starts heart rate monitoring from smartwatch
  Future<void> startMonitoring() async {
    // Note: Heart rate data comes from PhoneDataListener
    // The running session provider should listen to PhoneDataListener.heartRateStream
    // and call _updateHeartRate() with the real BPM values

    // This service now acts as a data holder and calculator
    // Real heart rate updates come from the watch via PhoneDataListener
    debugPrint(
      '💓 HeartRateService: Ready to receive heart rate data from smartwatch',
    );
  }

  /// Stops heart rate monitoring
  Future<void> stopMonitoring() async {
    await _hrSubscription?.cancel();
    _hrSubscription = null;
  }

  /// Updates heart rate and calculates zones (called from external sources like PhoneDataListener)
  void updateHeartRate(int heartRate) {
    _currentHeartRate = heartRate;
    _heartRateHistory.add(heartRate);

    // Update max heart rate
    if (_maxHeartRate == null || heartRate > _maxHeartRate!) {
      _maxHeartRate = heartRate;
    }

    // Calculate zone (assuming max HR of 180 for now)
    const maxHR = 180;
    final zone = _calculateZone(heartRate, maxHR);
    _heartRateZones[zone] = (_heartRateZones[zone] ?? 0) + 1;

    _heartRateController.add(heartRate);
  }

  /// Calculates which heart rate zone the current HR falls into
  String _calculateZone(int heartRate, int maxHR) {
    final percentage = (heartRate / maxHR) * 100;

    if (percentage < 60) return 'zone1';
    if (percentage < 70) return 'zone2';
    if (percentage < 80) return 'zone3';
    if (percentage < 90) return 'zone4';
    return 'zone5';
  }

  /// Resets all heart rate data
  void reset() {
    _currentHeartRate = null;
    _maxHeartRate = null;
    _heartRateHistory.clear();
    _heartRateZones.updateAll((key, value) => 0);
  }

  /// Checks if heart rate monitor is available
  Future<bool> isAvailable() async {
    // TODO: Check if heart rate sensor is available
    return true; // Placeholder
  }

  /// Disposes resources
  void dispose() {
    _hrSubscription?.cancel();
    _heartRateController.close();
  }
}
