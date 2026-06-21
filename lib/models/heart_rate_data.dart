import 'sensor_status.dart';

class HeartRateData {
  final int? bpm; // Nullable since it might not be available during measurement
  final DateTime timestamp;
  final SensorStatus status;
  final List<int> ibiValues; // Inter-beat interval values in milliseconds

  HeartRateData({
    this.bpm,
    required this.timestamp,
    required this.status,
    this.ibiValues = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'bpm': bpm,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.toJson(),
      'ibiValues': ibiValues,
    };
  }

  factory HeartRateData.fromJson(Map<String, dynamic> json) {
    // Handle status as either String or SensorStatus
    final statusValue = json['status'];
    final SensorStatus parsedStatus;

    if (statusValue is String) {
      parsedStatus = SensorStatus.fromJson(statusValue);
    } else {
      parsedStatus = SensorStatus.active;
    }

    // Parse IBI values
    final ibiList = json['ibiValues'];
    final List<int> parsedIbiValues;
    if (ibiList is List) {
      parsedIbiValues = ibiList.cast<int>();
    } else {
      parsedIbiValues = [];
    }

    return HeartRateData(
      bpm: json['bpm'] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      status: parsedStatus,
      ibiValues: parsedIbiValues,
    );
  }

  @override
  String toString() {
    return 'HeartRateData(bpm: $bpm, timestamp: $timestamp, status: ${status.name}, ibiCount: ${ibiValues.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HeartRateData &&
        other.bpm == bpm &&
        other.timestamp == timestamp &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(bpm, timestamp, status);
  }
}
