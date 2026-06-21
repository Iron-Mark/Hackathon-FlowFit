import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/heart_rate_repository_provider.dart';
import '../../../domain/entities/heart_rate_data.dart';

/// Heart rate service provider
///
/// This is a use case / service layer that orchestrates heart rate operations.
final heartRateServiceProvider = Provider((ref) {
  final repository = ref.watch(heartRateRepositoryProvider);
  return HeartRateService(repository);
});

/// Heart rate service
///
/// Orchestrates heart rate tracking and data persistence.
class HeartRateService {
  final dynamic heartRateRepository;

  HeartRateService(this.heartRateRepository);

  /// Start tracking and auto-save to backend
  Future<void> startTrackingWithAutoSave() async {
    await heartRateRepository.startTracking();

    // Listen to heart rate stream and save periodically
    heartRateRepository.heartRateStream.listen((HeartRateData data) {
      if (data.bpm != null && data.bpm! > 0) {
        heartRateRepository.saveHeartRateData(data);
      }
    });
  }

  /// Stop tracking
  Future<void> stopTracking() async {
    await heartRateRepository.stopTracking();
  }

  /// Get historical data for a date range
  Future<List<HeartRateData>> getHistoricalData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await heartRateRepository.getHistoricalData(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
