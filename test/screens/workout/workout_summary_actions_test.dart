import 'dart:async';
import 'dart:ui' as ui;

import 'package:flowfit/models/exercise_progress.dart';
import 'package:flowfit/models/heart_rate_data.dart';
import 'package:flowfit/models/mission.dart';
import 'package:flowfit/models/resistance_session.dart';
import 'package:flowfit/models/running_session.dart';
import 'package:flowfit/models/sensor_batch.dart';
import 'package:flowfit/models/walking_session.dart';
import 'package:flowfit/models/workout_session.dart';
import 'package:flowfit/providers/resistance_session_provider.dart';
import 'package:flowfit/providers/running_session_provider.dart';
import 'package:flowfit/providers/walking_session_provider.dart';
import 'package:flowfit/screens/workout/resistance/resistance_summary_screen.dart';
import 'package:flowfit/screens/workout/running/running_summary_screen.dart';
import 'package:flowfit/screens/workout/running/share_achievement_screen.dart';
import 'package:flowfit/screens/workout/walking/walking_summary_screen.dart';
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
  testWidgets('running summary saves workout and returns to dashboard', (
    tester,
  ) async {
    final sessionService = _FakeWorkoutSessionService();
    final notifier = _FakeRunningSessionNotifier(_runningSession());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runningSessionProvider.overrideWith((ref) => notifier),
          workoutSessionServiceProvider.overrideWithValue(sessionService),
        ],
        child: MaterialApp(
          home: const RunningSummaryScreen(),
          routes: {
            '/dashboard': (_) => const Scaffold(body: Text('route:dashboard')),
          },
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Save to History'), 300);
    await tester.tap(find.text('Save to History'));
    await tester.pumpAndSettle();

    expect(sessionService.savedSessions, hasLength(1));
    expect(sessionService.savedSessions.single.id, 'run-1');
    expect(find.text('route:dashboard'), findsOneWidget);
  });

  testWidgets('running summary opens share achievement route with session', (
    tester,
  ) async {
    final notifier = _FakeRunningSessionNotifier(_runningSession());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [runningSessionProvider.overrideWith((ref) => notifier)],
        child: MaterialApp(
          home: const RunningSummaryScreen(),
          onGenerateRoute: (settings) {
            if (settings.name == '/workout/running/share') {
              final args = settings.arguments! as Map<String, dynamic>;
              final session = args['session']! as RunningSession;
              return MaterialPageRoute<void>(
                builder: (_) =>
                    Scaffold(body: Text('route:running-share:${session.id}')),
              );
            }
            return null;
          },
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Share Achievement'), 300);
    await tester.tap(find.text('Share Achievement'));
    await tester.pumpAndSettle();

    expect(find.text('route:running-share:run-1'), findsOneWidget);
  });

  testWidgets('running summary empty state can return to dashboard', (
    tester,
  ) async {
    final notifier = _EmptyRunningSessionNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [runningSessionProvider.overrideWith((ref) => notifier)],
        child: MaterialApp(
          initialRoute: '/summary',
          routes: {
            '/': (_) => const Scaffold(body: Text('route:root')),
            '/summary': (_) => const RunningSummaryScreen(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No session data available'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Back to Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('route:root'), findsOneWidget);
  });

  testWidgets('walking summary saves workout before returning to first route', (
    tester,
  ) async {
    final sessionService = _FakeWorkoutSessionService();
    final notifier = _FakeWalkingSessionNotifier(_walkingSession());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walkingSessionProvider.overrideWith((ref) => notifier),
          workoutSessionServiceProvider.overrideWithValue(sessionService),
        ],
        child: MaterialApp(
          initialRoute: '/summary',
          routes: {
            '/': (_) => const Scaffold(body: Text('route:root')),
            '/summary': (_) => const WalkingSummaryScreen(),
          },
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Save to History'), 300);
    await tester.tap(find.text('Save to History'));
    await tester.pumpAndSettle();

    expect(sessionService.savedSessions, hasLength(1));
    expect(sessionService.savedSessions.single.id, 'walk-1');
    expect(find.text('route:root'), findsOneWidget);
    expect(find.text('Workout saved successfully!'), findsOneWidget);
  });

  testWidgets('walking summary empty state can return to dashboard', (
    tester,
  ) async {
    final notifier = _EmptyWalkingSessionNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [walkingSessionProvider.overrideWith((ref) => notifier)],
        child: MaterialApp(
          initialRoute: '/summary',
          routes: {
            '/': (_) => const Scaffold(body: Text('route:root')),
            '/summary': (_) => const WalkingSummaryScreen(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No session data available'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Back to Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('route:root'), findsOneWidget);
  });

  testWidgets('walking summary ignores duplicate save taps while saving', (
    tester,
  ) async {
    final saveCompleter = Completer<void>();
    final sessionService = _FakeWorkoutSessionService(
      saveCompleter: saveCompleter,
    );
    final notifier = _FakeWalkingSessionNotifier(_walkingSession());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walkingSessionProvider.overrideWith((ref) => notifier),
          workoutSessionServiceProvider.overrideWithValue(sessionService),
        ],
        child: MaterialApp(
          initialRoute: '/summary',
          routes: {
            '/': (_) => const Scaffold(body: Text('route:root')),
            '/summary': (_) => const WalkingSummaryScreen(),
          },
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Save to History'), 300);
    await tester.tap(find.text('Save to History'));
    await tester.tap(find.text('Save to History'), warnIfMissed: false);
    await tester.pump();

    expect(sessionService.saveCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('route:root'), findsNothing);

    saveCompleter.complete();
    await tester.pumpAndSettle();

    expect(sessionService.savedSessions, hasLength(1));
    expect(find.text('route:root'), findsOneWidget);
  });

  testWidgets(
    'walking summary creates the next mission from completed mission',
    (tester) async {
      final notifier = _FakeWalkingSessionNotifier(
        _walkingSession(
          mission: _mission(MissionType.sanctuary),
          missionCompleted: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walkingSessionProvider.overrideWith((ref) => notifier),
            gpsTrackingServiceProvider.overrideWithValue(
              _NoopGpsTrackingService(),
            ),
          ],
          child: MaterialApp(
            initialRoute: '/summary',
            routes: {
              '/': (_) => const Scaffold(body: Text('route:root')),
              '/summary': (_) => const WalkingSummaryScreen(),
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(find.text('Create Next Mission'), 300);
      await tester.tap(find.text('Create Next Mission'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Create Mission'), findsOneWidget);
      expect(find.text('Destination Walk'), findsOneWidget);
    },
  );

  testWidgets('resistance summary retries sync and returns to dashboard', (
    tester,
  ) async {
    final notifier = _FakeResistanceSessionNotifier(_resistanceSession());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [resistanceSessionProvider.overrideWith((ref) => notifier)],
        child: MaterialApp(
          initialRoute: '/summary',
          routes: {
            '/': (_) => const Scaffold(body: Text('route:root')),
            '/summary': (_) => const ResistanceSummaryScreen(),
          },
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Retry Sync'), 300);
    await tester.tap(find.text('Retry Sync'));
    await tester.pumpAndSettle();

    expect(notifier.retryCalls, 1);
    expect(find.text('Workout synced.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Back to Dashboard'), 300);
    await tester.tap(find.widgetWithText(FilledButton, 'Back to Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('route:root'), findsOneWidget);
  });

  testWidgets(
    'resistance summary retry failure keeps recovery action visible',
    (tester) async {
      final notifier = _FakeResistanceSessionNotifier(
        _resistanceSession(),
        throwOnRetry: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resistanceSessionProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            initialRoute: '/summary',
            routes: {
              '/': (_) => const Scaffold(body: Text('route:root')),
              '/summary': (_) => const ResistanceSummaryScreen(),
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(find.text('Retry Sync'), 300);
      await tester.tap(find.text('Retry Sync'));
      await tester.pump();

      expect(notifier.retryCalls, 1);
      expect(
        find.text('Workout sync failed. Check your connection and retry.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'Retry Sync'), findsOneWidget);
      expect(find.text('route:root'), findsNothing);
    },
  );

  testWidgets('resistance summary empty state can return to dashboard', (
    tester,
  ) async {
    final notifier = _FakeResistanceSessionNotifier(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [resistanceSessionProvider.overrideWith((ref) => notifier)],
        child: MaterialApp(
          initialRoute: '/summary',
          routes: {
            '/': (_) => const Scaffold(body: Text('route:root')),
            '/summary': (_) => const ResistanceSummaryScreen(),
          },
        ),
      ),
    );

    expect(find.text('No completed workout available'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Back to Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('route:root'), findsOneWidget);
  });

  test('share route painter handles a single GPS point', () {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    RoutePolylinePainter(
      routePoints: const [LatLng(14.5995, 120.9842)],
      polylineColor: Colors.blue,
      polylineWidth: 8,
    ).paint(canvas, const Size(320, 568));

    recorder.endRecording().dispose();
  });

  test('share route painter handles flat GPS lines', () {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    RoutePolylinePainter(
      routePoints: const [
        LatLng(14.5995, 120.9842),
        LatLng(14.5995, 120.9850),
        LatLng(14.5995, 120.9860),
      ],
      polylineColor: Colors.blue,
      polylineWidth: 8,
    ).paint(canvas, const Size(320, 568));

    recorder.endRecording().dispose();
  });
}

RunningSession _runningSession() {
  return RunningSession(
    id: 'run-1',
    userId: 'user-1',
    startTime: DateTime(2026, 1, 1),
    goalType: GoalType.distance,
    targetDistance: 5,
    durationSeconds: 600,
    currentDistance: 1.5,
    avgPace: 6.4,
    steps: 1800,
    caloriesBurned: 120,
  );
}

WalkingSession _walkingSession({
  Mission? mission,
  bool missionCompleted = false,
}) {
  return WalkingSession(
    id: 'walk-1',
    userId: 'user-1',
    startTime: DateTime(2026, 1, 1),
    mode: mission == null ? WalkingMode.free : WalkingMode.mission,
    targetDuration: 30,
    durationSeconds: 900,
    currentDistance: 1.1,
    steps: 1500,
    caloriesBurned: 80,
    mission: mission,
    missionCompleted: missionCompleted,
  );
}

Mission _mission(MissionType type) {
  return Mission(
    id: 'mission-1',
    type: type,
    targetLocation: const LatLng(14.5995, 120.9842),
    targetDistance: type == MissionType.target ? 500 : null,
    radius: type == MissionType.safetyNet ? 100 : null,
    name: type.displayName,
  );
}

ResistanceSession _resistanceSession() {
  final exercise = ExerciseProgress(
    exerciseName: 'Bench Press',
    emoji: 'BP',
    totalSets: 1,
    targetReps: 10,
    completedSets: [
      SetData(reps: 10, weight: 40, completedAt: DateTime(2026, 1, 1)),
    ],
  );

  return ResistanceSession(
    id: 'resistance-1',
    userId: 'user-1',
    startTime: DateTime(2026, 1, 1),
    split: BodySplit.upper,
    exercises: [exercise],
    durationSeconds: 900,
    totalVolumeKg: 400,
    caloriesBurned: 90,
  );
}

class _FakeWorkoutSessionService implements WorkoutSessionService {
  _FakeWorkoutSessionService({this.saveCompleter});

  final Completer<void>? saveCompleter;
  final List<WorkoutSession> savedSessions = [];
  int saveCalls = 0;

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
  }) async => const [];

  @override
  Future<List<WorkoutSession>> listRecentSessions({
    int limit = 20,
    WorkoutType? type,
  }) async => const [];

  @override
  Future<void> saveSession(WorkoutSession session) async {
    saveCalls++;
    final completer = saveCompleter;
    if (completer != null) {
      await completer.future;
    }
    savedSessions.add(session);
  }

  @override
  Future<void> updateSession(WorkoutSession session) async {}
}

class _FakeRunningSessionNotifier extends RunningSessionNotifier {
  _FakeRunningSessionNotifier(RunningSession initial)
    : super(
        gpsService: _NoopGpsTrackingService(),
        timerService: _NoopTimerService(),
        hrService: _NoopHeartRateService(),
        calorieService: CalorieCalculatorService(),
        sessionService: _FakeWorkoutSessionService(),
        phoneStepCounterService: _NoopPhoneStepCounterService(),
        phoneDataListener: _NoopPhoneDataListener(),
        readCurrentUserId: () => 'user-1',
      ) {
    state = initial;
  }
}

class _EmptyRunningSessionNotifier extends RunningSessionNotifier {
  _EmptyRunningSessionNotifier()
    : super(
        gpsService: _NoopGpsTrackingService(),
        timerService: _NoopTimerService(),
        hrService: _NoopHeartRateService(),
        calorieService: CalorieCalculatorService(),
        sessionService: _FakeWorkoutSessionService(),
        phoneStepCounterService: _NoopPhoneStepCounterService(),
        phoneDataListener: _NoopPhoneDataListener(),
        readCurrentUserId: () => 'user-1',
      );
}

class _FakeWalkingSessionNotifier extends WalkingSessionNotifier {
  _FakeWalkingSessionNotifier(WalkingSession initial)
    : super(
        gpsService: _NoopGpsTrackingService(),
        timerService: _NoopTimerService(),
        hrService: _NoopHeartRateService(),
        calorieService: CalorieCalculatorService(),
        sessionService: _FakeWorkoutSessionService(),
        readCurrentUserId: () => 'user-1',
      ) {
    state = initial;
  }
}

class _EmptyWalkingSessionNotifier extends WalkingSessionNotifier {
  _EmptyWalkingSessionNotifier()
    : super(
        gpsService: _NoopGpsTrackingService(),
        timerService: _NoopTimerService(),
        hrService: _NoopHeartRateService(),
        calorieService: CalorieCalculatorService(),
        sessionService: _FakeWorkoutSessionService(),
        readCurrentUserId: () => 'user-1',
      );
}

class _FakeResistanceSessionNotifier extends ResistanceSessionNotifier {
  _FakeResistanceSessionNotifier(
    ResistanceSession? initial, {
    this.throwOnRetry = false,
  }) : super(
         timerService: _NoopTimerService(),
         countdownService: _NoopCountdownTimerService(),
         hrService: _NoopHeartRateService(),
         calorieService: CalorieCalculatorService(),
         sessionService: _FakeWorkoutSessionService(),
         readCurrentUserId: () => 'user-1',
       ) {
    state = initial;
  }

  final bool throwOnRetry;
  int retryCalls = 0;

  @override
  Future<void> retrySaveSession() async {
    retryCalls++;
    if (throwOnRetry) {
      throw StateError('sync unavailable');
    }
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

class _NoopCountdownTimerService implements CountdownTimerService {
  final StreamController<int> _controller = StreamController<int>.broadcast();

  @override
  String get formattedTime => '00:00';

  @override
  bool get isRunning => false;

  @override
  int get remainingSeconds => 0;

  @override
  Stream<int> get timerStream => _controller.stream;

  @override
  void dispose() {
    _controller.close();
  }

  @override
  void skip() {}

  @override
  void start(int seconds) {}

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
