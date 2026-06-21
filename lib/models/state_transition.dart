import 'wellness_state.dart';

/// State transition model for tracking wellness state changes
class StateTransition {
  final WellnessState fromState;
  final WellnessState toState;
  final DateTime timestamp;
  final Duration duration; // How long in previous state
  final String? trigger; // What triggered the transition

  StateTransition({
    required this.fromState,
    required this.toState,
    required this.timestamp,
    required this.duration,
    this.trigger,
  });

  /// Whether this is a significant transition (not to/from unknown)
  bool get isSignificant {
    return fromState != WellnessState.unknown &&
        toState != WellnessState.unknown;
  }

  /// Whether this transition indicates improvement
  bool get isImprovement {
    // Stress → Calm or Cardio is improvement
    if (fromState == WellnessState.stress) {
      return toState == WellnessState.calm || toState == WellnessState.cardio;
    }
    // Cardio → Calm is natural cooldown
    if (fromState == WellnessState.cardio && toState == WellnessState.calm) {
      return true;
    }
    return false;
  }

  /// Whether this transition indicates concern
  bool get isConcerning {
    // Calm → Stress is concerning
    if (fromState == WellnessState.calm && toState == WellnessState.stress) {
      return true;
    }
    // Cardio → Stress might indicate overexertion
    if (fromState == WellnessState.cardio && toState == WellnessState.stress) {
      return true;
    }
    return false;
  }

  /// Human-readable description
  String get description {
    return '${fromState.displayName} → ${toState.displayName}';
  }

  /// Creates a copy with updated fields
  StateTransition copyWith({
    WellnessState? fromState,
    WellnessState? toState,
    DateTime? timestamp,
    Duration? duration,
    String? trigger,
  }) {
    return StateTransition(
      fromState: fromState ?? this.fromState,
      toState: toState ?? this.toState,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      trigger: trigger ?? this.trigger,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'from_state': fromState.name,
      'to_state': toState.name,
      'timestamp': timestamp.toIso8601String(),
      'duration_seconds': duration.inSeconds,
      if (trigger != null) 'trigger': trigger,
    };
  }

  /// Creates from JSON
  factory StateTransition.fromJson(Map<String, dynamic> json) {
    return StateTransition(
      fromState: WellnessState.values.byName(json['from_state'] as String),
      toState: WellnessState.values.byName(json['to_state'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      duration: Duration(seconds: json['duration_seconds'] as int),
      trigger: json['trigger'] as String?,
    );
  }

  @override
  String toString() {
    return 'StateTransition($description at ${timestamp.toIso8601String()}, duration: ${duration.inMinutes}min)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StateTransition &&
        other.fromState == fromState &&
        other.toState == toState &&
        other.timestamp == timestamp &&
        other.duration == duration &&
        other.trigger == trigger;
  }

  @override
  int get hashCode {
    return Object.hash(fromState, toState, timestamp, duration, trigger);
  }
}
