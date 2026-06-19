/// Feature: Activity Classifier (AI Inference)
/// 
/// This feature classifies user activity types (Stress, Cardio, Strength) from sensor data
/// using TensorFlow Lite inference. It demonstrates a feature-first clean architecture.
///
/// Structure:
/// ```
/// lib/features/activity_classifier/
/// ├── domain/
/// │   ├── activity.dart                 # Domain model
/// │   └── classify_activity_usecase.dart # Use case & repository interface
/// ├── data/
/// │   ├── activity_dto.dart             # Data transfer object
/// │   └── tflite_activity_repository.dart # Repository implementation
/// ├── platform/
/// │   └── tflite_activity_classifier.dart # TFLite platform wrapper
/// └── presentation/
///     └── providers.dart                # View model & Provider setup
///
/// test/features/activity_classifier/
/// ├── domain/
/// │   └── classify_activity_usecase_test.dart
/// ├── data/
/// │   └── tflite_activity_repository_test.dart
/// └── platform/
///     └── tflite_activity_classifier_test.dart
/// ```
///
/// Data Flow:
/// 1. Sensor reads [accX, accY, accZ, bpm] values into a 320-sample buffer
/// 2. UI calls `viewModel.classify(buffer)`
/// 3. ViewModel delegates to `ClassifyActivityUseCase.execute(buffer)`
/// 4. UseCase validates input, then calls `repository.classifyActivity(buffer)`
/// 5. Repository calls `TFLiteActivityClassifier.predict(buffer)` (platform layer)
/// 6. TFLite returns raw probabilities [stress%, cardio%, strength%]
/// 7. Repository maps to `Activity` domain model
/// 8. ViewModel updates state, UI reflects result
///
/// Architecture Benefits:
/// - Domain layer (classify_activity_usecase.dart) is pure Dart, testable without platform
/// - Data layer handles mapping and persistence (could add Supabase, local DB, cache)
/// - Platform layer isolates TFLite dependencies (can swap with other ML framework)
/// - Presentation layer (ViewModel) uses Provider for state management
/// - Each layer has dedicated tests
///
/// Usage in App:
/// 1. Initialize classifier in main.dart:
///    ```dart
///    final classifier = TFLiteActivityClassifier();
///    await classifier.loadModel(); // Call once at startup
///    ```
/// 2. Set up Provider hierarchy (see providers.dart for MultiProvider setup)
/// 3. In widget, read the ViewModel:
///    ```dart
///    final viewModel = context.read<ActivityClassifierViewModel>();
///    await viewModel.classify(sensorBuffer);
///    ```
/// 4. Listen for changes:
///    ```dart
///    Consumer<ActivityClassifierViewModel>(
///      builder: (context, vm, _) {
///        return Text('Activity: ${vm.currentActivity?.label}');
///      },
///    )
///    ```
///
/// See also:
/// - Copilot instructions: .github/copilot-instructions.md
/// - Sensor bridge: lib/services/watch_bridge.dart (for heart rate data)
/// - Domain models: lib/models/ (cross-feature models)

/// Heart BPM integration
/// - The tracker UI prefers a simulated BPM value (mock slider) by default to make demos and testing consistent.
/// - To use a hardware source, connect the `HeartBpm` plugin's stream to the `HeartBpmAdapter` in `main.dart`, e.g.:
///
/// ```dart
/// final adapter = context.read<HeartBpmAdapter>();
/// adapter.connectExternalStream(HeartBpm.heartBpmStream);
/// ```
///
/// If the external stream provides values, the adapter will publish them and `TrackerPage` will use them.
