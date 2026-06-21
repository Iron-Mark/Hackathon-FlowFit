/// Wellness state enumeration
enum WellnessState {
  calm,
  stress,
  cardio,
  unknown;

  String get displayName {
    switch (this) {
      case WellnessState.calm:
        return 'Calm';
      case WellnessState.stress:
        return 'Stress';
      case WellnessState.cardio:
        return 'Cardio';
      case WellnessState.unknown:
        return 'Unknown';
    }
  }

  String get emoji {
    switch (this) {
      case WellnessState.calm:
        return '😌';
      case WellnessState.stress:
        return '😰';
      case WellnessState.cardio:
        return '💪';
      case WellnessState.unknown:
        return '❓';
    }
  }

  String get description {
    switch (this) {
      case WellnessState.calm:
        return 'Relaxed and at ease';
      case WellnessState.stress:
        return 'Elevated stress detected';
      case WellnessState.cardio:
        return 'Active exercise detected';
      case WellnessState.unknown:
        return 'Analyzing...';
    }
  }
}

/// Wellness state data with metrics
class WellnessStateData {
  final WellnessState state;
  final DateTime timestamp;
  final int? heartRate;
  final double? motionMagnitude;
  final double confidence;

  WellnessStateData({
    required this.state,
    required this.timestamp,
    this.heartRate,
    this.motionMagnitude,
    this.confidence = 1.0,
  }) : assert(
         confidence >= 0.0 && confidence <= 1.0,
         'Confidence must be between 0 and 1',
       );

  /// Creates a copy with updated fields
  WellnessStateData copyWith({
    WellnessState? state,
    DateTime? timestamp,
    int? heartRate,
    double? motionMagnitude,
    double? confidence,
  }) {
    return WellnessStateData(
      state: state ?? this.state,
      timestamp: timestamp ?? this.timestamp,
      heartRate: heartRate ?? this.heartRate,
      motionMagnitude: motionMagnitude ?? this.motionMagnitude,
      confidence: confidence ?? this.confidence,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'state': state.name,
      'timestamp': timestamp.toIso8601String(),
      if (heartRate != null) 'heart_rate': heartRate,
      if (motionMagnitude != null) 'motion_magnitude': motionMagnitude,
      'confidence': confidence,
    };
  }

  /// Creates from JSON
  factory WellnessStateData.fromJson(Map<String, dynamic> json) {
    return WellnessStateData(
      state: WellnessState.values.byName(json['state'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      heartRate: json['heart_rate'] as int?,
      motionMagnitude: (json['motion_magnitude'] as num?)?.toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  String toString() {
    return 'WellnessStateData(state: ${state.displayName}, HR: $heartRate, motion: ${motionMagnitude?.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WellnessStateData &&
        other.state == state &&
        other.timestamp == timestamp &&
        other.heartRate == heartRate &&
        other.motionMagnitude == motionMagnitude &&
        other.confidence == confidence;
  }

  @override
  int get hashCode {
    return Object.hash(
      state,
      timestamp,
      heartRate,
      motionMagnitude,
      confidence,
    );
  }
}
