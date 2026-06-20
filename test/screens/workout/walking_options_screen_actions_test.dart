import 'dart:async';

import 'package:flowfit/models/mission.dart';
import 'package:flowfit/models/mood_rating.dart';
import 'package:flowfit/models/walking_session.dart';
import 'package:flowfit/models/workout_session.dart';
import 'package:flowfit/providers/running_session_provider.dart';
import 'package:flowfit/providers/walking_session_provider.dart';
import 'package:flowfit/screens/workout/walking/walking_options_screen.dart';
import 'package:flowfit/services/calorie_calculator_service.dart';
import 'package:flowfit/services/gps_tracking_service.dart';
import 'package:flowfit/services/heart_rate_service.dart';
import 'package:flowfit/services/timer_service.dart';
import 'package:flowfit/services/workout_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  Widget buildHarness() {
    return ProviderScope(
      overrides: [
        gpsTrackingServiceProvider.overrideWithValue(_FakeGpsTrackingService()),
      ],
      child: const MaterialApp(home: WalkingOptionsScreen()),
    );
  }

  testWidgets('Start Free Walk opens active walking with a free session', (
    tester,
  ) async {
    final notifier = _FakeWalkingOptionsNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [walkingSessionProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(home: WalkingOptionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Free Walk'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(notifier.startCalls, 1);
    expect(notifier.lastMode, WalkingMode.free);
    expect(notifier.lastTargetDuration, 30);
    expect(find.text('Free Walk'), findsWidgets);
    expect(find.text('No active walking session'), findsNothing);
  });

  testWidgets('Start Free Walk failure keeps options visible with feedback', (
    tester,
  ) async {
    final notifier = _FakeWalkingOptionsNotifier(throwOnStart: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [walkingSessionProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(home: WalkingOptionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Free Walk'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(notifier.startCalls, 1);
    expect(find.text('Choose Walking Mode'), findsOneWidget);
    expect(find.text('No active walking session'), findsNothing);
    expect(
      find.text(
        'Could not start walking. Sign in and check your connection, then try again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Create Mission opens target mission setup', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create Mission'));
    await tester.tap(find.text('Create Mission'));
    await tester.pumpAndSettle();

    expect(find.text('Target Distance'), findsOneWidget);
    expect(find.text('Mission Name'), findsOneWidget);
    expect(find.text('Start Mission'), findsOneWidget);
  });

  testWidgets('selected Safety Net type opens safety radius setup', (
    tester,
  ) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Safety Net'));
    await tester.tap(find.text('Safety Net'));
    await tester.ensureVisible(find.text('Create Mission'));
    await tester.tap(find.text('Create Mission'));
    await tester.pumpAndSettle();

    expect(find.text('Safe Zone Radius'), findsOneWidget);
    expect(find.text('Start Mission'), findsOneWidget);
  });
}

class _FakeWalkingOptionsNotifier extends WalkingSessionNotifier {
  _FakeWalkingOptionsNotifier({this.throwOnStart = false})
    : super(
        gpsService: _FakeGpsTrackingService(),
        timerService: _NoopTimerService(),
        hrService: _NoopHeartRateService(),
        calorieService: CalorieCalculatorService(),
        sessionService: _NoopWorkoutSessionService(),
        readCurrentUserId: () => 'user-1',
      );

  final bool throwOnStart;
  int startCalls = 0;
  WalkingMode? lastMode;
  int? lastTargetDuration;

  @override
  Future<void> startSession({
    required WalkingMode mode,
    int? targetDuration,
    Mission? mission,
    MoodRating? preMood,
  }) async {
    startCalls++;
    lastMode = mode;
    lastTargetDuration = targetDuration;

    if (throwOnStart) {
      throw StateError('start failed');
    }

    state = WalkingSession(
      id: 'walk-options-$startCalls',
      userId: 'user-1',
      startTime: DateTime(2026, 1, 1),
      mode: mode,
      targetDuration: targetDuration,
    );
  }
}

class _FakeGpsTrackingService extends GPSTrackingService {
  final StreamController<LatLng> _controller =
      StreamController<LatLng>.broadcast();

  @override
  Stream<LatLng> get locationStream => _controller.stream;

  @override
  Future<LatLng> getCurrentLocation() async => const LatLng(14.5995, 120.9842);

  @override
  Future<void> startTracking() async {}

  @override
  Future<void> stopTracking() async {}

  @override
  void dispose() {
    _controller.close();
  }
}

class _NoopTimerService implements TimerService {
  final StreamController<int> _controller = StreamController<int>.broadcast();

  @override
  int get elapsedSeconds => 0;

  @override
  String get formattedTime => '00:00';

  @override
  bool get isPaused => false;

  @override
  bool get isRunning => false;

  @override
  Stream<int> get timerStream => _controller.stream;

  @override
  void dispose() {
    _controller.close();
  }

  @override
  void pause() {}

  @override
  void reset() {}

  @override
  void resume() {}

  @override
  void setElapsedSeconds(int seconds) {}

  @override
  void start() {}

  @override
  void stop() {}
}

class _NoopHeartRateService implements HeartRateService {
  final StreamController<int> _controller = StreamController<int>.broadcast();

  @override
  int? get avgHeartRate => null;

  @override
  int? get currentHeartRate => null;

  @override
  Map<String, int> get heartRateZones => const {};

  @override
  Stream<int> get heartRateStream => _controller.stream;

  @override
  int? get maxHeartRate => null;

  @override
  void dispose() {
    _controller.close();
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  void reset() {}

  @override
  Future<void> startMonitoring() async {}

  @override
  Future<void> stopMonitoring() async {}

  @override
  void updateHeartRate(int heartRate) {}
}

class _NoopWorkoutSessionService implements WorkoutSessionService {
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
