/// Domain entity representing a single heart rate measurement point
class HeartRatePoint {
  final DateTime timestamp;
  final int bpm;
  final List<int> ibiValues;

  const HeartRatePoint({
    required this.timestamp,
    required this.bpm,
    required this.ibiValues,
  });

  HeartRatePoint copyWith({
    DateTime? timestamp,
    int? bpm,
    List<int>? ibiValues,
  }) {
    return HeartRatePoint(
      timestamp: timestamp ?? this.timestamp,
      bpm: bpm ?? this.bpm,
      ibiValues: ibiValues ?? this.ibiValues,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HeartRatePoint &&
        other.timestamp == timestamp &&
        other.bpm == bpm &&
        _listEquals(other.ibiValues, ibiValues);
  }

  @override
  int get hashCode {
    return Object.hash(timestamp, bpm, Object.hashAll(ibiValues));
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
