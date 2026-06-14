import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/walking_session.dart';
import '../models/mood_rating.dart';
import '../models/mission.dart';
import '../models/workout_session.dart';
import '../services/gps_tracking_service.dart';
import '../services/timer_service.dart';
import '../services/heart_rate_service.dart';
import '../services/calorie_calculator_service.dart';
import '../services/workout_session_service.dart';
import 'running_session_provider.dart';

/// Provider for managing walking workout sessions
class WalkingSessionNotifier extends StateNotifier<WalkingSession?> {
  final GPSTrackingService _gpsService;
  final TimerService _timerService;
  final HeartRateService _hrService;
  final CalorieCalculatorService _calorieService;
  final WorkoutSessionService _sessionService;
  final String? Function() _readCurrentUserId;

  StreamSubscription<LatLng>? _gpsSubscription;
  StreamSubscription<int>? _timerSubscription;
  StreamSubscription<int>? _hrSubscription;
  Timer? _metricsUpdateTimer;

  WalkingSessionNotifier({
    required GPSTrackingService gpsService,
    required TimerService timerService,
    required HeartRateService hrService,
    required CalorieCalculatorService calorieService,
    required WorkoutSessionService sessionService,
    required String? Function() readCurrentUserId,
  }) : _gpsService = gpsService,
       _timerService = timerService,
       _hrService = hrService,
       _calorieService = calorieService,
       _sessionService = sessionService,
       _readCurrentUserId = readCurrentUserId,
       super(null);

  /// Starts a new walking session
  Future<void> startSession({
    required WalkingMode mode,
    int? targetDuration,
    Mission? mission,
    MoodRating? preMood,
  }) async {
    final userId = requireWorkoutSessionUserId(_readCurrentUserId);
    final session = WalkingSession(
      id: const Uuid().v4(),
      userId: userId,
      startTime: DateTime.now(),
      mode: mode,
      targetDuration: targetDuration,
      mission: mission,
      preMood: preMood,
    );

    await _sessionService.createSession(session);

    state = session;

    // Start services
    await _gpsService.startTracking();
    _timerService.start();
    await _hrService.startMonitoring();

    // Subscribe to GPS updates
    _gpsSubscription = _gpsService.locationStream.listen((location) {
      _updateLocation(location);
      if (mission != null) {
        _checkMissionCompletion();
      }
    });

    // Subscribe to timer updates
    _timerSubscription = _timerService.timerStream.listen((seconds) {
      _updateDuration(seconds);
    });

    // Subscribe to heart rate updates
    _hrSubscription = _hrService.heartRateStream.listen((hr) {
      _updateHeartRate(hr);
    });

    // Update metrics every second
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

    // Estimate steps (rough calculation: ~1300 steps per km)
    final steps = (distance * 1300).round();

    state = state!.copyWith(
      routePoints: updatedPoints,
      currentDistance: distance,
      steps: steps,
    );
  }

  /// Updates duration
  void _updateDuration(int seconds) {
    if (state == null) return;

    state = state!.copyWith(durationSeconds: seconds);
  }

  /// Updates heart rate
  void _updateHeartRate(int hr) {
    if (state == null) return;

    state = state!.copyWith(
      avgHeartRate: _hrService.avgHeartRate,
      maxHeartRate: _hrService.maxHeartRate,
      heartRateZones: _hrService.heartRateZones,
    );
  }

  /// Updates all metrics (calories)
  void _updateMetrics() {
    if (state == null) return;

    // Calculate calories
    final durationMinutes = (state!.durationSeconds ?? 0) / 60.0;
    final calories = _calorieService.calculateCalories(
      workoutType: WorkoutType.walking,
      durationMinutes: durationMinutes.round(),
      distanceKm: state!.currentDistance,
      avgHeartRate: state!.avgHeartRate,
    );

    state = state!.copyWith(caloriesBurned: calories);
  }

  /// Checks if mission is completed
  bool _checkMissionCompletion() {
    if (state == null || state!.mission == null || state!.routePoints.isEmpty) {
      return false;
    }

    final currentLocation = state!.routePoints.last;
    final isCompleted = state!.mission!.isCompleted(currentLocation);

    if (isCompleted && !state!.missionCompleted) {
      state = state!.copyWith(missionCompleted: true);
      // Auto-end workout when mission is completed
      endSession();
    }

    return isCompleted;
  }

  /// Pauses the walking session
  void pauseSession() {
    if (state == null) return;

    _timerService.pause();
    _gpsService.stopTracking();
    _hrService.stopMonitoring();
    _metricsUpdateTimer?.cancel();

    state = state!.copyWith(status: WorkoutStatus.paused);
  }

  /// Resumes the walking session
  Future<void> resumeSession() async {
    if (state == null) return;

    _timerService.resume();
    await _gpsService.startTracking();
    await _hrService.startMonitoring();

    _metricsUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateMetrics(),
    );

    state = state!.copyWith(status: WorkoutStatus.active);
  }

  /// Ends the walking session
  Future<void> endSession({MoodRating? postMood}) async {
    if (state == null) return;

    _timerService.stop();
    await _gpsService.stopTracking();
    await _hrService.stopMonitoring();
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

    // Save final session to database
    await _sessionService.saveSession(state!);
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _timerSubscription?.cancel();
    _hrSubscription?.cancel();
    _metricsUpdateTimer?.cancel();
    _gpsService.dispose();
    _timerService.dispose();
    _hrService.dispose();
    super.dispose();
  }
}

/// Provider for walking session state
final walkingSessionProvider =
    StateNotifierProvider<WalkingSessionNotifier, WalkingSession?>(
      (ref) => WalkingSessionNotifier(
        gpsService: ref.watch(gpsTrackingServiceProvider),
        timerService: ref.watch(timerServiceProvider),
        hrService: ref.watch(heartRateServiceProvider),
        calorieService: ref.watch(calorieCalculatorServiceProvider),
        sessionService: ref.watch(workoutSessionServiceProvider),
        readCurrentUserId: () => ref.read(workoutSessionUserIdProvider),
      ),
    );
