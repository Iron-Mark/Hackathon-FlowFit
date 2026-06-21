import 'dart:math';
import 'sensor_status.dart';

/// Enhanced TrackedData model matching Kotlin implementation
/// Includes HR, IBI, HRV, and SPO2 data
class TrackedData {
  final int hr; // Heart Rate (BPM)
  final List<int> ibiValues; // Inter-Beat Intervals (ms)
  final double hrv; // Heart Rate Variability (RMSSD in ms)
  final int spo2; // Blood Oxygen (%)
  final DateTime timestamp;
  final SensorStatus status;

  TrackedData({
    required this.hr,
    required this.ibiValues,
    required this.hrv,
    required this.spo2,
    required this.timestamp,
    required this.status,
  });

  /// Check if IBI data is available
  bool get hasIbiData => ibiValues.isNotEmpty;

  /// Get IBI display string
  String get ibiDisplay {
    if (!hasIbiData) return 'No IBI data';
    return ibiValues.take(5).map((ibi) => '${ibi}ms').join(', ');
  }

  /// Calculate HRV from IBI values (RMSSD algorithm)
  /// Same algorithm as Kotlin implementation
  static double calculateHRV(List<int> ibiList) {
    if (ibiList.length < 2) return 0.0;

    // Calculate RMSSD (Root Mean Square of Successive Differences)
    final differences = <double>[];
    for (int i = 0; i < ibiList.length - 1; i++) {
      final diff = ibiList[i + 1] - ibiList[i];
      differences.add(diff * diff.toDouble());
    }

    if (differences.isEmpty) return 0.0;

    final average = differences.reduce((a, b) => a + b) / differences.length;
    return sqrt(average);
  }

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'hr': hr,
      'ibi': ibiValues,
      'hrv': hrv,
      'spo2': spo2,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  /// Create from JSON (from Kotlin watch or database)
  factory TrackedData.fromJson(Map<String, dynamic> json) {
    // Parse IBI values
    final ibiList = json['ibi'] ?? json['ibiValues'] ?? [];
    final List<int> parsedIbiValues = ibiList is List
        ? ibiList
              .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
              .toList()
        : [];

    // Parse status
    final statusValue = json['status'];
    final SensorStatus parsedStatus = statusValue is String
        ? SensorStatus.values.firstWhere(
            (e) => e.name == statusValue,
            orElse: () => SensorStatus.active,
          )
        : SensorStatus.active;

    // Parse HRV (might be sent from watch or calculate locally)
    double parsedHrv = 0.0;
    if (json['hrv'] != null) {
      parsedHrv = (json['hrv'] is double)
          ? json['hrv']
          : double.tryParse(json['hrv'].toString()) ?? 0.0;
    } else if (parsedIbiValues.length >= 2) {
      // Calculate HRV if not provided
      parsedHrv = calculateHRV(parsedIbiValues);
    }

    return TrackedData(
      hr: json['hr'] ?? 0,
      ibiValues: parsedIbiValues,
      hrv: parsedHrv,
      spo2: json['spo2'] ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      status: parsedStatus,
    );
  }

  /// Convert to database map (for SQLite)
  Map<String, dynamic> toDatabaseMap() {
    return {
      'hr': hr,
      'ibi_values': ibiValues.join(','), // Store as comma-separated string
      'hrv': hrv,
      'spo2': spo2,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  /// Create from database map
  factory TrackedData.fromDatabaseMap(Map<String, dynamic> map) {
    // Parse IBI values from comma-separated string
    final ibiString = map['ibi_values'] as String? ?? '';
    final List<int> ibiValues = ibiString.isEmpty
        ? []
        : ibiString.split(',').map((e) => int.tryParse(e) ?? 0).toList();

    return TrackedData(
      hr: map['hr'] as int,
      ibiValues: ibiValues,
      hrv: map['hrv'] as double,
      spo2: map['spo2'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      status: SensorStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SensorStatus.active,
      ),
    );
  }

  /// Create a copy with updated values
  TrackedData copyWith({
    int? hr,
    List<int>? ibiValues,
    double? hrv,
    int? spo2,
    DateTime? timestamp,
    SensorStatus? status,
  }) {
    return TrackedData(
      hr: hr ?? this.hr,
      ibiValues: ibiValues ?? this.ibiValues,
      hrv: hrv ?? this.hrv,
      spo2: spo2 ?? this.spo2,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'TrackedData(hr: $hr, ibiCount: ${ibiValues.length}, hrv: ${hrv.toStringAsFixed(1)}, spo2: $spo2, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackedData &&
        other.hr == hr &&
        other.hrv == hrv &&
        other.spo2 == spo2 &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(hr, hrv, spo2, timestamp);
  }
}

/// Rolling IBI History Manager
/// Maintains a rolling window of IBI values for stable HRV calculation
/// Matches Kotlin implementation behavior
class IbiHistoryManager {
  final List<int> _ibiHistory = [];
  final int maxHistorySize;

  IbiHistoryManager({this.maxHistorySize = 10});

  /// Add new IBI values to history
  void addIbiValues(List<int> newValues) {
    _ibiHistory.addAll(newValues);

    // Keep only last N values
    while (_ibiHistory.length > maxHistorySize) {
      _ibiHistory.removeAt(0);
    }
  }

  /// Get current IBI history
  List<int> get history => List.unmodifiable(_ibiHistory);

  /// Calculate HRV from current history
  double calculateHRV() {
    return TrackedData.calculateHRV(_ibiHistory);
  }

  /// Check if enough data for HRV calculation
  bool get hasEnoughData => _ibiHistory.length >= 2;

  /// Clear history
  void clear() {
    _ibiHistory.clear();
  }

  /// Get history size
  int get size => _ibiHistory.length;
}
