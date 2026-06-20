import 'dart:async';

import 'package:flowfit/models/mission.dart';
import 'package:flowfit/models/walking_session.dart';
import 'package:flowfit/models/workout_session.dart';
import 'package:flowfit/providers/running_session_provider.dart';
import 'package:flowfit/screens/workout/walking/mission_creation_screen.dart';
import 'package:flowfit/services/gps_tracking_service.dart';
import 'package:flowfit/services/heart_rate_service.dart';
import 'package:flowfit/services/timer_service.dart';
import 'package:flowfit/services/workout_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets(
    'Start Mission creates target walking session and opens active tracking',
    (tester) async {
      final sessionService = _FakeWorkoutSessionService();

      await _pumpScreen(tester, sessionService);

      await tester.ensureVisible(find.text('Start Mission'));
      await tester.tap(find.text('Start Mission'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(sessionService.createdSessions, hasLength(1));

      final session = sessionService.createdSessions.single as WalkingSession;
      expect(session.type, WorkoutType.walking);
      expect(session.mission, isNotNull);
      expect(session.mission!.type, MissionType.target);
      expect(session.mission!.name, 'Distance Challenge');
      expect(session.mission!.targetDistance, 500);
      expect(find.text('Map Mission'), findsWidgets);
      expect(find.text('No active walking session'), findsNothing);
    },
  );

  testWidgets('Start Mission failure stays on setup with retry feedback', (
    tester,
  ) async {
    final sessionService = _FakeWorkoutSessionService(throwOnCreate: true);

    await _pumpScreen(tester, sessionService);

    await tester.ensureVisible(find.text('Start Mission'));
    await tester.tap(find.text('Start Mission'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(sessionService.createdSessions, isEmpty);
    expect(find.text('Create Mission'), findsOneWidget);
    expect(find.text('Map Mission'), findsNothing);
    expect(
      find.text(
        'Could not start the mission. Sign in and check your connection, then try again.',
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _FakeWorkoutSessionService sessionService,
) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gpsTrackingServiceProvider.overrideWithValue(_FakeGpsTrackingService()),
        timerServiceProvider.overrideWithValue(_NoopTimerService()),
        heartRateServiceProvider.overrideWithValue(_NoopHeartRateService()),
        workoutSessionServiceProvider.overrideWithValue(sessionService),
        workoutSessionUserIdProvider.overrideWithValue('user-1'),
      ],
      child: const MaterialApp(
        home: MissionCreationScreen(missionType: MissionType.target),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

class _FakeWorkoutSessionService implements WorkoutSessionService {
  _FakeWorkoutSessionService({this.throwOnCreate = false});

  final bool throwOnCreate;
  final List<WorkoutSession> createdSessions = [];

  @override
  Future<String> createSession(WorkoutSession session) async {
    if (throwOnCreate) {
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
  Future<void> saveSession(WorkoutSession session) async {}

  @override
  Future<void> updateSession(WorkoutSession session) async {}
}

class _FakeGpsTrackingService implements GPSTrackingService {
  final StreamController<LatLng> _controller =
      StreamController<LatLng>.broadcast();

  @override
  Stream<LatLng> get locationStream => _controller.stream;

  @override
  double calculateDistance(LatLng point1, LatLng point2) => 0;

  @override
  double calculateRouteDistance(List<LatLng> routePoints) => 0;

  @override
  void dispose() {
    _controller.close();
  }

  @override
  Future<LatLng> getCurrentLocation() async => const LatLng(14.5995, 120.9842);

  @override
  Future<bool> hasLocationPermission() async => true;

  @override
  Future<bool> requestLocationPermission() async => true;

  @override
  Future<void> startTracking() async {}

  @override
  Future<void> stopTracking() async {}
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
