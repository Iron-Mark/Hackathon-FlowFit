import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood_rating.dart';

/// State for mood tracking
class MoodTrackingState {
  final MoodRating? preMood;
  final MoodRating? postMood;
  final int? moodChange;

  MoodTrackingState({this.preMood, this.postMood, this.moodChange});

  MoodTrackingState copyWith({
    MoodRating? preMood,
    MoodRating? postMood,
    int? moodChange,
  }) {
    return MoodTrackingState(
      preMood: preMood ?? this.preMood,
      postMood: postMood ?? this.postMood,
      moodChange: moodChange ?? this.moodChange,
    );
  }
}

/// Provider for managing mood tracking
class MoodTrackingNotifier extends StateNotifier<MoodTrackingState> {
  MoodTrackingNotifier() : super(MoodTrackingState());

  /// Records pre-workout mood
  void selectPreMood(int moodValue) {
    final mood = MoodRating.fromValue(moodValue);
    state = state.copyWith(preMood: mood);
  }

  /// Records post-workout mood and calculates change
  void selectPostMood(int moodValue) {
    final mood = MoodRating.fromValue(moodValue);
    final change = state.preMood != null
        ? moodValue - state.preMood!.value
        : null;

    state = state.copyWith(postMood: mood, moodChange: change);
  }

  /// Calculates mood change from pre and post moods
  int? calculateMoodChange() {
    if (state.preMood == null || state.postMood == null) return null;
    return state.postMood!.value - state.preMood!.value;
  }

  /// Resets mood tracking state
  void reset() {
    state = MoodTrackingState();
  }
}

/// Provider for mood tracking state
final moodTrackingProvider =
    StateNotifierProvider<MoodTrackingNotifier, MoodTrackingState>(
      (ref) => MoodTrackingNotifier(),
    );
