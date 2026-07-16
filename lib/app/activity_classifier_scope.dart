import 'package:flowfit/features/activity_classifier/data/tflite_activity_repository.dart';
import 'package:flowfit/features/activity_classifier/domain/classify_activity_usecase.dart';
import 'package:flowfit/features/activity_classifier/platform/heart_bpm_adapter.dart';
import 'package:flowfit/features/activity_classifier/platform/tflite_activity_classifier.dart';
import 'package:flowfit/features/activity_classifier/presentation/providers.dart';
import 'package:flowfit/services/sensors/phone_data_listener.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Hosts the provider-package dependency chain for the TFLite activity
/// classifier so the app shell stays focused on bootstrap and routing.
class ActivityClassifierScope extends StatelessWidget {
  const ActivityClassifierScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<HeartBpmAdapter>(create: (_) => HeartBpmAdapter()),
        // Phone data listener used to receive watch heart rate via Wearable data layer
        Provider<PhoneDataListener>(create: (_) => PhoneDataListener()),
        Provider<TFLiteActivityClassifier>(
          create: (_) => TFLiteActivityClassifier(),
        ),

        // Data layer
        ProxyProvider<TFLiteActivityClassifier, ActivityClassifierRepository>(
          create: (context) => TFLiteActivityRepository(
            context.read<TFLiteActivityClassifier>(),
          ),
          update: (_, classifier, __) => TFLiteActivityRepository(classifier),
        ),
        // Domain layer (use ActivityClassifierRepository abstract type)
        ProxyProvider<ActivityClassifierRepository, ClassifyActivityUseCase>(
          create: (context) => ClassifyActivityUseCase(
            context.read<ActivityClassifierRepository>(),
          ),
          update: (_, repository, __) => ClassifyActivityUseCase(repository),
        ),

        // Presentation layer
        ChangeNotifierProxyProvider<
          ClassifyActivityUseCase,
          ActivityClassifierViewModel
        >(
          create: (context) => ActivityClassifierViewModel(
            context.read<ClassifyActivityUseCase>(),
          ),
          update: (_, useCase, __) => ActivityClassifierViewModel(useCase),
        ),
      ],
      child: child,
    );
  }
}
