/// Model for storing individual AI activity mode detection records
///
/// Each detection represents a single AI classification result
/// captured during a workout session.
class ActivityModeDetection {
  /// Timestamp when detection was performed
  final DateTime timestamp;

  /// Detected activity mode ('Stress', 'Cardio', or 'Strength')
  final String mode;

  /// Confidence level of the detection (0.0 to 1.0)
  final double confidence;

  /// Probability breakdown for all modes [stress, cardio, strength]
  final List<double> probabilities;

  /// Heart rate at time of detection (optional)
  final int? heartRate;

  ActivityModeDetection({
    required this.timestamp,
    required this.mode,
    required this.confidence,
    required this.probabilities,
    this.heartRate,
  });

  /// Converts detection to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'mode': mode,
      'confidence': confidence,
      'probabilities': probabilities,
      if (heartRate != null) 'heart_rate': heartRate,
    };
  }

  /// Creates detection from JSON
  factory ActivityModeDetection.fromJson(Map<String, dynamic> json) {
    return ActivityModeDetection(
      timestamp: DateTime.parse(json['timestamp'] as String),
      mode: json['mode'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      probabilities: (json['probabilities'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      heartRate: json['heart_rate'] as int?,
    );
  }

  /// Creates a copy with updated fields
  ActivityModeDetection copyWith({
    DateTime? timestamp,
    String? mode,
    double? confidence,
    List<double>? probabilities,
    int? heartRate,
  }) {
    return ActivityModeDetection(
      timestamp: timestamp ?? this.timestamp,
      mode: mode ?? this.mode,
      confidence: confidence ?? this.confidence,
      probabilities: probabilities ?? this.probabilities,
      heartRate: heartRate ?? this.heartRate,
    );
  }

  @override
  String toString() {
    return 'ActivityModeDetection(timestamp: $timestamp, mode: $mode, confidence: ${(confidence * 100).toStringAsFixed(1)}%, heartRate: $heartRate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ActivityModeDetection &&
        other.timestamp == timestamp &&
        other.mode == mode &&
        other.confidence == confidence &&
        other.heartRate == heartRate;
  }

  @override
  int get hashCode {
    return timestamp.hashCode ^
        mode.hashCode ^
        confidence.hashCode ^
        heartRate.hashCode;
  }
}
