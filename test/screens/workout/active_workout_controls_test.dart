import 'dart:async';

import 'package:flowfit/features/activity_classifier/domain/activity.dart';
import 'package:flowfit/features/activity_classifier/domain/classify_activity_usecase.dart';
import 'package:flowfit/features/activity_classifier/platform/tflite_activity_classifier.dart';
import 'package:flowfit/features/activity_classifier/presentation/providers.dart';
import 'package:flowfit/models/exercise_progress.dart';
import 'package:flowfit/models/heart_rate_data.dart';
import 'package:flowfit/models/mood_rating.dart';
import 'package:flowfit/models/resistance_session.dart';
import 'package:flowfit/models/running_session.dart';
import 'package:flowfit/models/sensor_batch.dart';
import 'package:flowfit/models/walking_session.dart';
import 'package:flowfit/models/workout_session.dart';
import 'package:flowfit/providers/resistance_session_provider.dart';
import 'package:flowfit/providers/running_session_provider.dart';
import 'package:flowfit/providers/walking_session_provider.dart';
import 'package:flowfit/screens/workout/resistance/active_resistance_screen.dart';
import 'package:flowfit/screens/workout/running/active_running_screen.dart';
import 'package:flowfit/screens/workout/walking/active_walking_screen.dart';
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
import 'package:provider/provider.dart' as provider;
import 'package:solar_icons/solar_icons.dart';

