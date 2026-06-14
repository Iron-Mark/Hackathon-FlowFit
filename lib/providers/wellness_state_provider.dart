import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wellness_state.dart';
import '../models/state_transition.dart';
import '../services/wellness_state_service.dart';
import '../services/watch_bridge.dart';
import '../services/phone_data_listener.dart';

/// Provider for WatchBridgeService (singleton)
final watchBridgeServiceProvider = Provider<WatchBridgeService>((ref) {
  return WatchBridgeService();
});

/// Provider for PhoneDataListener (singleton)
final phoneDataListenerServiceProvider = Provider<PhoneDataListener>((ref) {
  return PhoneDataListener();
});

/// Provider for WellnessStateService
final wellnessStateServiceProvider = Provider<WellnessStateService>((ref) {
  final phoneDataListener = ref.watch(phoneDataListenerServiceProvider);
  return WellnessStateService(phoneDataListener);
});

/// State notifier for wellness state management
class WellnessStateNotifier extends StateNotifier<WellnessStateData> {
  final WellnessStateService _service;
  final SharedPreferences _prefs;

  StreamSubscription<WellnessStateData>? _stateSubscription;
  final List<WellnessStateData> _history = [];
  final List<StateTransition> _transitions = [];

  static const String _historyKey = 'wellness_history';
  static const String _transitionsKey = 'wellness_transitions';
  static const int _maxHistoryHours = 24;

  WellnessStateNotifier(this._service, this._prefs)
    : super(
        WellnessStateData(
          state: WellnessState.unknown,
          timestamp: DateTime.now(),
        ),
      ) {
    _loadHistory();
    _subscribeToStateChanges();
  }

  /// Loads history from persistent storage
  Future<void> _loadHistory() async {
    try {
      final historyJson = _prefs.getStringList(_historyKey) ?? [];
      _history.clear();
      for (final json in historyJson) {
        try {
          final data = WellnessStateData.fromJson(
            Map<String, dynamic>.from(
              Uri.splitQueryString(json).map((k, v) => MapEntry(k, v)),
            ),
          );
          _history.add(data);
        } catch (e) {
          // Skip invalid entries
        }
      }

      final transitionsJson = _prefs.getStringList(_transitionsKey) ?? [];
      _transitions.clear();
      for (final json in transitionsJson) {
        try {
          final transition = StateTransition.fromJson(
            Map<String, dynamic>.from(
              Uri.splitQueryString(json).map((k, v) => MapEntry(k, v)),
            ),
          );
          _transitions.add(transition);
        } catch (e) {
          // Skip invalid entries
        }
      }
    } catch (e) {
      // Ignore load errors
    }
  }

  /// Saves history to persistent storage
  Future<void> _saveHistory() async {
    try {
      final historyJson = _history
          .map((data) => data.toJson().toString())
          .toList();
      await _prefs.setStringList(_historyKey, historyJson);

      final transitionsJson = _transitions
          .map((t) => t.toJson().toString())
          .toList();
      await _prefs.setStringList(_transitionsKey, transitionsJson);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Subscribes to state changes from service
  void _subscribeToStateChanges() {
    debugPrint('🎧 WellnessStateNotifier: Subscribing to state stream...');
    _stateSubscription = _service.stateStream.listen((newState) {
      debugPrint(
        '📨 WellnessStateNotifier: Received new state: ${newState.state.displayName}, HR: ${newState.heartRate}, Motion: ${newState.motionMagnitude}',
      );

      // Track transition
      if (state.state != newState.state) {
        debugPrint(
          '🔄 WellnessStateNotifier: State transition: ${state.state.displayName} → ${newState.state.displayName}',
        );
        final transition = StateTransition(
          fromState: state.state,
          toState: newState.state,
          timestamp: newState.timestamp,
          duration: newState.timestamp.difference(state.timestamp),
        );
        _transitions.add(transition);
      }

      // Update current state
      state = newState;
      debugPrint(
        '✅ WellnessStateNotifier: State updated to: ${state.state.displayName}',
      );

      // Add to history
      _history.add(newState);
      _pruneOldHistory();

      // Save to storage
      _saveHistory();
    });
  }

  /// Removes history older than 24 hours
  void _pruneOldHistory() {
    final cutoff = DateTime.now().subtract(
      const Duration(hours: _maxHistoryHours),
    );
    _history.removeWhere((data) => data.timestamp.isBefore(cutoff));
    _transitions.removeWhere((t) => t.timestamp.isBefore(cutoff));
  }

  /// Gets current wellness state
  WellnessStateData getCurrentState() => state;

  /// Gets state history for the last 24 hours
  List<WellnessStateData> getStateHistory() => List.unmodifiable(_history);

  /// Gets state transitions
  List<StateTransition> getTransitions() => List.unmodifiable(_transitions);

  /// Clears all history
  Future<void> clearHistory() async {
    _history.clear();
    _transitions.clear();
    await _prefs.remove(_historyKey);
    await _prefs.remove(_transitionsKey);
  }

  /// Gets duration in each state today
  Map<WellnessState, Duration> getTodayDurations() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final durations = <WellnessState, Duration>{
      WellnessState.calm: Duration.zero,
      WellnessState.stress: Duration.zero,
      WellnessState.cardio: Duration.zero,
    };

    for (int i = 0; i < _history.length - 1; i++) {
      final current = _history[i];
      final next = _history[i + 1];

      if (current.timestamp.isAfter(startOfDay)) {
        final duration = next.timestamp.difference(current.timestamp);
        durations[current.state] =
            (durations[current.state] ?? Duration.zero) + duration;
      }
    }

    return durations;
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for wellness state notifier
final wellnessStateProvider =
    StateNotifierProvider<WellnessStateNotifier, WellnessStateData>((ref) {
      final service = ref.watch(wellnessStateServiceProvider);
      final prefs = ref.watch(sharedPreferencesProvider);
      return WellnessStateNotifier(service, prefs);
    });

/// Provider for wellness history
final wellnessHistoryProvider = Provider<List<WellnessStateData>>((ref) {
  final notifier = ref.watch(wellnessStateProvider.notifier);
  return notifier.getStateHistory();
});

/// Provider for today's wellness durations
final todayDurationsProvider = Provider<Map<WellnessState, Duration>>((ref) {
  ref.watch(wellnessStateProvider); // Rebuild when state changes
  final notifier = ref.read(wellnessStateProvider.notifier);
  return notifier.getTodayDurations();
});

/// Provider for SharedPreferences (must be initialized in main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});
