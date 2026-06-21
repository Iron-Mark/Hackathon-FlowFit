import 'package:flowfit/models/resistance_session.dart';
import 'package:flowfit/models/workout_session.dart';
import 'package:flowfit/providers/running_session_provider.dart';
import 'package:flowfit/screens/workout/resistance/active_resistance_screen.dart';
import 'package:flowfit/screens/workout/resistance/split_selection_screen.dart';
import 'package:flowfit/services/workout_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'start workout creates resistance session before opening active screen',
    (tester) async {
      final workoutService = _FakeWorkoutSessionService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutSessionUserIdProvider.overrideWithValue('test-user-id'),
            workoutSessionServiceProvider.overrideWithValue(workoutService),
          ],
          child: MaterialApp(
            routes: {
              '/workout/resistance/active': (_) =>
                  const ActiveResistanceScreen(),
            },
            home: const SplitSelectionScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Upper Body'));
      await tester.pump();
      await tester.ensureVisible(find.text('Start Workout'));
      await tester.tap(find.text('Start Workout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(workoutService.createdSessions, hasLength(1));
      expect(workoutService.createdSessions.single, isA<ResistanceSession>());
      expect(find.text('Resistance Training'), findsOneWidget);
      expect(find.text('Bench Press'), findsWidgets);
      expect(find.text('No active resistance workout'), findsNothing);
    },
  );

  testWidgets('start workout preserves selected split settings', (
    tester,
  ) async {
    final workoutService = _FakeWorkoutSessionService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutSessionUserIdProvider.overrideWithValue('test-user-id'),
          workoutSessionServiceProvider.overrideWithValue(workoutService),
        ],
        child: MaterialApp(
          routes: {
            '/workout/resistance/active': (_) => const ActiveResistanceScreen(),
          },
          home: const SplitSelectionScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Lower Body'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('120s'));
    await tester.tap(find.text('120s'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start Workout'));
    await tester.tap(find.text('Start Workout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final session = workoutService.createdSessions.single as ResistanceSession;
    expect(session.split, BodySplit.lower);
    expect(session.restTimerSeconds, 120);
    expect(session.audioCuesEnabled, isFalse);
    expect(session.hrMonitorEnabled, isTrue);
    expect(session.exercises.first.exerciseName, 'Squats');
    expect(find.text('Resistance Training'), findsOneWidget);
  });

  testWidgets('failed start stays on setup and can be retried', (tester) async {
    final workoutService = _FakeWorkoutSessionService()..failCreate = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutSessionUserIdProvider.overrideWithValue('test-user-id'),
          workoutSessionServiceProvider.overrideWithValue(workoutService),
        ],
        child: MaterialApp(
          routes: {
            '/workout/resistance/active': (_) => const ActiveResistanceScreen(),
          },
          home: const SplitSelectionScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Upper Body'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start Workout'));
    await tester.tap(find.text('Start Workout'));
    await tester.pumpAndSettle();

    expect(workoutService.createCalls, 1);
    expect(find.text('Choose Your Split'), findsOneWidget);
    expect(find.text('Start Workout'), findsOneWidget);
    expect(
      find.textContaining('Could not start resistance workout'),
      findsOneWidget,
    );
    expect(find.text('Resistance Training'), findsNothing);

    workoutService.failCreate = false;
    await tester.ensureVisible(find.text('Start Workout'));
    await tester.tap(find.text('Start Workout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(workoutService.createCalls, 2);
    expect(workoutService.createdSessions, hasLength(1));
    expect(find.text('Resistance Training'), findsOneWidget);
  });
}

class _FakeWorkoutSessionService implements WorkoutSessionService {
  final List<WorkoutSession> createdSessions = [];
  final List<WorkoutSession> savedSessions = [];
  bool failCreate = false;
  int createCalls = 0;

  @override
  Future<String> createSession(WorkoutSession session) async {
    createCalls++;
    if (failCreate) {
      throw StateError('create failed');
    }
    createdSessions.add(session);
    return session.id;
  }

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
  Future<void> saveSession(WorkoutSession session) async {
    savedSessions.add(session);
  }

  @override
  Future<void> updateSession(WorkoutSession session) async {}
}
