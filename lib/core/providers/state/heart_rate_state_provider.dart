import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/heart_rate_data.dart';
import '../repositories/heart_rate_repository_provider.dart';

/// Current heart rate state provider
///
/// This provides the latest heart rate data as a stream.
final currentHeartRateProvider = StreamProvider<HeartRateData>((ref) {
  final repository = ref.watch(heartRateRepositoryProvider);
  return repository.heartRateStream;
});

/// Heart rate tracking state provider
///
/// Manages whether heart rate tracking is active.
final heartRateTrackingStateProvider =
    StateNotifierProvider<HeartRateTrackingNotifier, bool>((ref) {
      final repository = ref.watch(heartRateRepositoryProvider);
      return HeartRateTrackingNotifier(repository);
    });

/// Notifier for heart rate tracking state
class HeartRateTrackingNotifier extends StateNotifier<bool> {
  final dynamic heartRateRepository;

  HeartRateTrackingNotifier(this.heartRateRepository) : super(false);

  /// Start tracking
  Future<void> startTracking() async {
    try {
      await heartRateRepository.startTracking();
      state = true;
    } catch (e) {
      // Handle error
      state = false;
      rethrow;
    }
  }

  /// Stop tracking
  Future<void> stopTracking() async {
    try {
      await heartRateRepository.stopTracking();
      state = false;
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
}
