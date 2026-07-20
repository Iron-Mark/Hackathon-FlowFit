import 'package:flutter/foundation.dart';
// flutter_riverpod 2.x exports ChangeNotifierProvider directly; riverpod 3.x
// moves it to package:flutter_riverpod/legacy.dart.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:flowfit/features/activity_classifier/data/tflite_activity_repository.dart';
import 'package:flowfit/features/activity_classifier/domain/activity.dart';
import 'package:flowfit/features/activity_classifier/domain/classify_activity_usecase.dart';
import 'package:flowfit/features/activity_classifier/platform/heart_bpm_adapter.dart';
import 'package:flowfit/features/activity_classifier/platform/tflite_activity_classifier.dart';
import 'package:flowfit/services/sensors/phone_data_listener.dart';

/// ChangeNotifier for activity classification state management
class ActivityClassifierViewModel with ChangeNotifier {
  final ClassifyActivityUseCase _useCase;
  final Logger _logger = Logger();

  Activity? _currentActivity;
  bool _isLoading = false;
  String? _error;

  Activity? get currentActivity => _currentActivity;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  ActivityClassifierViewModel(this._useCase);

  /// Classify sensor buffer
  Future<void> classify(List<List<double>> buffer) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentActivity = await _useCase.execute(buffer);
      _logger.i('Classification completed: ${_currentActivity?.label}');
    } catch (e, stackTrace) {
      _error = e.toString();
      _logger.e('Classification failed', error: e, stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset state
  void reset() {
    _currentActivity = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}

/// Platform layer: heart BPM adapter (plugin or watch stream source).
final heartBpmAdapterProvider = Provider<HeartBpmAdapter>(
  (ref) => HeartBpmAdapter(),
);

/// Platform layer: phone-side listener that receives watch heart rate and
/// sensor batches via the Wearable data layer.
final phoneDataListenerProvider = Provider<PhoneDataListener>(
  (ref) => PhoneDataListener(),
);

/// Platform layer: TFLite model wrapper.
final tfliteActivityClassifierProvider = Provider<TFLiteActivityClassifier>(
  (ref) => TFLiteActivityClassifier(),
);

/// Data layer (exposed as the abstract ActivityClassifierRepository type).
final activityClassifierRepositoryProvider =
    Provider<ActivityClassifierRepository>(
      (ref) =>
          TFLiteActivityRepository(ref.watch(tfliteActivityClassifierProvider)),
    );

/// Domain layer.
final classifyActivityUseCaseProvider = Provider<ClassifyActivityUseCase>(
  (ref) =>
      ClassifyActivityUseCase(ref.watch(activityClassifierRepositoryProvider)),
);

/// Presentation layer. Riverpod's ChangeNotifierProvider disposes the notifier
/// automatically, matching the old ChangeNotifierProxyProvider behaviour; the
/// plain providers above hold objects the retired ActivityClassifierScope
/// never disposed either, so no ref.onDispose hooks are needed.
final activityClassifierViewModelProvider =
    ChangeNotifierProvider<ActivityClassifierViewModel>(
      (ref) => ActivityClassifierViewModel(
        ref.watch(classifyActivityUseCaseProvider),
      ),
    );

// =============================================================================
// USAGE: The app root hosts a ProviderScope (see lib/main.dart), so the
// Riverpod providers above are available everywhere — no MultiProvider setup.
//
// In a ConsumerWidget / ConsumerState:
//
// // One-shot reads (init code, callbacks)
// final classifier = ref.read(tfliteActivityClassifierProvider);
// final viewModel = ref.read(activityClassifierViewModelProvider);
//
// // Rebuild whenever the ViewModel notifies
// final viewModel = ref.watch(activityClassifierViewModelProvider);
// if (viewModel.isLoading) return Text('Classifying...');
// if (viewModel.hasError) return Text('Error: ${viewModel.error}');
// return Text('Activity: ${viewModel.currentActivity?.label}');
//
// Optional: Heart BPM integration (plugin or watch)
// - Read heartBpmAdapterProvider / phoneDataListenerProvider where needed.
// - To connect a plugin stream in your app initialization, do:
//
// WidgetsBinding.instance.addPostFrameCallback((_) {
//   final adapter = ref.read(heartBpmAdapterProvider);
//   // If the plugin exports a stream called `heartBpmStream`, connect it:
//   // adapter.connectExternalStream(HeartBpm.heartBpmStream);
// });
//
// Tests override the chain with fakes:
//
// ProviderScope(
//   overrides: [
//     tfliteActivityClassifierProvider.overrideWithValue(fakeClassifier),
//   ],
//   child: ...,
// )
// =============================================================================
