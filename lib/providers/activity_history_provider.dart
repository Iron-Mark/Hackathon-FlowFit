import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recent_activity.dart';
import '../models/workout_session.dart';
import 'running_session_provider.dart';

/// Provider for fetching recent workout activities with mood data
final activityHistoryProvider = FutureProvider<List<RecentActivity>>((
  ref,
) async {
  final sessionService = ref.watch(workoutSessionServiceProvider);

  // Fetch recent sessions from database
  final sessions = await sessionService.listRecentSessions(limit: 20);

  // Convert to RecentActivity format
  return sessions
      .map((session) => workoutSessionToRecentActivity(session))
      .toList();
});

/// Converts a WorkoutSession to RecentActivity
RecentActivity workoutSessionToRecentActivity(WorkoutSession session) {
  // Format details based on workout type
  String details = '';
  String type = '';

  switch (session.type) {
    case WorkoutType.running:
      type = 'run';
      final distance = (session as dynamic).currentDistance ?? 0.0;
      final duration = session.durationSeconds != null
          ? '${(session.durationSeconds! / 60).round()} min'
          : '';
      details = '${distance.toStringAsFixed(1)} km • $duration';
      if (session.caloriesBurned != null) {
        details += ' • ${session.caloriesBurned} cal';
      }
      break;

    case WorkoutType.walking:
      type = 'walk';
      final distance = (session as dynamic).currentDistance ?? 0.0;
      final duration = session.durationSeconds != null
          ? '${(session.durationSeconds! / 60).round()} min'
          : '';
      details = '${distance.toStringAsFixed(1)} km • $duration';
      if (session.caloriesBurned != null) {
        details += ' • ${session.caloriesBurned} cal';
      }
      break;

    case WorkoutType.resistance:
      type = 'workout';
      final duration = session.durationSeconds != null
          ? '${(session.durationSeconds! / 60).round()} min'
          : '';
      final split = (session as dynamic).split.displayName;
      details = '$duration • $split';
      if (session.caloriesBurned != null) {
        details += ' • ${session.caloriesBurned} cal';
      }
      break;

    case WorkoutType.cycling:
      type = 'cycle';
      final duration = session.durationSeconds != null
          ? '${(session.durationSeconds! / 60).round()} min'
          : '';
      details = duration;
      break;

    case WorkoutType.yoga:
      type = 'workout';
      final duration = session.durationSeconds != null
          ? '${(session.durationSeconds! / 60).round()} min'
          : '';
      details = '$duration • Yoga';
      break;
  }

  // Generate name based on time of day
  final hour = session.startTime.hour;
  String timeOfDay;
  if (hour < 12) {
    timeOfDay = 'Morning';
  } else if (hour < 17) {
    timeOfDay = 'Afternoon';
  } else {
    timeOfDay = 'Evening';
  }

  final name = '$timeOfDay ${session.type.displayName}';

  return RecentActivity(
    id: session.id,
    name: name,
    type: type,
    details: details,
    date: session.startTime,
    preMood: session.preMood,
    postMood: session.postMood,
    moodChange: session.moodChange,
  );
}

/// Provider for refreshing activity history
final refreshActivityHistoryProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(activityHistoryProvider);
  };
});
