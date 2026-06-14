import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/resistance_session.dart';
import '../models/exercise_progress.dart';
import '../models/mood_rating.dart';
import '../models/workout_session.dart';
import '../services/timer_service.dart';
import '../services/heart_rate_service.dart';
import '../services/calorie_calculator_service.dart';
import '../services/workout_session_service.dart';
import 'running_session_provider.dart';

/// Provider for countdown timer service (rest periods)
final countdownTimerServiceProvider = Provider(
  (ref) => CountdownTimerService(),
);

/// Provider for managing resistance training sessions
class ResistanceSessionNotifier extends StateNotifier<ResistanceSession?> {
  final TimerService _timerService;
  final CountdownTimerService _countdownService;
  final HeartRateService _hrService;
  final CalorieCalculatorService _calorieService;
  final WorkoutSessionService _sessionService;

  StreamSubscription<int>? _timerSubscription;
  StreamSubscription<int>? _countdownSubscription;
  StreamSubscription<int>? _hrSubscription;
  Timer? _metricsUpdateTimer;

  int _currentExerciseIndex = 0;
  bool _isResting = false;

  ResistanceSessionNotifier({
    required TimerService timerService,
    required CountdownTimerService countdownService,
    required HeartRateService hrService,
    required CalorieCalculatorService calorieService,
    required WorkoutSessionService sessionService,
  }) : _timerService = timerService,
       _countdownService = countdownService,
       _hrService = hrService,
       _calorieService = calorieService,
       _sessionService = sessionService,
       super(null);

  /// Starts a new resistance training session
  Future<void> startSession({
    required BodySplit split,
    required List<ExerciseProgress> exercises,
    int restTimerSeconds = 90,
    bool audioCuesEnabled = true,
    bool hrMonitorEnabled = false,
    MoodRating? preMood,
  }) async {
    final session = ResistanceSession(
      id: const Uuid().v4(),
      userId: 'current-user-id', // TODO: Get from auth
      startTime: DateTime.now(),
      split: split,
      exercises: exercises,
      restTimerSeconds: restTimerSeconds,
      audioCuesEnabled: audioCuesEnabled,
      hrMonitorEnabled: hrMonitorEnabled,
      preMood: preMood,
    );

    state = session;
    _currentExerciseIndex = 0;

    // Start services
    _timerService.start();
    if (hrMonitorEnabled) {
      await _hrService.startMonitoring();
    }

    // Subscribe to timer updates
    _timerSubscription = _timerService.timerStream.listen((seconds) {
      _updateDuration(seconds);
    });

    // Subscribe to heart rate updates
    if (hrMonitorEnabled) {
      _hrSubscription = _hrService.heartRateStream.listen((hr) {
        _updateHeartRate(hr);
      });
    }

    // Update metrics every second
    _metricsUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateMetrics(),
    );

    // Save initial session to database
    await _sessionService.createSession(session);
  }

  /// Gets current exercise
  ExerciseProgress? get currentExercise {
    if (state == null || _currentExerciseIndex >= state!.exercises.length) {
      return null;
    }
    return state!.exercises[_currentExerciseIndex];
  }

  /// Whether currently in rest period
  bool get isResting => _isResting;

  /// Completes the current set
  void completeSet({int? reps, double? weight}) {
    if (state == null || currentExercise == null) return;

    // Update exercise progress
    final updatedExercise = currentExercise!.completeSet(
      reps: reps,
      weight: weight,
    );

    final updatedExercises = List<ExerciseProgress>.from(state!.exercises);
    updatedExercises[_currentExerciseIndex] = updatedExercise;

    state = state!.copyWith(exercises: updatedExercises);

    // Check if exercise is complete
    if (updatedExercise.isComplete) {
      advanceToNextExercise();
    } else {
      // Start rest timer
      startRestTimer();
    }
  }

  /// Skips the current set
  void skipSet() {
    if (state == null || currentExercise == null) return;

    // Just advance without recording the set
    if (currentExercise!.currentSet >= currentExercise!.totalSets) {
      advanceToNextExercise();
    } else {
      startRestTimer();
    }
  }

  /// Starts the rest timer
  void startRestTimer() {
    if (state == null) return;

    _isResting = true;
    _countdownService.start(state!.restTimerSeconds);

    _countdownSubscription = _countdownService.timerStream.listen((remaining) {
      if (remaining <= 0) {
        _isResting = false;
        _countdownSubscription?.cancel();

        // TODO: Play audio cue if enabled
        if (state!.audioCuesEnabled) {
          // Play sound
        }
      }
    });
  }

  /// Skips the rest timer
  void skipRest() {
    _countdownService.skip();
    _isResting = false;
    _countdownSubscription?.cancel();
  }

  /// Advances to the next exercise
  void advanceToNextExercise() {
    if (state == null) return;

    _currentExerciseIndex++;

    // Check if all exercises are complete
    if (_currentExerciseIndex >= state!.exercises.length) {
      // All exercises complete - end workout
      endWorkout();
    }
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

  /// Updates all metrics (calories, volume)
  void _updateMetrics() {
    if (state == null) return;

    // Calculate calories
    final durationMinutes = (state!.durationSeconds ?? 0) / 60.0;
    final calories = _calorieService.calculateCalories(
      workoutType: WorkoutType.resistance,
      durationMinutes: durationMinutes.round(),
      avgHeartRate: state!.avgHeartRate,
    );

    // Calculate total volume
    double totalVolume = 0.0;
    for (final exercise in state!.exercises) {
      for (final set in exercise.completedSets) {
        if (set.weight != null) {
          totalVolume += set.reps * set.weight!;
        }
      }
    }

    state = state!.copyWith(
      caloriesBurned: calories,
      totalVolumeKg: totalVolume > 0 ? totalVolume : null,
    );
  }

  /// Ends the workout
  Future<void> endWorkout({MoodRating? postMood}) async {
    if (state == null) return;

    _timerService.stop();
    _countdownService.stop();
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
    _timerSubscription?.cancel();
    _countdownSubscription?.cancel();
    _hrSubscription?.cancel();
    _metricsUpdateTimer?.cancel();
    _timerService.dispose();
    _countdownService.dispose();
    _hrService.dispose();
    super.dispose();
  }
}

/// Provider for resistance session state
final resistanceSessionProvider =
    StateNotifierProvider<ResistanceSessionNotifier, ResistanceSession?>(
      (ref) => ResistanceSessionNotifier(
        timerService: ref.watch(timerServiceProvider),
        countdownService: ref.watch(countdownTimerServiceProvider),
        hrService: ref.watch(heartRateServiceProvider),
        calorieService: ref.watch(calorieCalculatorServiceProvider),
        sessionService: ref.watch(workoutSessionServiceProvider),
      ),
    );
