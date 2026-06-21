import 'package:flowfit/models/resistance_session.dart';
import 'package:flowfit/models/running_session.dart';
import 'package:flowfit/models/walking_session.dart';
import 'package:flowfit/models/workout_session.dart';
import 'package:flowfit/services/workout_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutSessionService.parseWorkoutSession', () {
    test('parses canonical Supabase workout row types', () {
      expect(
        WorkoutSessionService.parseWorkoutSession(_runningRow('running')),
        isA<RunningSession>(),
      );
      expect(
        WorkoutSessionService.parseWorkoutSession(_walkingRow('walking')),
        isA<WalkingSession>(),
      );
      expect(
        WorkoutSessionService.parseWorkoutSession(_resistanceRow('resistance')),
        isA<ResistanceSession>(),
      );
    });

    test('uses the model factory aliases for recovered legacy rows', () {
      expect(
        WorkoutSessionService.parseWorkoutSession(_runningRow('run')),
        isA<RunningSession>(),
      );
      expect(
        WorkoutSessionService.parseWorkoutSession(_walkingRow('walk')),
        isA<WalkingSession>(),
      );
      expect(
        WorkoutSessionService.parseWorkoutSession(_resistanceRow('strength')),
        isA<ResistanceSession>(),
      );
    });

    test('throws a clear FormatException for unsupported rows', () {
      expect(
        () => WorkoutSessionService.parseWorkoutSession({
          'id': 'bad-type',
          'user_id': 'user-1',
          'workout_type': 'cycling',
          'start_time': '2026-06-21T10:00:00.000Z',
          'status': WorkoutStatus.completed.name,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _runningRow(String workoutType) {
  return {
    'id': 'run-1',
    'user_id': 'user-1',
    'workout_type': workoutType,
    'start_time': '2026-06-21T10:00:00.000Z',
    'goal_type': GoalType.distance.name,
    'target_distance': 5,
    'current_distance': 2,
    'status': WorkoutStatus.active.name,
  };
}

Map<String, dynamic> _walkingRow(String workoutType) {
  return {
    'id': 'walk-1',
    'user_id': 'user-1',
    'workout_type': workoutType,
    'start_time': '2026-06-21T10:00:00.000Z',
    'mode': WalkingMode.free.name,
    'current_distance': 1,
    'steps': 1200,
    'mission_completed': false,
    'status': WorkoutStatus.completed.name,
  };
}

Map<String, dynamic> _resistanceRow(String workoutType) {
  return {
    'id': 'strength-1',
    'user_id': 'user-1',
    'workout_type': workoutType,
    'workout_subtype': BodySplit.upper.name,
    'start_time': '2026-06-21T10:00:00.000Z',
    'exercises_completed': const [],
    'status': WorkoutStatus.completed.name,
  };
}
