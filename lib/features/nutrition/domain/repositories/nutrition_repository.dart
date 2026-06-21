import '../entities/food_log.dart';
import '../entities/daily_nutrition_summary.dart';

/// Abstract repository interface for nutrition data access
///
/// This interface defines the contract for nutrition data operations.
/// Implementations can be mock repositories or real backend integrations.
abstract class NutritionRepository {
  /// Get food logs for a specific date
  ///
  /// Returns a list of all food logs recorded on [date]
  Future<List<FoodLog>> getFoodLogsForDate(DateTime date);

  /// Add a food log entry
  ///
  /// Persists the given food [log] to storage
  Future<void> addFoodLog(FoodLog log);

  /// Update a food log entry
  ///
  /// Updates the food log with the same ID as [log]
  Future<void> updateFoodLog(FoodLog log);

  /// Delete a food log entry
  ///
  /// Removes the food log with the given [id] from storage
  Future<void> deleteFoodLog(String id);

  /// Get daily nutrition summary
  ///
  /// Returns aggregated nutrition data for [date] including totals and progress
  Future<DailyNutritionSummary> getDailySummary(DateTime date);
}
