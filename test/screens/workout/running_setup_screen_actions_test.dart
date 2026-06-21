import 'dart:async';

import 'package:flowfit/models/heart_rate_data.dart';
import 'package:flowfit/models/mood_rating.dart';
import 'package:flowfit/models/running_session.dart';
import 'package:flowfit/models/sensor_batch.dart';
import 'package:flowfit/models/workout_session.dart';
import 'package:flowfit/providers/running_session_provider.dart';
import 'package:flowfit/screens/workout/running/running_setup_screen.dart';
import 'package:flowfit/services/calorie_calculator_service.dart';
import 'package:flowfit/services/gps_tracking_service.dart';
import 'package:flowfit/services/heart_rate_service.dart';
import 'package:flowfit/services/phone_data_listener.dart';
import 'package:flowfit/services/phone_step_counter_service.dart';
import 'package:flowfit/services/timer_service.dart';
import 'package:flowfit/services/workout_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets(
    'Start Running creates a default distance session and opens active route',
    (tester) async {
      final notifier = _FakeRunningSetupNotifier();

      await _pumpScreen(tester, notifier);

      await tester.tap(find.text('Start Running'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(notifier.startCalls, 1);
      expect(notifier.lastGoalType, GoalType.distance);
      expect(notifier.lastTargetDistance, 5);
      expect(notifier.lastTargetDuration, isNull);
      expect(find.text('route:running-active'), findsOneWidget);
    },
  );

  testWidgets(
    'Duration goal starts a duration session and opens active route',
    (tester) async {
      final notifier = _FakeRunningSetupNotifier();

      await _pumpScreen(tester, notifier);

      await tester.tap(find.text('Duration'));
      await tester.pump();
      await tester.tap(find.text('Start Running'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(notifier.startCalls, 1);
      expect(notifier.lastGoalType, GoalType.duration);
      expect(notifier.lastTargetDistance, isNull);
      expect(notifier.lastTargetDuration, 30);
      expect(find.text('route:running-active'), findsOneWidget);
    },
  );

  testWidgets('distance target slider value is passed to started session', (
    tester,
  ) async {
    final distanceNotifier = _FakeRunningSetupNotifier();
    await _pumpScreen(tester, distanceNotifier);

    tester.widget<Slider>(find.byType(Slider)).onChanged!(12.5);
    await tester.pump();
    expect(find.text('12.5 km'), findsOneWidget);

    await tester.tap(find.text('Start Running'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(distanceNotifier.lastGoalType, GoalType.distance);
    expect(distanceNotifier.lastTargetDistance, 12.5);
    expect(distanceNotifier.lastTargetDuration, isNull);
  });

  testWidgets('duration target slider value is passed to started session', (
    tester,
  ) async {
    final durationNotifier = _FakeRunningSetupNotifier();
    await _pumpScreen(tester, durationNotifier);

    await tester.tap(
      find.ancestor(
        of: find.text('Duration'),
        matching: find.byType(GestureDetector),
      ),
    );
    await tester.pump();
    tester.widget<Slider>(find.byType(Slider)).onChanged!(75);
    await tester.pump();
    expect(find.text('75 min'), findsOneWidget);

    await tester.tap(find.text('Start Running'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(durationNotifier.lastGoalType, GoalType.duration);
    expect(durationNotifier.lastTargetDistance, isNull);
    expect(durationNotifier.lastTargetDuration, 75);
  });

  testWidgets('start failure keeps setup visible with retry feedback', (
    tester,
  ) async {
    final notifier = _FakeRunningSetupNotifier(throwOnStart: true);

    await _pumpScreen(tester, notifier);

    await tester.tap(find.text('Start Running'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(notifier.startCalls, 1);
    expect(find.text('Running Setup'), findsOneWidget);
    expect(find.text('route:running-active'), findsNothing);
    expect(
      find.text(
        'Could not start running. Sign in and check your connection, then try again.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Start Running'),
          )
          .onPressed,
      isNotNull,
    );
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _FakeRunningSetupNotifier notifier,
) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [runningSessionProvider.overrideWith((ref) => notifier)],
      child: MaterialApp(
        home: const RunningSetupScreen(),
        routes: {
          '/workout/running/active': (_) =>
              const Scaffold(body: Text('route:running-active')),
        },
      ),
    ),
  );
  await tester.pump();
}

class _FakeRunningSetupNotifier extends RunningSessionNotifier {
  _FakeRunningSetupNotifier({this.throwOnStart = false})
    : super(
        gpsService: _NoopGpsTrackingService(),
        timerService: _NoopTimerService(),
        hrService: _NoopHeartRateService(),
        calorieService: CalorieCalculatorService(),
        sessionService: _NoopWorkoutSessionService(),
        phoneStepCounterService: _NoopPhoneStepCounterService(),
        phoneDataListener: _NoopPhoneDataListener(),
        readCurrentUserId: () => 'user-1',
      );

  final bool throwOnStart;
  int startCalls = 0;
  GoalType? lastGoalType;
  double? lastTargetDistance;
  int? lastTargetDuration;

  @override
  Future<void> startSession({
    required GoalType goalType,
    double? targetDistance,
    int? targetDuration,
    MoodRating? preMood,
  }) async {
    startCalls++;
    lastGoalType = goalType;
    lastTargetDistance = targetDistance;
    lastTargetDuration = targetDuration;

    if (throwOnStart) {
      throw StateError('start failed');
    }

    state = RunningSession(
      id: 'run-setup-$startCalls',
      userId: 'user-1',
      startTime: DateTime(2026, 1, 1),
      goalType: goalType,
      targetDistance: targetDistance,
      targetDuration: targetDuration,
    );
  }
}

class _NoopGpsTrackingService implements GPSTrackingService {
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
  Future<LatLng> getCurrentLocation() async => const LatLng(0, 0);

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

class _NoopPhoneStepCounterService implements PhoneStepCounterService {
  final StreamController<int> _controller = StreamController<int>.broadcast();

  @override
  Stream<int> get stepStream => _controller.stream;

  @override
  int get totalSteps => 0;

  @override
  void dispose() {
    _controller.close();
  }

  @override
  void resetSteps() {}

  @override
  Future<void> startCounting() async {}

  @override
  Future<void> stopCounting() async {}
}

class _NoopPhoneDataListener implements PhoneDataListener {
  final StreamController<HeartRateData> _heartRateController =
      StreamController<HeartRateData>.broadcast();
  final StreamController<SensorBatch> _sensorBatchController =
      StreamController<SensorBatch>.broadcast();

  @override
  Stream<HeartRateData> get heartRateStream => _heartRateController.stream;

  @override
  Stream<SensorBatch> get sensorBatchStream => _sensorBatchController.stream;

  @override
  Future<bool> isWatchConnected() async => false;

  @override
  Future<bool> startListening() async => true;

  @override
  Future<void> stopListening() async {}

  @override
  void dispose() {
    _heartRateController.close();
    _sensorBatchController.close();
  }
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
