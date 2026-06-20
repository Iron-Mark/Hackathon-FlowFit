import 'dart:async';

import 'package:flowfit/core/providers/data_sources/watch_data_source_provider.dart';
import 'package:flowfit/core/providers/repositories/heart_rate_repository_provider.dart';
import 'package:flowfit/domain/entities/heart_rate_data.dart';
import 'package:flowfit/domain/repositories/heart_rate_repository.dart';
import 'package:flowfit/models/connection_state.dart' as watch_connection;
import 'package:flowfit/screens/heart_rate_monitor_screen.dart';
import 'package:flowfit/services/watch_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('heart rate monitor start and stop controls update tracking', (
    tester,
  ) async {
    final repository = _FakeHeartRateRepository();
    final watchBridge = _FakeWatchBridge();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heartRateRepositoryProvider.overrideWithValue(repository),
          watchDataSourceProvider.overrideWithValue(watchBridge),
        ],
        child: const MaterialApp(home: HeartRateMonitorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('72'), findsOneWidget);
    expect(find.text('INACTIVE'), findsOneWidget);
    expect(find.text('IBI Values: 0'), findsOneWidget);

    final startButton = find.widgetWithText(ElevatedButton, 'Start');
    final stopButton = find.widgetWithText(ElevatedButton, 'Stop');

    expect(tester.widget<ElevatedButton>(startButton).enabled, isTrue);
    expect(tester.widget<ElevatedButton>(stopButton).enabled, isFalse);

    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(repository.startCalls, 1);
    expect(tester.widget<ElevatedButton>(startButton).enabled, isFalse);
    expect(tester.widget<ElevatedButton>(stopButton).enabled, isTrue);

    repository.emit(
      HeartRateData(
        bpm: 91,
        ibiValues: const [650, 660],
        timestamp: DateTime(2026, 6, 20, 14),
        status: HeartRateStatus.active,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('91'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('IBI Values: 2'), findsOneWidget);

    await tester.tap(stopButton);
    await tester.pumpAndSettle();

    expect(repository.stopCalls, 1);
    expect(tester.widget<ElevatedButton>(startButton).enabled, isTrue);
    expect(tester.widget<ElevatedButton>(stopButton).enabled, isFalse);
  });
}

class _FakeHeartRateRepository implements HeartRateRepository {
  final StreamController<HeartRateData> _controller =
      StreamController<HeartRateData>.broadcast();
  late HeartRateData _latest;

  int startCalls = 0;
  int stopCalls = 0;

  _FakeHeartRateRepository() {
    _latest = HeartRateData(
      bpm: 72,
      ibiValues: const [],
      timestamp: DateTime(2026, 6, 20, 13),
      status: HeartRateStatus.inactive,
    );
  }

  @override
  Stream<HeartRateData> get heartRateStream async* {
    yield _latest;
    yield* _controller.stream;
  }

  @override
  Future<void> startTracking() async {
    startCalls++;
  }

  @override
  Future<void> stopTracking() async {
    stopCalls++;
  }

  @override
  Future<void> saveHeartRateData(HeartRateData data) async {}

  @override
  Future<List<HeartRateData>> getHistoricalData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return const [];
  }

  void emit(HeartRateData data) {
    _latest = data;
    _controller.add(data);
  }
}

class _FakeWatchBridge extends WatchBridgeService {
  @override
  Stream<watch_connection.ConnectionState> get connectionStateStream =>
      Stream<watch_connection.ConnectionState>.value(
        watch_connection.ConnectionState.connected(nodeCount: 1),
      );
}
