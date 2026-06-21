import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/features/activity_classifier/domain/activity.dart';
import 'package:flowfit/features/activity_classifier/domain/classify_activity_usecase.dart';

/// Mock implementation of ActivityClassifierRepository for testing
class MockActivityClassifierRepository implements ActivityClassifierRepository {
  List<double>? nextPrediction;
  int callCount = 0;

  @override
  Future<Activity> classifyActivity(List<List<double>> buffer) async {
    callCount++;

    if (nextPrediction == null) {
      throw StateError('nextPrediction not set');
    }

    if (nextPrediction!.length != 3) {
      throw ArgumentError('Prediction must have 3 values');
    }

    // Find max probability
    int maxIndex = 0;
    double maxProb = nextPrediction![0];
    for (int i = 1; i < nextPrediction!.length; i++) {
      if (nextPrediction![i] > maxProb) {
        maxProb = nextPrediction![i];
        maxIndex = i;
      }
    }

    const labels = ['Stress', 'Cardio', 'Strength'];

    return Activity(
      label: labels[maxIndex],
      confidence: maxProb,
      timestamp: DateTime.now(),
      probabilities: nextPrediction!,
    );
  }

  @override
  Future<List<String>> getActivityLabels() async {
    return ['Stress', 'Cardio', 'Strength'];
  }
}

void main() {
  group('ClassifyActivityUseCase', () {
    late MockActivityClassifierRepository mockRepository;
    late ClassifyActivityUseCase useCase;

    setUp(() {
      mockRepository = MockActivityClassifierRepository();
      useCase = ClassifyActivityUseCase(mockRepository);
    });

    test('validate buffer length requirement', () async {
      final emptyBuffer = <List<double>>[];

      expect(() => useCase.execute(emptyBuffer), throwsA(isA<ArgumentError>()));
    });

    test('validate buffer must have 320 samples', () async {
      final shortBuffer = List.generate(100, (_) => [1.0, 2.0, 3.0, 4.0]);

      expect(
        () => useCase.execute(shortBuffer),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('320'),
          ),
        ),
      );
    });

    test('validate each sample has 4 features', () async {
      final invalidBuffer = List.generate(
        320,
        (_) => [1.0, 2.0, 3.0], // Only 3 values instead of 4
      );

      expect(
        () => useCase.execute(invalidBuffer),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('4'),
          ),
        ),
      );
    });

    test('classify activity successfully with valid buffer', () async {
      final validBuffer = List.generate(
        320,
        (_) => [
          1.5,
          2.3,
          0.8,
          90.0,
        ], // [accX, accY, accZ, bpm] - HR >= 85 to allow AI
      );

      mockRepository.nextPrediction = [0.1, 0.8, 0.1]; // Cardio is highest

      final result = await useCase.execute(validBuffer);

      expect(result.label, equals('Cardio'));
      expect(result.confidence, closeTo(0.8, 0.01));
      expect(result.probabilities, equals([0.1, 0.8, 0.1]));
      expect(mockRepository.callCount, equals(1));
    });

    test('classify Stress activity', () async {
      final buffer = List.generate(320, (_) => [1.0, 1.0, 1.0, 90.0]);
      mockRepository.nextPrediction = [0.9, 0.05, 0.05]; // Stress is highest

      final result = await useCase.execute(buffer);

      expect(result.label, equals('Stress'));
      expect(result.confidence, closeTo(0.9, 0.01));
    });

    test('classify Strength activity', () async {
      final buffer = List.generate(320, (_) => [5.0, 4.0, 3.0, 120.0]);
      mockRepository.nextPrediction = [0.05, 0.1, 0.85]; // Strength is highest

      final result = await useCase.execute(buffer);

      expect(result.label, equals('Strength'));
      expect(result.confidence, closeTo(0.85, 0.01));
    });

    test('handle repository errors gracefully', () async {
      final buffer = List.generate(320, (_) => [1.0, 2.0, 3.0, 120.0]);
      mockRepository.nextPrediction = null; // This will throw

      expect(() => useCase.execute(buffer), throwsA(isA<StateError>()));
    });

    test('short-circuit to Calm when bpm < 85', () async {
      final calmbuffer = List.generate(320, (_) => [0.0, 0.0, 0.0, 70.0]);
      // Ensure repository not called
      mockRepository.nextPrediction = [0.1, 0.1, 0.8];

      final result = await useCase.execute(calmbuffer);
      expect(result.label, equals('Calm'));
      expect(result.probabilities, equals([0.0, 0.0, 0.0]));
      expect(mockRepository.callCount, equals(0));
    });
  });

  group('Activity domain model', () {
    test('create activity with all fields', () {
      final activity = Activity(
        label: 'Cardio',
        confidence: 0.95,
        timestamp: DateTime(2025, 1, 1),
        probabilities: [0.02, 0.95, 0.03],
      );

      expect(activity.label, equals('Cardio'));
      expect(activity.confidence, equals(0.95));
      expect(activity.probabilities.length, equals(3));
    });

    test('activity copyWith method', () {
      final original = Activity(
        label: 'Stress',
        confidence: 0.7,
        timestamp: DateTime(2025, 1, 1),
        probabilities: [0.7, 0.2, 0.1],
      );

      final updated = original.copyWith(label: 'Cardio', confidence: 0.8);

      expect(updated.label, equals('Cardio'));
      expect(updated.confidence, equals(0.8));
      expect(updated.timestamp, equals(original.timestamp));
    });

    test('activity equality based on label, confidence, timestamp', () {
      final now = DateTime.now();
      final activity1 = Activity(
        label: 'Cardio',
        confidence: 0.9,
        timestamp: now,
        probabilities: [0.05, 0.9, 0.05],
      );

      final activity2 = Activity(
        label: 'Cardio',
        confidence: 0.9,
        timestamp: now,
        probabilities: [0.05, 0.9, 0.05],
      );

      expect(activity1, equals(activity2));
    });

    test('activity toString formatting', () {
      final activity = Activity(
        label: 'Cardio',
        confidence: 0.95,
        timestamp: DateTime(2025, 1, 1, 12, 0, 0),
        probabilities: [0.02, 0.95, 0.03],
      );

      final str = activity.toString();
      expect(str, contains('Cardio'));
      expect(str, contains('95.0%'));
    });
  });
}
