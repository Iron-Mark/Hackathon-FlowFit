import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_stats.dart';
import '../models/recent_activity.dart';
import '../models/daily_mood.dart';
import '../models/running_session.dart';
import '../models/walking_session.dart';
import '../models/workout_session.dart';
import 'activity_history_provider.dart';
import 'running_session_provider.dart';
import 'package:flowfit/core/providers/repositories/heart_rate_repository_provider.dart'
    as core_hrp;

/// Provider for fetching daily fitness statistics
///
/// Returns DailyStats containing steps, calories, and active minutes.
/// States: loading, data(DailyStats), error
///
/// Refresh by calling: ref.invalidate(dailyStatsProvider)
final dailyStatsProvider = FutureProvider<DailyStats>((ref) async {
  final sessionService = ref.watch(workoutSessionServiceProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final sessions = await sessionService.getSessionsInRange(
    startDate: start,
    endDate: now,
  );

  return _dailyStatsFromSessions(sessions);
});

/// Provider for fetching recent workout activities
///
/// Returns a list of RecentActivity objects sorted by most recent first.
/// States: loading, data(List<RecentActivity>), error
///
/// Refresh by calling: ref.invalidate(recentActivitiesProvider)
final recentActivitiesProvider = FutureProvider<List<RecentActivity>>((
  ref,
) async {
  return ref.watch(activityHistoryProvider.future);
});

/// Provider for daily mood/stress summary from AI tracker
final dailyMoodProvider = FutureProvider<DailyMood>((ref) async {
  // Try to get historical heart rate readings for today and derive a mood summary from them.
  try {
    final heartRateRepo = ref.watch(core_hrp.heartRateRepositoryProvider);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = now;
    final readings = await heartRateRepo.getHistoricalData(
      startDate: start,
      endDate: end,
    );
    if (readings.isEmpty) {
      return DailyMood(stressMinutes: 0, calmMinutes: 0);
    }

    // compute average delta between consecutive readings
    int avgDeltaSeconds = 10; // default: assume 10s
    if (readings.length >= 2) {
      final deltas = <int>[];
      for (int i = 1; i < readings.length; i++) {
        final delta = readings[i].timestamp
            .difference(readings[i - 1].timestamp)
            .inSeconds;
        if (delta > 0) deltas.add(delta);
      }
      if (deltas.isNotEmpty) {
        final sum = deltas.reduce((a, b) => a + b);
        avgDeltaSeconds = (sum / deltas.length).round();
        avgDeltaSeconds = avgDeltaSeconds.clamp(1, 600);
      }
    }

    // Determine baseline as average bpm for the day (fallback to 70)
    final bpms = readings.map((r) => r.bpm ?? 0).where((b) => b > 0).toList();
    final avgBpm = bpms.isEmpty
        ? 70
        : (bpms.reduce((a, b) => a + b) / bpms.length);
    double threshold =
        avgBpm + 15.0; // threshold above average indicates possible stress
    threshold = threshold.clamp(80.0, 140.0);

    // classify each reading as stressed or calm using threshold
    int stressedSeconds = 0;
    int calmSeconds = 0;
    for (final r in readings) {
      final bpm = r.bpm ?? 0;
      if (bpm >= threshold) {
        stressedSeconds += avgDeltaSeconds;
      } else {
        calmSeconds += avgDeltaSeconds;
      }
    }
    final stressedMinutes = (stressedSeconds / 60).round();
    final calmMinutes = (calmSeconds / 60).round();
    return DailyMood(stressMinutes: stressedMinutes, calmMinutes: calmMinutes);
  } catch (e) {
    return DailyMood(stressMinutes: 0, calmMinutes: 0);
  }
});

/// Provider to compare today's cardio/active minutes vs baseline.
/// Returns a percentage (positive => more than baseline, negative => less)
final activityComparisonProvider = FutureProvider<double>((ref) async {
  final sessionService = ref.watch(workoutSessionServiceProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final historyStart = today.subtract(const Duration(days: 7));
  final sessions = await sessionService.getSessionsInRange(
    startDate: historyStart,
    endDate: now,
  );

  final todayMinutes = _activeMinutesForDay(sessions, today);
  final historicalMinutes = <int>[];
  for (var i = 1; i <= 7; i++) {
    historicalMinutes.add(
      _activeMinutesForDay(sessions, today.subtract(Duration(days: i))),
    );
  }

  final nonZeroHistorical = historicalMinutes
      .where((minutes) => minutes > 0)
      .toList();
  if (nonZeroHistorical.isEmpty) return 0;

  final baseline =
      nonZeroHistorical.reduce((a, b) => a + b) / nonZeroHistorical.length;
  return (todayMinutes - baseline) / baseline;
});

/// Provider for managing the selected bottom navigation index
///
/// Initial value: 0 (Home)
/// Range: 0-4 (5 navigation items: Home, Health, Track, Progress, Profile)
final selectedNavIndexProvider = StateProvider<int>((ref) => 0);

/// Provider for managing unread notification count
///
/// Initial value: 0
/// Display logic: Shows "9+" when count > 9
final unreadNotificationsProvider = StateProvider<int>((ref) => 0);

DailyStats _dailyStatsFromSessions(List<WorkoutSession> sessions) {
  final steps = sessions.fold<int>(
    0,
    (total, session) => total + _stepsForSession(session),
  );
  final calories = sessions.fold<int>(
    0,
    (total, session) => total + (session.caloriesBurned ?? 0),
  );
  final activeSeconds = sessions.fold<int>(
    0,
    (total, session) => total + (session.durationSeconds ?? 0),
  );

  return DailyStats(
    steps: steps,
    stepsGoal: 10000,
    calories: calories,
    activeMinutes: (activeSeconds / 60).round(),
  );
}

int _activeMinutesForDay(List<WorkoutSession> sessions, DateTime day) {
  return (sessions
              .where((session) => _isSameDay(session.startTime, day))
              .fold<int>(
                0,
                (total, session) => total + (session.durationSeconds ?? 0),
              ) /
          60)
      .round();
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

int _stepsForSession(WorkoutSession session) {
  if (session is RunningSession) {
    return session.steps ?? _estimateStepsFromDistance(session.currentDistance);
  }
  if (session is WalkingSession) {
    return session.steps;
  }
  return 0;
}

int _estimateStepsFromDistance(double kilometers) {
  return (kilometers * 1300).round().clamp(0, 100000);
}
