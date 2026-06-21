import '../entities/mood_entry.dart';
import '../entities/mood_type.dart';
import '../entities/workout_recommendation.dart';

/// Abstract repository interface for mood data access
///
/// This interface defines the contract for mood data operations.
/// Implementations can be mock repositories or real backend integrations.
abstract class MoodRepository {
  /// Get mood entries for a date range
  ///
  /// Returns a list of mood entries that occurred between [startDate] and [endDate]
  Future<List<MoodEntry>> getMoodEntries({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Add a mood entry
  ///
  /// Persists the given mood [entry] to storage
  Future<void> addMoodEntry(MoodEntry entry);

  /// Get workout recommendations based on mood
  ///
  /// Returns a list of workout recommendations tailored to the given [mood]
  Future<List<WorkoutRecommendation>> getRecommendationsForMood(MoodType mood);
}