void main() {
  testWidgets('active walking pause, resume, and end controls work', (
    tester,
  ) async {
    final notifier = _FakeWalkingSessionNotifier(
      WalkingSession(
        id: 'walk-1',
        userId: 'user-1',
        startTime: DateTime(2026, 1, 1),
        mode: WalkingMode.free,
        targetDuration: 30,
        durationSeconds: 120,
        currentDistance: 0.8,
        steps: 1040,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [walkingSessionProvider.overrideWith((ref) => notifier)],
        child: MaterialApp(
          home: const ActiveWalkingScreen(),
          routes: {
            '/workout/walking/summary': (_) =>
                const Scaffold(body: Text('route:walking-summary')),
          },
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Pause'), 300);
    expect(find.text('Pause'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();

    expect(notifier.pauseCalls, 1);
    expect(find.text('Resume'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();

    expect(notifier.resumeCalls, 1);
    expect(find.text('Pause'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('End'), 300);
    await tester.tap(find.text('End'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End Walk'));
    await tester.pumpAndSettle();

    expect(notifier.endCalls, 1);
    expect(find.text('route:walking-summary'), findsOneWidget);
  });

  testWidgets('active resistance set, rest, and end controls work', (
    tester,
  ) async {
    final exercise = ExerciseProgress(
      exerciseName: 'Bench Press',
      emoji: '🏋️',
      totalSets: 2,
      targetReps: 10,
    );
    final notifier = _FakeResistanceSessionNotifier(
      ResistanceSession(
        id: 'resistance-1',
        userId: 'user-1',
        startTime: DateTime(2026, 1, 1),
        split: BodySplit.upper,
        exercises: [exercise],
        durationSeconds: 90,
      ),
      exercise,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [resistanceSessionProvider.overrideWith((ref) => notifier)],
        child: MaterialApp(
          home: const ActiveResistanceScreen(),
          routes: {
            '/workout/resistance/summary': (_) =>
                const Scaffold(body: Text('route:resistance-summary')),
          },
        ),
      ),
    );

    expect(find.text('Complete Set'), findsOneWidget);

    await tester.tap(find.text('Complete Set'));
    await tester.pumpAndSettle();

    expect(notifier.completeSetCalls, 1);
    expect(find.text('Skip Rest'), findsOneWidget);

    await tester.tap(find.text('Skip Rest'));
    await tester.pumpAndSettle();

    expect(notifier.skipRestCalls, 1);
    expect(find.text('Complete Set'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('End Workout'), 300);
    await tester.tap(find.text('End Workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End Workout').last);
    await tester.pumpAndSettle();

    expect(notifier.endCalls, 1);
    expect(find.text('route:resistance-summary'), findsOneWidget);
  });

  testWidgets('active running tracker, pause, resume, and end controls work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final notifier = _FakeRunningSessionNotifier(
      RunningSession(
        id: 'run-1',
        userId: 'user-1',
        startTime: DateTime(2026, 1, 1),
        goalType: GoalType.distance,
        targetDistance: 5,
        durationSeconds: 120,
        currentDistance: 1.2,
        avgPace: 6.3,
        steps: 1600,
        caloriesBurned: 96,
      ),
    );

    await tester.pumpWidget(_RunningHarness(notifier: notifier));

    expect(find.text('RUNNING'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);

    await tester.tap(find.byIcon(SolarIconsBold.cpu).first);
    await tester.pumpAndSettle();
    expect(find.text('route:activity-classifier'), findsOneWidget);

    Navigator.of(tester.element(find.text('route:activity-classifier'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('RUNNING'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();

    expect(notifier.pauseCalls, 1);
    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();

    expect(notifier.resumeCalls, 1);
    expect(find.text('RUNNING'), findsOneWidget);

    await tester.tap(find.byIcon(SolarIconsBold.stopCircle));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End Workout'));
    await tester.pumpAndSettle();

    expect(notifier.endCalls, 1);
    expect(find.text('route:running-summary'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });
}

class _RunningHarness extends StatelessWidget {
  const _RunningHarness({required this.notifier});

  final _FakeRunningSessionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider<ActivityClassifierViewModel>.value(
          value: _ReadyActivityClassifierViewModel(),
        ),
        provider.Provider<TFLiteActivityClassifier>.value(
          value: _FakeTFLiteActivityClassifier(),
        ),
        provider.Provider<PhoneDataListener>.value(
          value: _NoopPhoneDataListener(),
        ),
      ],
      child: ProviderScope(
        overrides: [runningSessionProvider.overrideWith((ref) => notifier)],
        child: MaterialApp(
          home: const ActiveRunningScreen(),
          routes: {
            '/activity-classifier': (_) =>
                const Scaffold(body: Text('route:activity-classifier')),
            '/workout/running/summary': (_) =>
                const Scaffold(body: Text('route:running-summary')),
          },
        ),
      ),
    );
  }
}

class _FakeWalkingSessionNotifier extends WalkingSessionNotifier {
  _FakeWalkingSessionNotifier(WalkingSession initial)
    : super(
        gpsService: _NoopGpsTrackingService(),
        timerService: _NoopTimerService(),
        hrService: _NoopHeartRateService(),
        calorieService: CalorieCalculatorService(),
        sessionService: _NoopWorkoutSessionService(),
        readCurrentUserId: () => 'user-1',
      ) {
    state = initial;
  }

  int pauseCalls = 0;
  int resumeCalls = 0;
  int endCalls = 0;

  @override
  void pauseSession() {
    pauseCalls++;
    state = state!.copyWith(status: WorkoutStatus.paused);
  }

  @override
  Future<void> resumeSession() async {
    resumeCalls++;
    state = state!.copyWith(status: WorkoutStatus.active);
  }

  @override
  Future<void> endSession({MoodRating? postMood}) async {
    endCalls++;
    state = state!.copyWith(status: WorkoutStatus.completed);
  }
}

class _FakeResistanceSessionNotifier extends ResistanceSessionNotifier {
  _FakeResistanceSessionNotifier(
    ResistanceSession initial,
    ExerciseProgress exercise,
  ) : _currentExercise = exercise,
      super(
        timerService: _NoopTimerService(),
        countdownService: _NoopCountdownTimerService(),
        hrService: _NoopHeartRateService(),
        calorieService: CalorieCalculatorService(),
        sessionService: _NoopWorkoutSessionService(),
        readCurrentUserId: () => 'user-1',
      ) {
    state = initial;
  }

  final ExerciseProgress? _currentExercise;
  bool _resting = false;
  int completeSetCalls = 0;
  int skipRestCalls = 0;
  int endCalls = 0;

  @override
  ExerciseProgress? get currentExercise => _currentExercise;

  @override
  bool get isResting => _resting;

  @override
  void completeSet({int? reps, double? weight}) {
    completeSetCalls++;
    _resting = true;
    state = state!.copyWith(durationSeconds: (state!.durationSeconds ?? 0) + 1);
  }

  @override
  void skipRest() {
    skipRestCalls++;
    _resting = false;
    state = state!.copyWith(durationSeconds: (state!.durationSeconds ?? 0) + 1);
  }

  @override
  Future<void> endWorkout({MoodRating? postMood}) async {
    endCalls++;
    state = state!.copyWith(status: WorkoutStatus.completed);
  }
}

class _FakeRunningSessionNotifier extends RunningSessionNotifier {
  _FakeRunningSessionNotifier(RunningSession initial)
    : super(
        gpsService: _NoopGpsTrackingService(),
        timerService: _NoopTimerService(),
        hrService: _NoopHeartRateService(),
        calorieService: CalorieCalculatorService(),
        sessionService: _NoopWorkoutSessionService(),
        phoneStepCounterService: _NoopPhoneStepCounterService(),
        phoneDataListener: _NoopPhoneDataListener(),
        readCurrentUserId: () => 'user-1',
      ) {
    state = initial;
  }

  int pauseCalls = 0;
  int resumeCalls = 0;
  int endCalls = 0;

  @override
  void pauseSession() {
    pauseCalls++;
    state = state!.copyWith(status: WorkoutStatus.paused);
  }

  @override
  Future<void> resumeSession() async {
    resumeCalls++;
    state = state!.copyWith(status: WorkoutStatus.active);
  }

  @override
  Future<void> endSession({MoodRating? postMood}) async {
    endCalls++;
    state = state!.copyWith(status: WorkoutStatus.completed);
  }
}

class _FakeActivityClassifierRepository
    implements ActivityClassifierRepository {
  @override
  Future<Activity> classifyActivity(List<List<double>> buffer) async {
    return Activity(
      label: 'Cardio',
      confidence: 0.8,
      timestamp: DateTime(2026, 1, 1),
      probabilities: const [0.1, 0.8, 0.1],
    );
  }

  @override
  Future<List<String>> getActivityLabels() async {
    return const ['Stress', 'Cardio', 'Strength'];
  }
}

class _ReadyActivityClassifierViewModel extends ActivityClassifierViewModel {
  _ReadyActivityClassifierViewModel()
    : super(ClassifyActivityUseCase(_FakeActivityClassifierRepository()));

  final Activity _activity = Activity(
    label: 'Cardio',
    confidence: 0.8,
    timestamp: DateTime(2026, 1, 1),
    probabilities: const [0.1, 0.8, 0.1],
  );

  @override
  Activity? get currentActivity => _activity;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  bool get hasError => false;
}

class _FakeTFLiteActivityClassifier extends TFLiteActivityClassifier {
  @override
  bool get isLoaded => true;

  @override
  Future<void> loadModel() async {}

  @override
  Future<List<double>> predict(List<List<double>> buffer) async {
    return const [0.1, 0.8, 0.1];
  }
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
  }) async => const [];

  @override
  Future<List<WorkoutSession>> listRecentSessions({
    int limit = 20,
    WorkoutType? type,
  }) async => const [];

  @override
  Future<void> saveSession(WorkoutSession session) async {}

  @override
  Future<void> updateSession(WorkoutSession session) async {}
}
