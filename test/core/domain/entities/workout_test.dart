import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/core/domain/entities/workout.dart';
import 'package:flowfit/core/domain/entities/workout_type.dart';
import 'package:flowfit/core/domain/entities/heart_rate_point.dart';

void main() {
  group('Workout', () {
    late DateTime testStartTime;
    late DateTime testEndTime;
    late List<HeartRatePoint> testHeartRateData;

    setUp(() {
      testStartTime = DateTime(2024, 1, 1, 10, 0, 0);
      testEndTime = DateTime(2024, 1, 1, 10, 30, 0);
      testHeartRateData = [
        HeartRatePoint(timestamp: testStartTime, bpm: 120, ibiValues: [500]),
        HeartRatePoint(
          timestamp: testStartTime.add(const Duration(minutes: 15)),
          bpm: 150,
          ibiValues: [400],
        ),
      ];
    });

    group('Constructor', () {
      test('creates workout with all required fields', () {
        final workout = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.running,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          heartRateData: testHeartRateData,
        );

        expect(workout.id, equals('workout_1'));
        expect(workout.userId, equals('user_1'));
        expect(workout.type, equals(WorkoutType.running));
        expect(workout.startTime, equals(testStartTime));
        expect(workout.endTime, equals(testEndTime));
        expect(workout.duration, equals(const Duration(minutes: 30)));
        expect(workout.heartRateData, equals(testHeartRateData));
        expect(workout.distance, isNull);
        expect(workout.calories, isNull);
        expect(workout.metadata, isNull);
      });

      test('creates workout with optional fields', () {
        final metadata = {'route': 'park_loop', 'weather': 'sunny'};
        final workout = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.running,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          distance: 5.0,
          calories: 300,
          heartRateData: testHeartRateData,
          metadata: metadata,
        );

        expect(workout.distance, equals(5.0));
        expect(workout.calories, equals(300));
        expect(workout.metadata, equals(metadata));
      });

      test('creates workout with empty heart rate data', () {
        final workout = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.yoga,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          heartRateData: [],
        );

        expect(workout.heartRateData, isEmpty);
      });
    });

    group('copyWith', () {
      late Workout original;

      setUp(() {
        original = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.running,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          distance: 5.0,
          calories: 300,
          heartRateData: testHeartRateData,
          metadata: {'note': 'morning run'},
        );
      });

      test('creates copy with updated single field', () {
        final copy = original.copyWith(calories: 350);

        expect(copy.calories, equals(350));
        expect(copy.id, equals(original.id));
        expect(copy.userId, equals(original.userId));
        expect(copy.type, equals(original.type));
      });

      test('creates copy with updated workout type', () {
        final copy = original.copyWith(type: WorkoutType.walking);

        expect(copy.type, equals(WorkoutType.walking));
        expect(copy.distance, equals(original.distance));
      });

      test('creates copy with updated distance', () {
        final copy = original.copyWith(distance: 7.5);

        expect(copy.distance, equals(7.5));
      });

      test('creates copy with updated duration', () {
        const newDuration = Duration(minutes: 45);
        final copy = original.copyWith(duration: newDuration);

        expect(copy.duration, equals(newDuration));
      });

      test('creates copy with updated heart rate data', () {
        final newHeartRateData = [
          HeartRatePoint(timestamp: testStartTime, bpm: 130, ibiValues: [460]),
        ];
        final copy = original.copyWith(heartRateData: newHeartRateData);

        expect(copy.heartRateData, equals(newHeartRateData));
        expect(copy.heartRateData.length, equals(1));
      });

      test('creates copy with updated metadata', () {
        final newMetadata = {'note': 'evening run', 'terrain': 'hilly'};
        final copy = original.copyWith(metadata: newMetadata);

        expect(copy.metadata, equals(newMetadata));
        expect(copy.metadata?['terrain'], equals('hilly'));
      });

      test('creates copy with multiple updated fields', () {
        final copy = original.copyWith(
          distance: 10.0,
          calories: 500,
          type: WorkoutType.cycling,
        );

        expect(copy.distance, equals(10.0));
        expect(copy.calories, equals(500));
        expect(copy.type, equals(WorkoutType.cycling));
      });

      test('returns same values when no parameters provided', () {
        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.userId, equals(original.userId));
        expect(copy.type, equals(original.type));
        expect(copy.distance, equals(original.distance));
      });
    });

    group('Equality', () {
      test('two workouts with same values are equal', () {
        final workout1 = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.running,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          distance: 5.0,
          calories: 300,
          heartRateData: testHeartRateData,
        );
        final workout2 = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.running,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          distance: 5.0,
          calories: 300,
          heartRateData: testHeartRateData,
        );

        expect(workout1, equals(workout2));
        expect(workout1.hashCode, equals(workout2.hashCode));
      });

      test('two workouts with different ids are not equal', () {
        final workout1 = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.running,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          heartRateData: [],
        );
        final workout2 = Workout(
          id: 'workout_2',
          userId: 'user_1',
          type: WorkoutType.running,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          heartRateData: [],
        );

        expect(workout1, isNot(equals(workout2)));
      });

      test('two workouts with different types are not equal', () {
        final workout1 = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.running,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          heartRateData: [],
        );
        final workout2 = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.walking,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          heartRateData: [],
        );

        expect(workout1, isNot(equals(workout2)));
      });

      test('equality handles null optional fields correctly', () {
        final workout1 = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.yoga,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          heartRateData: [],
        );
        final workout2 = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.yoga,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          heartRateData: [],
        );

        expect(workout1, equals(workout2));
      });

      test('workout is equal to itself', () {
        final workout = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.running,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          heartRateData: testHeartRateData,
        );

        expect(workout, equals(workout));
      });
    });

    group('Edge Cases', () {
      test('handles workout with zero duration', () {
        final workout = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.strength,
          startTime: testStartTime,
          endTime: testStartTime,
          duration: Duration.zero,
          heartRateData: [],
        );

        expect(workout.duration, equals(Duration.zero));
      });

      test('handles workout with very long duration', () {
        const longDuration = Duration(hours: 24);
        final workout = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.walking,
          startTime: testStartTime,
          endTime: testStartTime.add(longDuration),
          duration: longDuration,
          heartRateData: [],
        );

        expect(workout.duration.inHours, equals(24));
      });

      test('handles workout with zero distance', () {
        final workout = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.strength,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          distance: 0.0,
          heartRateData: [],
        );

        expect(workout.distance, equals(0.0));
      });

      test('handles workout with large distance', () {
        final workout = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.cycling,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(hours: 5),
          distance: 150.0,
          heartRateData: [],
        );

        expect(workout.distance, equals(150.0));
      });

      test('handles workout with zero calories', () {
        final workout = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.yoga,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          calories: 0,
          heartRateData: [],
        );

        expect(workout.calories, equals(0));
      });

      test('handles workout with many heart rate points', () {
        final manyPoints = List.generate(
          1000,
          (i) => HeartRatePoint(
            timestamp: testStartTime.add(Duration(seconds: i)),
            bpm: 120 + (i % 40),
            ibiValues: [500],
          ),
        );
        final workout = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.running,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          heartRateData: manyPoints,
        );

        expect(workout.heartRateData.length, equals(1000));
      });

      test('handles complex metadata structures', () {
        final complexMetadata = {
          'splits': [
            {'km': 1, 'time': '5:30'},
            {'km': 2, 'time': '5:45'},
          ],
          'elevation': {'gain': 150, 'loss': 120},
          'weather': {'temp': 20, 'humidity': 65},
        };
        final workout = Workout(
          id: 'workout_1',
          userId: 'user_1',
          type: WorkoutType.running,
          startTime: testStartTime,
          endTime: testEndTime,
          duration: const Duration(minutes: 30),
          heartRateData: [],
          metadata: complexMetadata,
        );

        expect(workout.metadata?['splits'], isA<List>());
        expect(workout.metadata?['elevation'], isA<Map>());
      });
    });
  });
}
