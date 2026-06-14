import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/running_session.dart';
import '../models/mood_rating.dart';
import '../models/workout_session.dart';
import '../services/gps_tracking_service.dart';
import '../services/timer_service.dart';
import '../services/heart_rate_service.dart';
import '../services/calorie_calculator_service.dart';
import '../services/workout_session_service.dart';
import '../services/phone_step_counter_service.dart';
import '../services/phone_data_listener.dart';

/// Provider for GPS tracking service
final gpsTrackingServiceProvider = Provider((ref) => GPSTrackingService());

/// Provider for timer service
final timerServiceProvider = Provider((ref) => TimerService());

/// Provider for heart rate service
final heartRateServiceProvider = Provider((ref) => HeartRateService());

/// Provider for calorie calculator service
final calorieCalculatorServiceProvider = Provider(
  (ref) => CalorieCalculatorService(),
);

/// Provider for workout session service
final workoutSessionServiceProvider = Provider(
  (ref) => WorkoutSessionService(),
);

/// Provider for resolving the current signed-in user for workout ownership.
final workoutSessionUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

String requireWorkoutSessionUserId(String? Function() readCurrentUserId) {
  final userId = readCurrentUserId();
  if (userId == null || userId.trim().isEmpty) {
    throw StateError(
      'A signed-in Supabase user is required before starting a workout.',
    );
  }
  return userId;
}

/// Provider for phone data listener (for smartwatch data)
final phoneDataListenerProvider = Provider((ref) => PhoneDataListener());

/// Provider for phone step counter service (uses phone's accelerometer)
final phoneStepCounterServiceProvider = Provider<PhoneStepCounterService>((
  ref,
) {
  return PhoneStepCounterService();
});

/// Provider for managing running workout sessions
class RunningSessionNotifier extends StateNotifier<RunningSession?> {
  final GPSTrackingService _gpsService;
  final TimerService _timerService;
  final HeartRateService _hrService;
  final CalorieCalculatorService _calorieService;
  final WorkoutSessionService _sessionService;
  final PhoneStepCounterService _phoneStepCounterService;
  final PhoneDataListener _phoneDataListener;
  final String? Function() _readCurrentUserId;

  StreamSubscription<LatLng>? _gpsSubscription;
  StreamSubscription<int>? _timerSubscription;
  StreamSubscription? _hrSubscription;
  StreamSubscription<int>? _stepSubscription;
  Timer? _metricsUpdateTimer;

  RunningSessionNotifier({
    required GPSTrackingService gpsService,
    required TimerService timerService,
    required HeartRateService hrService,
    required CalorieCalculatorService calorieService,
    required WorkoutSessionService sessionService,
    required PhoneStepCounterService phoneStepCounterService,
    required PhoneDataListener phoneDataListener,
    required String? Function() readCurrentUserId,
  }) : _gpsService = gpsService,
       _timerService = timerService,
       _hrService = hrService,
       _calorieService = calorieService,
       _sessionService = sessionService,
       _phoneStepCounterService = phoneStepCounterService,
       _phoneDataListener = phoneDataListener,
       _readCurrentUserId = readCurrentUserId,
       super(null);

