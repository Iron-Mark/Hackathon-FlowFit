import 'dart:async';

import 'package:flowfit/models/permission_status.dart';
import 'package:flowfit/services/watch_bridge.dart';
import 'package:flowfit/widgets/permission_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('grant permission refreshes the displayed status', (
    tester,
  ) async {
    final bridge = _FakeWatchBridge(
      initialStatus: PermissionStatus.notDetermined,
      requestResult: true,
      statusAfterRequest: PermissionStatus.granted,
    );

    await tester.pumpWidget(_harness(bridge));
    await tester.pumpAndSettle();

    expect(find.text('Permission Required'), findsOneWidget);

    await tester.tap(find.text('Grant Permission'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(bridge.requestCalls, 1);
    expect(find.text('Permission Granted'), findsOneWidget);
    expect(find.text('Grant Permission'), findsNothing);
  });

  testWidgets('denied permission refreshes into settings recovery action', (
    tester,
  ) async {
    final bridge = _FakeWatchBridge(
      initialStatus: PermissionStatus.notDetermined,
      requestResult: false,
      statusAfterRequest: PermissionStatus.denied,
    );

    await tester.pumpWidget(_harness(bridge));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grant Permission'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Permission Denied'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
  });

  testWidgets(
    'open settings refreshes permission status when access is granted',
    (tester) async {
      final bridge = _FakeWatchBridge(
        initialStatus: PermissionStatus.denied,
        openSettingsResult: true,
        statusAfterOpenSettings: PermissionStatus.granted,
      );

      await tester.pumpWidget(_harness(bridge));
      await tester.pumpAndSettle();

      expect(find.text('Open Settings'), findsOneWidget);

      await tester.tap(find.text('Open Settings'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(bridge.openSettingsCalls, 1);
      expect(find.text('Permission Granted'), findsOneWidget);
    },
  );

  testWidgets('request permission failure shows feedback and restores button', (
    tester,
  ) async {
    final bridge = _FakeWatchBridge(
      initialStatus: PermissionStatus.notDetermined,
      requestError: StateError('permission channel unavailable'),
    );

    await tester.pumpWidget(_harness(bridge));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grant Permission'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Grant Permission'), findsOneWidget);
    expect(
      find.textContaining('Failed to request permission:'),
      findsOneWidget,
    );
  });

  testWidgets('open settings failure shows feedback', (tester) async {
    final bridge = _FakeWatchBridge(
      initialStatus: PermissionStatus.denied,
      openSettingsResult: false,
    );

    await tester.pumpWidget(_harness(bridge));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Settings'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Permission Denied'), findsOneWidget);
    expect(find.text('Failed to open app settings'), findsOneWidget);
  });
}

Widget _harness(WatchBridgeService bridge) {
  return MaterialApp(
    home: Scaffold(body: PermissionStatusWidget(watchBridge: bridge)),
  );
}

class _FakeWatchBridge extends WatchBridgeService {
  _FakeWatchBridge({
    required PermissionStatus initialStatus,
    this.requestResult = true,
    this.statusAfterRequest,
    this.requestError,
    this.openSettingsResult = true,
    this.statusAfterOpenSettings,
  }) : _status = initialStatus;

  final StreamController<PermissionStatus> _permissionController =
      StreamController<PermissionStatus>.broadcast();
  PermissionStatus _status;
  final bool requestResult;
  final PermissionStatus? statusAfterRequest;
  final Object? requestError;
  final bool openSettingsResult;
  final PermissionStatus? statusAfterOpenSettings;
  int requestCalls = 0;
  int openSettingsCalls = 0;
  var monitoringStarted = false;
  var monitoringStopped = false;

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
    if (requestError != null) {
      throw requestError!;
    }
    _status = statusAfterRequest ?? _status;
    return requestResult;
  }

  @override
  Future<bool> openAppSettings() async {
    openSettingsCalls++;
    if (openSettingsResult) {
      _status = statusAfterOpenSettings ?? _status;
    }
    return openSettingsResult;
  }
}
