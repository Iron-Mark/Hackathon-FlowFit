import 'dart:async';
import 'dart:collection';

import 'package:flowfit/features/activity_classifier/domain/activity.dart';
import 'package:flowfit/features/activity_classifier/domain/classify_activity_usecase.dart';
import 'package:flowfit/features/activity_classifier/platform/heart_bpm_adapter.dart';
import 'package:flowfit/features/activity_classifier/platform/tflite_activity_classifier.dart';
import 'package:flowfit/features/activity_classifier/presentation/providers.dart';
import 'package:flowfit/features/activity_classifier/presentation/tracker_page.dart';
import 'package:flowfit/models/heart_rate_data.dart';
import 'package:flowfit/models/sensor_batch.dart';
import 'package:flowfit/models/sensor_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider;

void main() {
  testWidgets('shows retry when watch listener startup fails', (tester) async {
    final listener = _FakeActivityWatchDataListener(startResults: [false]);

    await tester.pumpWidget(_harness(listener));
    await tester.pump();
    await tester.pump();

    expect(find.text('Listener inactive'), findsOneWidget);
    expect(
      find.text(
        'Could not start watch listener. Check Bluetooth and Wear OS connection, then retry.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry watch listener'), findsOneWidget);
    expect(listener.startCalls, 1);
  });

  testWidgets('retry restarts watch listener and clears startup error', (
    tester,
  ) async {
    final listener = _FakeActivityWatchDataListener(
      startResults: [false, true],
    );

    await tester.pumpWidget(_harness(listener));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Retry watch listener'));
    await tester.pump();
    await tester.pump();

    expect(listener.startCalls, 2);
    expect(find.text('Retry watch listener'), findsNothing);
    expect(find.text('Not connected'), findsOneWidget);
  });

  testWidgets('watch stream error shows retryable status', (tester) async {
    final listener = _FakeActivityWatchDataListener(startResults: [true]);

    await tester.pumpWidget(_harness(listener));
    await tester.pump();
    await tester.pump();

    listener.addHeartRate(
      HeartRateData(
        bpm: 92,
        timestamp: DateTime(2026, 6, 20, 10),
        status: SensorStatus.active,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('92 BPM'), findsOneWidget);

    listener.addHeartRateError(StateError('phone listener stopped'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Listener inactive'), findsOneWidget);
    expect(
      find.text(
        'Watch data stream stopped. Check Bluetooth and Wear OS connection, then retry.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry watch listener'), findsOneWidget);
  });
}

Widget _harness(ActivityWatchDataListener listener) {
  return provider.MultiProvider(
    providers: [
      provider.ChangeNotifierProvider<ActivityClassifierViewModel>(
        create: (_) => ActivityClassifierViewModel(
          ClassifyActivityUseCase(_FakeActivityClassifierRepository()),
        ),
      ),
      provider.Provider<TFLiteActivityClassifier>.value(
        value: _FakeTFLiteActivityClassifier(),
      ),
      provider.Provider<HeartBpmAdapter>(create: (_) => HeartBpmAdapter()),
    ],
    child: MaterialApp(
      home: TrackerPage(
        watchDataListener: listener,
        initialAccelSource: AccelSource.watch,
      ),
    ),
  );
}

class _FakeActivityWatchDataListener implements ActivityWatchDataListener {
  _FakeActivityWatchDataListener({required List<bool> startResults})
    : _startResults = Queue<bool>.from(startResults);

  final Queue<bool> _startResults;
  final StreamController<HeartRateData> _heartRateController =
      StreamController<HeartRateData>.broadcast();
  final StreamController<SensorBatch> _sensorBatchController =
      StreamController<SensorBatch>.broadcast();
  int startCalls = 0;

  @override
  Future<bool> startListening() async {
    startCalls++;
    return _startResults.isNotEmpty ? _startResults.removeFirst() : true;
  }

  @override
  Stream<HeartRateData> get heartRateStream => _heartRateController.stream;

  @override
  Stream<SensorBatch> get sensorBatchStream => _sensorBatchController.stream;

  void addHeartRate(HeartRateData data) {
    _heartRateController.add(data);
  }

  void addHeartRateError(Object error) {
    _heartRateController.addError(error);
  }
}

class _FakeActivityClassifierRepository
    implements ActivityClassifierRepository {
  @override
  Future<Activity> classifyActivity(List<List<double>> buffer) async {
    return Activity(
      label: 'Cardio',
      confidence: 0.8,
      timestamp: DateTime(2026, 6, 20),
      probabilities: const [0.1, 0.8, 0.1],
    );
  }

  @override
  Future<List<String>> getActivityLabels() async {
    return const ['Stress', 'Cardio', 'Strength'];
  }
}

class _FakeTFLiteActivityClassifier extends TFLiteActivityClassifier {
  @override
  bool get isLoaded => true;

  @override
  Future<void> loadModel() async {}

  @override
  Future<List<double>> predict(List<List<double>> buffer) async {
    return const [0.1, 0.8, 0.1];
  }
}