  /// Starts a new running session
  Future<void> startSession({
    required GoalType goalType,
    double? targetDistance,
    int? targetDuration,
    MoodRating? preMood,
  }) async {
    final userId = requireWorkoutSessionUserId(_readCurrentUserId);
    final session = RunningSession(
      id: const Uuid().v4(),
      userId: userId,
      startTime: DateTime.now(),
      goalType: goalType,
      targetDistance: targetDistance,
      targetDuration: targetDuration,
      preMood: preMood,
    );

    await _sessionService.createSession(session);

    state = session;

    // Start services
    await _gpsService.startTracking();
    _timerService.start(); // Timer starts from 0
    await _hrService.startMonitoring();

    // Start phone step counter using phone's accelerometer
    try {
      await _phoneStepCounterService.startCounting();
      _phoneStepCounterService.resetSteps(); // Reset steps to 0 at start
    } catch (e) {
      debugPrint('⚠️ Phone step counter not available: $e');
    }

    // Subscribe to GPS updates for real distance tracking
    _gpsSubscription = _gpsService.locationStream.listen((location) {
      _updateLocation(location);
    });

    // Subscribe to timer updates for real duration
    _timerSubscription = _timerService.timerStream.listen((seconds) {
      _updateDuration(seconds);
    });

    // Subscribe to heart rate updates from smartwatch via PhoneDataListener
    _hrSubscription = _phoneDataListener.heartRateStream.listen((hrData) {
      // Update heart rate service with real BPM data from watch
      final bpm = hrData.bpm;
      if (bpm != null) {
        _hrService.updateHeartRate(bpm);
        // Update session state
        _updateHeartRate(bpm);
      }
    });

    // Subscribe to phone step counter updates
    try {
      _stepSubscription = _phoneStepCounterService.stepStream.listen((steps) {
        debugPrint(
          '👟 RunningSession: Received step update from phone: $steps',
        );
        _updateSteps(steps);
      });
      debugPrint('✅ RunningSession: Subscribed to phone step counter stream');
    } catch (e) {
      debugPrint('⚠️ Phone step counter stream not available: $e');
    }

    // Update metrics every second for real-time calorie calculation
    _metricsUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateMetrics(),
    );
  }

  /// Updates location and route
  void _updateLocation(LatLng location) {
    if (state == null) return;

    final updatedPoints = [...state!.routePoints, location];
    final distance = _gpsService.calculateRouteDistance(updatedPoints);

    state = state!.copyWith(
      routePoints: updatedPoints,
      currentDistance: distance,
    );
  }

  /// Updates duration
  void _updateDuration(int seconds) {
    if (state == null) return;

    state = state!.copyWith(durationSeconds: seconds);
  }

  /// Updates heart rate from smartwatch
  void _updateHeartRate(int hr) {
    if (state == null) return;

    state = state!.copyWith(
      avgHeartRate: _hrService.avgHeartRate,
      maxHeartRate: _hrService.maxHeartRate,
      heartRateZones: _hrService.heartRateZones,
    );
  }

  /// Updates step count from Android native layer
  void _updateSteps(int steps) {
    if (state == null) return;

    debugPrint('👟 RunningSession: Updating steps to $steps');
    state = state!.copyWith(steps: steps);
  }

  /// Updates all metrics (pace, calories) with real data
  void _updateMetrics() {
    if (state == null) return;

    // Calculate real pace from actual distance and duration
    final durationMinutes = (state!.durationSeconds ?? 0) / 60.0;
    final pace = state!.currentDistance > 0
        ? durationMinutes / state!.currentDistance
        : null;

    // Calculate real calories using actual distance, duration, and heart rate
    final calories = _calorieService.calculateCalories(
      workoutType: WorkoutType.running,
      durationMinutes: durationMinutes.round(),
      distanceKm: state!.currentDistance, // Real GPS distance
      avgHeartRate: state!.avgHeartRate, // Real smartwatch BPM
    );

    state = state!.copyWith(avgPace: pace, caloriesBurned: calories);
  }

  /// Pauses the running session
  void pauseSession() {
    if (state == null) return;

    _timerService.pause();
    _gpsService.stopTracking();
    _hrService.stopMonitoring();

    // Stop phone step counter if available
    try {
      _phoneStepCounterService.stopCounting();
    } catch (e) {
      debugPrint('⚠️ Could not stop phone step counter: $e');
    }

    _metricsUpdateTimer?.cancel();

    state = state!.copyWith(status: WorkoutStatus.paused);
  }

  /// Resumes the running session
  Future<void> resumeSession() async {
    if (state == null) return;

    _timerService.resume();
    await _gpsService.startTracking();
    await _hrService.startMonitoring();

    // Resume phone step counter if available
    try {
      await _phoneStepCounterService.startCounting();
    } catch (e) {
      debugPrint('⚠️ Could not resume phone step counter: $e');
    }

    _metricsUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateMetrics(),
    );

    state = state!.copyWith(status: WorkoutStatus.active);
  }

  /// Ends the running session
  Future<void> endSession({MoodRating? postMood}) async {
    if (state == null) return;

    _timerService.stop();
    await _gpsService.stopTracking();
    await _hrService.stopMonitoring();

    // Stop phone step counter if available
    try {
      await _phoneStepCounterService.stopCounting();
    } catch (e) {
      debugPrint('⚠️ Could not stop phone step counter: $e');
    }

    _metricsUpdateTimer?.cancel();

    final moodChange = postMood != null && state!.preMood != null
        ? postMood.value - state!.preMood!.value
        : null;

    state = state!.copyWith(
      endTime: DateTime.now(),
      postMood: postMood,
      moodChange: moodChange,
      status: WorkoutStatus.completed,
    );

    await _sessionService.saveSession(state!);

    // Reset timer for next session
    _timerService.reset();
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _timerSubscription?.cancel();
    _hrSubscription?.cancel();
    _stepSubscription?.cancel();
    _metricsUpdateTimer?.cancel();
    _gpsService.dispose();
    _timerService.dispose();
    _hrService.dispose();

    // Dispose phone step counter if available
    try {
      _phoneStepCounterService.dispose();
    } catch (e) {
      debugPrint('⚠️ Could not dispose phone step counter: $e');
    }

    super.dispose();
  }
}

/// Provider for running session state
final runningSessionProvider =
    StateNotifierProvider<RunningSessionNotifier, RunningSession?>(
      (ref) => RunningSessionNotifier(
        gpsService: ref.watch(gpsTrackingServiceProvider),
        timerService: ref.watch(timerServiceProvider),
        hrService: ref.watch(heartRateServiceProvider),
        calorieService: ref.watch(calorieCalculatorServiceProvider),
        sessionService: ref.watch(workoutSessionServiceProvider),
        phoneStepCounterService: ref.watch(phoneStepCounterServiceProvider),
        phoneDataListener: ref.watch(phoneDataListenerProvider),
        readCurrentUserId: () => ref.read(workoutSessionUserIdProvider),
      ),
    );
