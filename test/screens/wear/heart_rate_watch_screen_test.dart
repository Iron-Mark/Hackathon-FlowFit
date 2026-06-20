import 'dart:async';

import 'package:flowfit/models/heart_rate_data.dart';
import 'package:flowfit/models/sensor_status.dart';
import 'package:flowfit/screens/wear/heart_rate_watch_screen.dart';
import 'package:flowfit/services/watch_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows retry when watch sensor startup returns unavailable', (
    tester,
  ) async {
    final bridge = _FakeWatchBridge(startResult: false);

    await tester.pumpWidget(_harness(bridge));
    await tester.pump();

    expect(find.text('ERROR'), findsOneWidget);
    expect(
      find.text(
        'Heart rate sensor is unavailable. Check permission and retry.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(bridge.startCalls, 1);

    bridge.startResult = true;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(bridge.startCalls, 2);
    expect(find.text('TRACKING'), findsOneWidget);
  });

  testWidgets('shows retry when watch sensor startup throws', (tester) async {
    final bridge = _FakeWatchBridge(
      startError: StateError('sensor channel unavailable'),
    );

    await tester.pumpWidget(_harness(bridge));
    await tester.pump();

    expect(find.text('ERROR'), findsOneWidget);
    expect(
      find.text(
        'Could not start heart rate tracking. Check sensor permission and retry.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    bridge.startError = null;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(bridge.startCalls, 2);
    expect(find.text('TRACKING'), findsOneWidget);
  });

  testWidgets('renders live heart rate readings from watch stream', (
    tester,
  ) async {
    final bridge = _FakeWatchBridge();

    await tester.pumpWidget(_harness(bridge));
    await tester.pump();

    bridge.addReading(
      HeartRateData(
        bpm: 88,
        timestamp: DateTime(2026, 6, 20, 9),
        status: SensorStatus.active,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('88'), findsOneWidget);
    expect(find.text('TRACKING'), findsOneWidget);
  });

  testWidgets('shows retry when watch stream stops with an error', (
    tester,
  ) async {
    final bridge = _FakeWatchBridge();

    await tester.pumpWidget(_harness(bridge));
    await tester.pump();

    bridge.addError(StateError('stream stopped'));
    await tester.pump();
    await tester.pump();

    expect(find.text('ERROR'), findsOneWidget);
    expect(
      find.text(
        'Heart rate stream stopped. Check sensor permission and retry.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets(
    'disposing while stop is pending does not throw setState errors',
    (tester) async {
      final stopCompleter = Completer<void>();
      final bridge = _FakeWatchBridge(stopCompleter: stopCompleter);

      await tester.pumpWidget(_harness(bridge));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      stopCompleter.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );
}

Widget _harness(WatchBridgeService bridge) {
  return MaterialApp(home: HeartRateWatchScreen(watchBridge: bridge));
}

class _FakeWatchBridge extends WatchBridgeService {
  _FakeWatchBridge({
    this.startResult = true,
    this.startError,
    this.stopCompleter,
  });

  final StreamController<HeartRateData> _controller =
      StreamController<HeartRateData>.broadcast();
  bool startResult;
  Object? startError;
  final Completer<void>? stopCompleter;
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Future<bool> startHeartRateTracking() async {
    startCalls++;
    if (startError != null) {
      throw startError!;
    }
    return startResult;
  }

  @override
  Stream<HeartRateData> get heartRateStream => _controller.stream;

  @override
  Future<void> stopHeartRateTracking() async {
    stopCalls++;
    if (stopCompleter != null) {
      await stopCompleter!.future;
    }
  }

  void addReading(HeartRateData data) {
    _controller.add(data);
  }

  void addError(Object error) {
    _controller.addError(error);
  }

  @override
  void dispose() {
    unawaited(_controller.close());
  }
}
