import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood_rating.dart';
import '../models/workout_session.dart';

/// Current step in the workout flow
enum WorkoutFlowStep {
  idle,
  preMoodCheck,
  workoutTypeSelection,
  workoutSetup,
  activeWorkout,
  postMoodCheck,
  summary,
}

/// State for the overall workout flow
class WorkoutFlowState {
  final WorkoutFlowStep currentStep;
  final MoodRating? preMood;
  final WorkoutType? selectedType;
  final String? activeSessionId;

  WorkoutFlowState({
    this.currentStep = WorkoutFlowStep.idle,
    this.preMood,
    this.selectedType,
    this.activeSessionId,
  });

  WorkoutFlowState copyWith({
    WorkoutFlowStep? currentStep,
    MoodRating? preMood,
    WorkoutType? selectedType,
    String? activeSessionId,
  }) {
    return WorkoutFlowState(
      currentStep: currentStep ?? this.currentStep,
      preMood: preMood ?? this.preMood,
      selectedType: selectedType ?? this.selectedType,
      activeSessionId: activeSessionId ?? this.activeSessionId,
    );
  }
}

/// Provider for managing the overall workout flow
class WorkoutFlowNotifier extends StateNotifier<WorkoutFlowState> {
  WorkoutFlowNotifier() : super(WorkoutFlowState());

  /// Starts the workout flow with pre-mood check
  void startWorkoutFlow() {
    state = state.copyWith(currentStep: WorkoutFlowStep.preMoodCheck);
  }

  /// Records pre-workout mood and moves to workout type selection
  void setPreMood(MoodRating mood) {
    state = state.copyWith(
      preMood: mood,
      currentStep: WorkoutFlowStep.workoutTypeSelection,
    );
  }

  /// Selects workout type and moves to setup
  void selectWorkoutType(WorkoutType type) {
    state = state.copyWith(
      selectedType: type,
      currentStep: WorkoutFlowStep.workoutSetup,
    );
  }

  /// Starts active workout with session ID
  void startActiveWorkout(String sessionId) {
    state = state.copyWith(
      activeSessionId: sessionId,
      currentStep: WorkoutFlowStep.activeWorkout,
    );
  }

  /// Moves to post-workout mood check
  void moveToPostMoodCheck() {
    state = state.copyWith(currentStep: WorkoutFlowStep.postMoodCheck);
  }

  /// Moves to workout summary
  void moveToSummary() {
    state = state.copyWith(currentStep: WorkoutFlowStep.summary);
  }

  /// Resets the workout flow to idle
  void reset() {
    state = WorkoutFlowState();
  }
}

/// Provider for workout flow state
final workoutFlowProvider =
    StateNotifierProvider<WorkoutFlowNotifier, WorkoutFlowState>(
      (ref) => WorkoutFlowNotifier(),
    );
