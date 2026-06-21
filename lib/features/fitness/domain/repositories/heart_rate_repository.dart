import '../../../../core/domain/entities/heart_rate_point.dart';
import '../../../../models/heart_rate_data.dart';

/// Abstract repository interface for heart rate data access
///
/// This interface defines the contract for heart rate data operations.
/// Implementations can integrate with watch sensors or backend storage.
abstract class HeartRateRepository {
  /// Get real-time heart rate stream from watch
  ///
  /// Returns a stream of heart rate data from the connected watch device
  Stream<HeartRateData> getHeartRateStream();

  /// Get historical heart rate data
  ///
  /// Returns a list of heart rate points that occurred between [startDate] and [endDate]
  Future<List<HeartRatePoint>> getHeartRateHistory({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Save heart rate data point
  ///
  /// Persists the given heart rate [data] to storage
  Future<void> saveHeartRateData(HeartRatePoint data);

  /// Get current heart rate reading
  ///
  /// Returns the most recent heart rate measurement, or null if unavailable
  Future<HeartRatePoint?> getCurrentHeartRate();
}
