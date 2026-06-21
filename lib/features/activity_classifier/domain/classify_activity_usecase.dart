import '../domain/activity.dart';

/// Use case: Classify sensor buffer into an activity type
/// Pure business logic, no platform dependencies
class ClassifyActivityUseCase {
  final ActivityClassifierRepository _repository;

  ClassifyActivityUseCase(this._repository);

  /// Classify a buffer of [accX, accY, accZ, bpm] readings
  /// Expects buffer length of exactly 320 items (windowed data)
  Future<Activity> execute(List<List<double>> buffer) async {
    if (buffer.isEmpty) {
      throw ArgumentError('Buffer cannot be empty');
    }

    if (buffer.length != 320) {
      throw ArgumentError(
        'Buffer must contain exactly 320 samples, got ${buffer.length}',
      );
    }

    // Validate each item has 4 values: [accX, accY, accZ, bpm]
    for (final item in buffer) {
      if (item.length != 4) {
        throw ArgumentError(
          'Each buffer item must have 4 values [accX, accY, accZ, bpm], got ${item.length}',
        );
      }
    }

    // --- STEP 1: REST filter (sanity gate) ---
    // If the latest BPM is below the threshold, the user is considered Calm
    // and we purposely avoid invoking the ML model for performance and
    // because the model is trained for active/stressed detection only.
    final lastSample = buffer.last;
    final double? lastBpm = lastSample.length >= 4
        ? lastSample[3] as double?
        : null;
    if (lastBpm != null && lastBpm < 85.0) {
      return Activity(
        label: 'Calm',
        confidence: 0.0,
        timestamp: DateTime.now(),
        probabilities: [0.0, 0.0, 0.0],
      );
    }

    // Delegate to repository for actual classification
    return _repository.classifyActivity(buffer);
  }
}

/// Repository interface for activity classification
/// Decouples use case from platform-specific ML implementation
abstract class ActivityClassifierRepository {
  /// Classify sensor buffer and return activity prediction
  /// Returns Activity with label, confidence, and probabilities
  Future<Activity> classifyActivity(List<List<double>> buffer);

  /// Get available activity labels
  Future<List<String>> getActivityLabels();
}
