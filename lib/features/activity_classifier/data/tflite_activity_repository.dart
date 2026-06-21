import 'package:logger/logger.dart';
import '../domain/activity.dart';
import '../domain/classify_activity_usecase.dart';
import '../platform/tflite_activity_classifier.dart';
import 'activity_dto.dart';

/// Concrete implementation of ActivityClassifierRepository
/// Wraps TFLite platform layer and maps to domain models
class TFLiteActivityRepository implements ActivityClassifierRepository {
  final TFLiteActivityClassifier _classifier;
  final Logger _logger = Logger();

  // Cached labels
  static const List<String> _activityLabels = ['Stress', 'Cardio', 'Strength'];

  TFLiteActivityRepository(this._classifier);

  @override
  Future<Activity> classifyActivity(List<List<double>> buffer) async {
    try {
      _logger.d('Classifying activity buffer (${buffer.length} samples)');

      // Delegate to platform layer for inference
      final probabilities = await _classifier.predict(buffer);

      // Convert prediction to DTO and then to domain model
      final dto = ActivityDto.fromPrediction(probabilities);

      final activity = Activity(
        label: dto.label,
        confidence: dto.confidence,
        timestamp: DateTime.now(),
        probabilities: dto.probabilities,
      );

      _logger.i(
        'Activity classified: ${activity.label} (${(activity.confidence * 100).toStringAsFixed(1)}%)',
      );
      return activity;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to classify activity',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<String>> getActivityLabels() async {
    return _activityLabels;
  }
}
