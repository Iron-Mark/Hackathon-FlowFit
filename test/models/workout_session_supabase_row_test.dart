import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/models/resistance_session.dart';
import 'package:flowfit/models/running_session.dart';
import 'package:flowfit/models/walking_session.dart';

void main() {
  group('workout session Supabase row parsing', () {
    test(
      'running session accepts integer JSON for double precision columns',
      () {
        final session = RunningSession.fromJson({
          'id': '7ad0520e-2f0f-4b97-a974-9f339541cc0b',
          'user_id': '154748e0-165f-40aa-a4a1-a59f69723a0f',
          'workout_type': 'running',
          'start_time': '2026-06-14T00:00:00.000Z',
          'goal_type': 'distance',
          'target_distance': 5,
          'current_distance': 2,
          'avg_pace': 6,
          'status': 'active',
        });

        expect(session.targetDistance, 5.0);
        expect(session.currentDistance, 2.0);
        expect(session.avgPace, 6.0);
      },
    );

    test(
      'resistance session accepts integer JSON for total volume kilograms',
      () {
        final session = ResistanceSession.fromJson({
          'id': 'ef1ffb99-748b-4b47-a352-58717a694a65',
          'user_id': '154748e0-165f-40aa-a4a1-a59f69723a0f',
          'workout_type': 'resistance',
          'workout_subtype': 'upper',
          'start_time': '2026-06-14T00:00:00.000Z',
          'exercises_completed': [
            {
              'exercise_name': 'Bench Press',
              'emoji': 'lift',
              'total_sets': 1,
              'target_reps': 8,
              'completed_sets': [
                {
                  'reps': 8,
                  'weight': 15,
                  'completed_at': '2026-06-14T00:05:00.000Z',
                },
              ],
            },
          ],
          'rest_timer_seconds': 90,
          'audio_cues_enabled': true,
          'hr_monitor_enabled': false,
          'total_volume_kg': 120,
          'status': 'completed',
        });

        expect(session.totalVolumeKg, 120.0);
        expect(session.exercises.single.completedSets.single.weight, 15.0);
      },
    );

    test('walking session defaults old null mode rows to free walking', () {
      final session = WalkingSession.fromJson({
        'id': '34c81212-6f64-4a91-bf83-bdc7c51f91fa',
        'user_id': '154748e0-165f-40aa-a4a1-a59f69723a0f',
        'workout_type': 'walking',
        'start_time': '2026-06-14T00:00:00.000Z',
        'mode': null,
        'current_distance': 1,
        'steps': 1300,
        'mission_completed': false,
        'status': 'completed',
      });

      expect(session.mode, WalkingMode.free);
    });

    test('legacy invalid type-specific enum values fall back safely', () {
      final running = RunningSession.fromJson({
        'id': '7ad0520e-2f0f-4b97-a974-9f339541cc0b',
        'user_id': '154748e0-165f-40aa-a4a1-a59f69723a0f',
        'workout_type': 'running',
        'start_time': '2026-06-14T00:00:00.000Z',
        'goal_type': 'legacy_goal',
        'current_distance': 2,
        'status': 'active',
      });

      final resistance = ResistanceSession.fromJson({
        'id': 'ef1ffb99-748b-4b47-a352-58717a694a65',
        'user_id': '154748e0-165f-40aa-a4a1-a59f69723a0f',
        'workout_type': 'resistance',
        'workout_subtype': 'legacy_split',
        'start_time': '2026-06-14T00:00:00.000Z',
        'exercises_completed': const [],
        'status': 'completed',
      });

      final walking = WalkingSession.fromJson({
        'id': '34c81212-6f64-4a91-bf83-bdc7c51f91fa',
        'user_id': '154748e0-165f-40aa-a4a1-a59f69723a0f',
        'workout_type': 'walking',
        'start_time': '2026-06-14T00:00:00.000Z',
        'mode': 'legacy_mode',
        'current_distance': 1,
        'steps': 1300,
        'mission_completed': false,
        'status': 'completed',
      });

      expect(running.goalType, GoalType.distance);
      expect(resistance.split, BodySplit.upper);
      expect(walking.mode, WalkingMode.free);
    });
  });
}
