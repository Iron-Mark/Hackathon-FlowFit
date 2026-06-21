/// Model representing a batch of sensor data from the watch
/// Contains accelerometer samples combined with heart rate data
///
/// Each sample in the batch is a 4-feature vector: [accX, accY, accZ, bpm]
/// This format is ready for input to the AI activity classification model.
class SensorBatch {
  /// List of 4-feature vectors [accX, accY, accZ, bpm]
  final List<List<double>> samples;

  /// Timestamp when the batch was created (milliseconds since epoch)
  final int timestamp;

  /// Number of samples in the batch
  int get sampleCount => samples.length;

  SensorBatch({required this.samples, required this.timestamp});

  /// Create SensorBatch from JSON received from watch
  ///
  /// Expected JSON format (accepts both snake_case and camelCase):
  /// {
  ///   "type": "sensor_batch",
  ///   "timestamp": 1234567890,
  ///   "bpm": 75,
  ///   "sampleRate": 32,  // or "sample_rate": 32
  ///   "count": 32,
  ///   "accelerometer": [[0.12, -0.45, 9.81], [0.15, -0.42, 9.79], ...]
  /// }
  factory SensorBatch.fromJson(Map<String, dynamic> json) {
    final bpm = (json['bpm'] as num).toDouble();
    final timestamp = json['timestamp'] as int;
    final accelData = json['accelerometer'] as List;

    // Construct 4-feature vectors by combining each accelerometer triplet with BPM
    final samples = accelData.map((xyz) {
      final triplet = xyz as List;
      return [
        (triplet[0] as num).toDouble(), // accX
        (triplet[1] as num).toDouble(), // accY
        (triplet[2] as num).toDouble(), // accZ
        bpm, // bpm
      ];
    }).toList();

    return SensorBatch(samples: samples, timestamp: timestamp);
  }

  /// Convert to JSON format
  Map<String, dynamic> toJson() {
    // Extract BPM from first sample (all samples have same BPM)
    final bpm = samples.isNotEmpty ? samples[0][3].toInt() : 0;

    // Extract accelerometer triplets
    final accelerometer = samples.map((sample) {
      return [sample[0], sample[1], sample[2]];
    }).toList();

    return {
      'type': 'sensor_batch',
      'timestamp': timestamp,
      'bpm': bpm,
      'sample_rate': 32,
      'count': samples.length,
      'accelerometer': accelerometer,
    };
  }

  @override
  String toString() {
    return 'SensorBatch(sampleCount: $sampleCount, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SensorBatch &&
        other.timestamp == timestamp &&
        other.sampleCount == sampleCount;
  }

  @override
  int get hashCode {
    return Object.hash(timestamp, sampleCount);
  }
}
