import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:flowfit/features/activity_classifier/domain/activity.dart';
import 'package:flowfit/features/activity_classifier/domain/classify_activity_usecase.dart';

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

// =============================================================================
// USAGE: Set up in app's MultiProvider:
//
// MultiProvider(
//   providers: [
//     // Platform layer
//     Provider<TFLiteActivityClassifier>(
//       create: (_) => TFLiteActivityClassifier(),
//     ),
//     // Data layer
//     ProxyProvider<TFLiteActivityClassifier, ActivityClassifierRepository>(
//       create: (_, classifier) => TFLiteActivityRepository(classifier),
//       update: (_, classifier, __) => TFLiteActivityRepository(classifier),
//     ),
//     // Domain layer
//     ProxyProvider<ActivityClassifierRepository, ClassifyActivityUseCase>(
//       create: (_, repository) => ClassifyActivityUseCase(repository),
//       update: (_, repository, __) => ClassifyActivityUseCase(repository),
//     ),
//     // Presentation layer
//     ChangeNotifierProxyProvider<ClassifyActivityUseCase, ActivityClassifierViewModel>(
//       create: (_, useCase) => ActivityClassifierViewModel(useCase),
//       update: (_, useCase, __) => ActivityClassifierViewModel(useCase),
//     ),
//   ],
//   child: MyApp(),
// )
//
// Optional: Heart BPM integration (plugin or watch)
// - Add `Provider<HeartBpmAdapter>` and `Provider<PhoneDataListener>` in `main.dart`
// - To connect a plugin stream in your app initialization, do:
//
// WidgetsBinding.instance.addPostFrameCallback((_) {
//   final adapter = context.read<HeartBpmAdapter>();
//   // If the plugin exports a stream called `heartBpmStream`, connect it:
//   // adapter.connectExternalStream(HeartBpm.heartBpmStream);
// });
//
//
// USAGE: In widgets:
//
// // Read current activity
// final activity = context.read<Activity?>();
// final viewModel = context.read<ActivityClassifierViewModel>();
//
// // Listen for changes
// Consumer<ActivityClassifierViewModel>(
//   builder: (context, viewModel, _) {
//     if (viewModel.isLoading) return Text('Classifying...');
//     if (viewModel.hasError) return Text('Error: ${viewModel.error}');
//     return Text('Activity: ${viewModel.currentActivity?.label}');
//   },
// )
// =============================================================================
