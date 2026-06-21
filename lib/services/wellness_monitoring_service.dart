import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'wellness_state_service.dart';
import '../models/wellness_state.dart';

/// Background service for wellness monitoring lifecycle management
///
/// Manages the lifecycle of wellness monitoring across app states:
/// - Starts monitoring when user enables it
/// - Persists across page navigation
/// - Reduces sampling rate when app is backgrounded
/// - Stops monitoring on explicit user disable or app termination
class WellnessMonitoringService {
  final WellnessStateService _wellnessStateService;
  final SharedPreferences _prefs;

  static const String _monitoringEnabledKey = 'wellness_monitoring_enabled';
  static const String _lastMonitoringStateKey =
      'wellness_last_monitoring_state';

  bool _isMonitoring = false;
  StreamSubscription<WellnessStateData>? _stateSubscription;

  WellnessMonitoringService(this._wellnessStateService, this._prefs);

  /// Whether monitoring is currently active
  bool get isMonitoring => _isMonitoring;

  /// Whether monitoring is enabled by user
  bool get isEnabled => _prefs.getBool(_monitoringEnabledKey) ?? false;

  /// Initialize monitoring service and restore previous state
  Future<void> initialize() async {
    // Restore monitoring state if it was enabled
    if (isEnabled) {
      await startMonitoring();
    }
  }

  /// Start wellness monitoring
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    try {
      await _wellnessStateService.startMonitoring();
      _isMonitoring = true;

      // Save monitoring state
      await _prefs.setBool(_monitoringEnabledKey, true);
      await _prefs.setString(
        _lastMonitoringStateKey,
        DateTime.now().toIso8601String(),
      );

      // Subscribe to state changes for logging
      _stateSubscription = _wellnessStateService.stateStream.listen((state) {
        _handleStateChange(state);
      });
    } catch (e) {
      _isMonitoring = false;
      rethrow;
    }
  }

  /// Stop wellness monitoring
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    await _wellnessStateService.stopMonitoring();
    await _stateSubscription?.cancel();
    _stateSubscription = null;
    _isMonitoring = false;

    // Save monitoring state
    await _prefs.setBool(_monitoringEnabledKey, false);
  }

  /// Enable monitoring (user preference)
  Future<void> enableMonitoring() async {
    try {
      await startMonitoring();
    } catch (_) {
      await _prefs.setBool(_monitoringEnabledKey, false);
      rethrow;
    }
  }

  /// Disable monitoring (user preference)
  Future<void> disableMonitoring() async {
    await stopMonitoring();
    await _prefs.setBool(_monitoringEnabledKey, false);
  }

  /// Handle app lifecycle changes
  Future<void> onAppLifecycleStateChanged(bool isBackground) async {
    if (isBackground) {
      // App is backgrounded - reduce sampling rate for battery optimization
      // The native sensors will continue running but we process less frequently
      await _handleBackgrounded();
    } else {
      // App is foregrounded - restore normal sampling rate
      await _handleForegrounded();
    }
  }

  /// Handle app being backgrounded
  Future<void> _handleBackgrounded() async {
    // Monitoring continues but with reduced processing
    // The WellnessStateService will continue to buffer data
    // but we can reduce the frequency of state detection
  }

  /// Handle app being foregrounded
  Future<void> _handleForegrounded() async {
    // Restore normal monitoring if it was enabled
    if (isEnabled && !_isMonitoring) {
      await startMonitoring();
    }
  }

  /// Handle state changes for logging and analytics
  void _handleStateChange(WellnessStateData state) {
    // Log state changes for debugging
    // This can be extended to send analytics events
  }

  /// Get monitoring duration today
  Duration getMonitoringDurationToday() {
    final lastStateStr = _prefs.getString(_lastMonitoringStateKey);
    if (lastStateStr == null) return Duration.zero;

    try {
      final lastState = DateTime.parse(lastStateStr);
      final now = DateTime.now();

      // Check if it's the same day
      if (lastState.year == now.year &&
          lastState.month == now.month &&
          lastState.day == now.day) {
        return now.difference(lastState);
      }
    } catch (e) {
      // Invalid date format
    }

    return Duration.zero;
  }

  /// Dispose resources
  void dispose() {
    _stateSubscription?.cancel();
  }
}
