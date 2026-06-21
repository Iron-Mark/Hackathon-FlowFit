/// Domain entity for heart rate data
///
/// This is the core business model, independent of any framework or data source.
class HeartRateData {
  final int? bpm;
  final List<int> ibiValues;
  final DateTime timestamp;
  final HeartRateStatus status;

  const HeartRateData({
    required this.bpm,
    required this.ibiValues,
    required this.timestamp,
    required this.status,
  });

  /// Create from JSON (from watch or API)
  factory HeartRateData.fromJson(Map<String, dynamic> json) {
    return HeartRateData(
      bpm: json['bpm'] as int?,
      ibiValues:
          (json['ibiValues'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      timestamp: json['timestamp'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.parse(json['timestamp'] as String),
      status: HeartRateStatus.fromString(
        json['status'] as String? ?? 'inactive',
      ),
    );
  }

  /// Convert to JSON (for API or storage)
  Map<String, dynamic> toJson() {
    return {
      'bpm': bpm,
      'ibiValues': ibiValues,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  /// Copy with modifications
  HeartRateData copyWith({
    int? bpm,
    List<int>? ibiValues,
    DateTime? timestamp,
    HeartRateStatus? status,
  }) {
    return HeartRateData(
      bpm: bpm ?? this.bpm,
      ibiValues: ibiValues ?? this.ibiValues,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'HeartRateData(bpm: $bpm, ibiCount: ${ibiValues.length}, status: ${status.name})';
  }
}

/// Heart rate status enum
enum HeartRateStatus {
  active,
  inactive,
  error;

  static HeartRateStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return HeartRateStatus.active;
      case 'inactive':
        return HeartRateStatus.inactive;
      case 'error':
        return HeartRateStatus.error;
      default:
        return HeartRateStatus.inactive;
    }
  }
}
