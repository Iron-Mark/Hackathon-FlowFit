import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/services/sensors/step_counter_service.dart';
import 'package:flowfit/providers/wellness_state_provider.dart';

/// Provider for StepCounterService
final stepCounterServiceProvider = Provider<StepCounterService>((ref) {
  final phoneDataListener = ref.watch(phoneDataListenerServiceProvider);
  return StepCounterService(phoneDataListener);
});

/// Provider for current step count
final stepCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(stepCounterServiceProvider);
  return service.stepStream;
});

/// Provider for total steps (synchronous access)
final totalStepsProvider = Provider<int>((ref) {
  final asyncSteps = ref.watch(stepCountProvider);
  return asyncSteps.when(
    data: (steps) => steps,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
