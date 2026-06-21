import '../entities/heart_rate_data.dart';

/// Repository interface for heart rate data
///
/// This defines the contract for heart rate data operations,
/// independent of the data source (watch, API, local storage).
abstract class HeartRateRepository {
  /// Stream of heart rate data from the watch
  Stream<HeartRateData> get heartRateStream;

  /// Start heart rate tracking
  Future<void> startTracking();

  /// Stop heart rate tracking
  Future<void> stopTracking();

  /// Save heart rate data to backend
  Future<void> saveHeartRateData(HeartRateData data);

  /// Get historical heart rate data
  Future<List<HeartRateData>> getHistoricalData({
    required DateTime startDate,
    required DateTime endDate,
  });
}
