import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/providers/dashboard_providers.dart';
import 'package:flowfit/providers/activity_history_provider.dart';
import 'package:flowfit/providers/running_session_provider.dart';
import 'package:flowfit/models/daily_stats.dart';
import 'package:flowfit/models/daily_mood.dart';
import 'package:flowfit/models/recent_activity.dart';
import 'package:flowfit/models/workout_session.dart';
import 'package:flowfit/services/workout_session_service.dart';

void main() {
  group('Dashboard Providers', () {
    test('dailyStatsProvider returns DailyStats', () async {
      final container = _containerWithWorkoutService(
        _FakeWorkoutSessionService(),
      );
      addTearDown(container.dispose);

      final stats = await container.read(dailyStatsProvider.future);

      expect(stats, isA<DailyStats>());
      expect(stats.steps, greaterThanOrEqualTo(0));
      expect(stats.stepsGoal, greaterThan(0));
      expect(stats.calories, greaterThanOrEqualTo(0));
      expect(stats.activeMinutes, greaterThanOrEqualTo(0));
    });

    test('recentActivitiesProvider returns a safe activity list', () async {
      final container = _containerWithWorkoutService(
        _FakeWorkoutSessionService(),
      );
      addTearDown(container.dispose);

      final activities = await container.read(recentActivitiesProvider.future);

      expect(activities, isA<List<RecentActivity>>());

      for (final activity in activities) {
        expect(activity.id, isNotEmpty);
        expect(activity.name, isNotEmpty);
        expect(['run', 'walk', 'workout', 'cycle'], contains(activity.type));
      }
    });

    test(
      'dailyMoodProvider does not invent mood minutes when data is unavailable',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mood = await container.read(dailyMoodProvider.future);

        expect(mood, isA<DailyMood>());
        expect(mood.stressMinutes, 0);
        expect(mood.calmMinutes, 0);
      },
    );

    test('selectedNavIndexProvider starts at 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final index = container.read(selectedNavIndexProvider);

      expect(index, 0);
    });

    test('selectedNavIndexProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedNavIndexProvider.notifier).state = 2;
      final index = container.read(selectedNavIndexProvider);

      expect(index, 2);
    });

    test('unreadNotificationsProvider starts at 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final count = container.read(unreadNotificationsProvider);

      expect(count, 0);
    });

    test('unreadNotificationsProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(unreadNotificationsProvider.notifier).state = 5;
      final count = container.read(unreadNotificationsProvider);

      expect(count, 5);
    });

    test('dailyStatsProvider can be invalidated and refetched', () async {
      final container = _containerWithWorkoutService(
        _FakeWorkoutSessionService(),
      );
      addTearDown(container.dispose);

      // First fetch
      final stats1 = await container.read(dailyStatsProvider.future);
      expect(stats1, isA<DailyStats>());

      // Invalidate
      container.invalidate(dailyStatsProvider);

      // Second fetch
      final stats2 = await container.read(dailyStatsProvider.future);
      expect(stats2, isA<DailyStats>());
    });

    test('recentActivitiesProvider can be invalidated and refetched', () async {
      final container = _containerWithWorkoutService(
        _FakeWorkoutSessionService(),
      );
      addTearDown(container.dispose);

      // First fetch
      final activities1 = await container.read(recentActivitiesProvider.future);
      expect(activities1, isA<List<RecentActivity>>());

      // Invalidate
      container.invalidate(recentActivitiesProvider);

      // Second fetch
      final activities2 = await container.read(recentActivitiesProvider.future);
      expect(activities2, isA<List<RecentActivity>>());
    });

    test('dailyStatsProvider exposes workout service failures', () async {
      final container = _containerWithWorkoutService(
        _FailingWorkoutSessionService(),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(dailyStatsProvider.future),
        throwsA(isA<StateError>()),
      );
    });

    test('activityHistoryProvider exposes workout service failures', () async {
      final container = _containerWithWorkoutService(
        _FailingWorkoutSessionService(),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(activityHistoryProvider.future),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'activityComparisonProvider exposes workout service failures',
      () async {
        final container = _containerWithWorkoutService(
          _FailingWorkoutSessionService(),
        );
        addTearDown(container.dispose);

        await expectLater(
          container.read(activityComparisonProvider.future),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}

ProviderContainer _containerWithWorkoutService(WorkoutSessionService service) {
  return ProviderContainer(
    overrides: [workoutSessionServiceProvider.overrideWithValue(service)],
  );
}

class _FakeWorkoutSessionService implements WorkoutSessionService {
  @override
  Future<String> createSession(WorkoutSession session) async => session.id;

  @override
  Future<void> deleteSession(String sessionId) async {}

  @override
  Future<WorkoutSession?> getSession(String sessionId) async => null;

  @override
  Future<List<WorkoutSession>> getSessionsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return [];
  }

  @override
  Future<List<WorkoutSession>> listRecentSessions({
    int limit = 20,
    WorkoutType? type,
  }) async {
    return [];
  }

  @override
  Future<void> saveSession(WorkoutSession session) async {}

  @override
  Future<void> updateSession(WorkoutSession session) async {}
}

class _FailingWorkoutSessionService extends _FakeWorkoutSessionService {
  @override
  Future<List<WorkoutSession>> getSessionsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    throw StateError('workout service unavailable');
  }

  @override
  Future<List<WorkoutSession>> listRecentSessions({
    int limit = 20,
    WorkoutType? type,
  }) async {
    throw StateError('workout service unavailable');
  }
}
