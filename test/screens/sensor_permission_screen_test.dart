import 'dart:async';

import 'package:flowfit/models/permission_status.dart';
import 'package:flowfit/screens/sensor_permission_screen.dart';
import 'package:flowfit/services/watch_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows sensor permission context and grant action', (
    tester,
  ) async {
    final bridge = _FakeWatchBridge(
      initialStatus: PermissionStatus.notDetermined,
    );

    await tester.pumpWidget(_harness(bridge));
    await tester.pumpAndSettle();

    expect(find.text('Sensor Permissions'), findsOneWidget);
    expect(find.text('Body Sensor Permission'), findsOneWidget);
    expect(find.text('Permission Required'), findsOneWidget);
    expect(find.text('Grant Permission'), findsOneWidget);
    expect(find.text('Heart Rate'), findsOneWidget);
    expect(find.text('Activity Tracking'), findsOneWidget);
    expect(find.text('Workout Sessions'), findsOneWidget);
    expect(find.text('Sleep Tracking'), findsOneWidget);
    expect(bridge.monitoringStarted, isTrue);
  });

  testWidgets('grant permission updates the embedded status card', (
    tester,
  ) async {
    final bridge = _FakeWatchBridge(
      initialStatus: PermissionStatus.notDetermined,
      statusAfterRequest: PermissionStatus.granted,
    );

    await tester.pumpWidget(_harness(bridge));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grant Permission'));
    await tester.pumpAndSettle();

    expect(bridge.requestCalls, 1);
    expect(find.text('Permission Granted'), findsOneWidget);
    expect(find.text('Grant Permission'), findsNothing);
  });

  testWidgets('open settings refreshes denied permission recovery state', (
    tester,
  ) async {
    final bridge = _FakeWatchBridge(
      initialStatus: PermissionStatus.denied,
      statusAfterOpenSettings: PermissionStatus.granted,
    );

    await tester.pumpWidget(_harness(bridge));
    await tester.pumpAndSettle();

    expect(find.text('Permission Denied'), findsOneWidget);

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    expect(bridge.openSettingsCalls, 1);
    expect(find.text('Permission Granted'), findsOneWidget);
  });
}

Widget _harness(WatchBridgeService bridge) {
  return MaterialApp(
    home: SensorPermissionScreen(watchBridge: bridge, disposeWatchBridge: true),
  );
}

class _FakeWatchBridge extends WatchBridgeService {
  _FakeWatchBridge({
    required PermissionStatus initialStatus,
    this.statusAfterRequest,
    this.statusAfterOpenSettings,
  }) : _status = initialStatus;

  final StreamController<PermissionStatus> _permissionController =
      StreamController<PermissionStatus>.broadcast();
  PermissionStatus _status;
  final PermissionStatus? statusAfterRequest;
  final PermissionStatus? statusAfterOpenSettings;
  var monitoringStarted = false;
  var monitoringStopped = false;
  int requestCalls = 0;
  int openSettingsCalls = 0;

  @override
  Stream<PermissionStatus> get permissionStateStream =>
      _permissionController.stream;

  @override
  void startPermissionMonitoring({
    Duration interval = const Duration(seconds: 2),
  }) {
    monitoringStarted = true;
  }

  @override
  void stopPermissionMonitoring() {
    monitoringStopped = true;
  }

  @override
  Future<PermissionStatus> checkBodySensorPermission() async => _status;

  @override
  Future<bool> requestBodySensorPermission() async {
    requestCalls++;
    _status = statusAfterRequest ?? PermissionStatus.granted;
    return _status == PermissionStatus.granted;
  }

  @override
  Future<bool> openAppSettings() async {
    openSettingsCalls++;
    _status = statusAfterOpenSettings ?? _status;
    return true;
  }

  @override
  void dispose() {
    _permissionController.close();
    super.dispose();
  }
}
