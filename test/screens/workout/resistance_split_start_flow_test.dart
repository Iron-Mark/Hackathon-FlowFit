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
}

class _FakeWorkoutSessionService implements WorkoutSessionService {
  final List<WorkoutSession> createdSessions = [];
  final List<WorkoutSession> savedSessions = [];

  @override
  Future<String> createSession(WorkoutSession session) async {
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
