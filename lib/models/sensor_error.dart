import 'package:flowfit/models/sensor_error_code.dart';

class SensorError {
  final SensorErrorCode code;
  final String message;
  final String? details;
  final DateTime timestamp;

  SensorError({
    required this.code,
    required this.message,
    this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'code': code.toJson(),
      'message': message,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SensorError.fromJson(Map<String, dynamic> json) {
    return SensorError(
      code: SensorErrorCode.fromJson(json['code'] as String),
      message: json['message'] as String,
      details: json['details'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('SensorError(');
    buffer.write('code: ${code.name}, ');
    buffer.write('message: $message');
    if (details != null) {
      buffer.write(', details: $details');
    }
    buffer.write(', timestamp: $timestamp');
    buffer.write(')');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SensorError &&
        other.code == code &&
        other.message == message &&
        other.details == details &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(code, message, details, timestamp);
  }
}
