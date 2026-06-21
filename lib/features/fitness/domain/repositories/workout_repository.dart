import '../../../../core/domain/entities/workout.dart';

/// Abstract repository interface for workout data access
///
/// This interface defines the contract for workout data operations.
/// Implementations can be mock repositories or real backend integrations.
abstract class WorkoutRepository {
  /// Get workout history for a date range
  ///
  /// Returns a list of workouts that occurred between [startDate] and [endDate]
  Future<List<Workout>> getWorkoutHistory({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get a specific workout by ID
  ///
  /// Returns the workout with the given [id], or null if not found
  Future<Workout?> getWorkoutById(String id);

  /// Save a new workout
  ///
  /// Persists the given [workout] to storage
  Future<void> saveWorkout(Workout workout);

  /// Update an existing workout
  ///
  /// Updates the workout with the same ID as [workout]
  Future<void> updateWorkout(Workout workout);

  /// Delete a workout
  ///
  /// Removes the workout with the given [id] from storage
  Future<void> deleteWorkout(String id);

  /// Get active workout session (if any)
  ///
  /// Returns the currently active workout, or null if no workout is in progress
  Future<Workout?> getActiveWorkout();
}
