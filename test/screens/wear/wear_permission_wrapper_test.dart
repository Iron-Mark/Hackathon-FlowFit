import 'package:flowfit/screens/wear/wear_permission_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

void main() {
  testWidgets('shows child immediately when sensor permission is granted', (
    tester,
  ) async {
    final permissions = _FakeWearPermissions(
      statusResults: [ph.PermissionStatus.granted],
    );

    await tester.pumpWidget(_harness(permissions));
    await tester.pumpAndSettle();

    expect(permissions.checkCalls, 1);
    expect(permissions.requestCalls, 0);
    expect(find.text('wear content'), findsOneWidget);
  });

  testWidgets('requests permission and shows child when granted', (
    tester,
  ) async {
    final permissions = _FakeWearPermissions(
      statusResults: [ph.PermissionStatus.denied],
      requestResults: [ph.PermissionStatus.granted],
    );

    await tester.pumpWidget(_harness(permissions));
    await tester.pumpAndSettle();

    expect(permissions.checkCalls, 1);
    expect(permissions.requestCalls, 1);
    expect(find.text('wear content'), findsOneWidget);
  });

  testWidgets('shows grant recovery when permission remains denied', (
    tester,
  ) async {
    final permissions = _FakeWearPermissions(
      statusResults: [ph.PermissionStatus.denied],
      requestResults: [ph.PermissionStatus.denied],
    );

    await tester.pumpWidget(_harness(permissions));
    await tester.pumpAndSettle();

    expect(find.text('Body Sensors Permission Required'), findsOneWidget);
    expect(find.text('Grant Permission'), findsOneWidget);
  });

  testWidgets('grant recovery button retries permission and shows child', (
    tester,
  ) async {
    final permissions = _FakeWearPermissions(
      statusResults: [ph.PermissionStatus.denied, ph.PermissionStatus.denied],
      requestResults: [ph.PermissionStatus.denied, ph.PermissionStatus.granted],
    );

    await tester.pumpWidget(_harness(permissions));
    await tester.pumpAndSettle();

    expect(find.text('Grant Permission'), findsOneWidget);

    await tester.tap(find.text('Grant Permission'));
    await tester.pumpAndSettle();

    expect(permissions.checkCalls, 2);
    expect(permissions.requestCalls, 2);
    expect(find.text('wear content'), findsOneWidget);
  });

  testWidgets('permission check failure shows visible feedback', (
    tester,
  ) async {
    final permissions = _FakeWearPermissions(
      checkError: StateError('permission plugin unavailable'),
    );

    await tester.pumpWidget(_harness(permissions));
    await tester.pumpAndSettle();

    expect(find.text('Body Sensors Permission Required'), findsOneWidget);
    expect(
      find.textContaining('Failed to check sensor permission:'),
      findsOneWidget,
    );
  });

  testWidgets('settings failure shows visible feedback', (tester) async {
    final permissions = _FakeWearPermissions(
      statusResults: [ph.PermissionStatus.permanentlyDenied],
      requestResults: [ph.PermissionStatus.permanentlyDenied],
      settingsResults: [false],
    );

    await tester.pumpWidget(_harness(permissions));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    expect(permissions.openSettingsCalls, 1);
    expect(find.text('Permission Permanently Denied'), findsOneWidget);
    expect(find.textContaining('Could not open app settings'), findsOneWidget);
  });

  testWidgets('settings recovery rechecks permission and shows child', (
    tester,
  ) async {
    final permissions = _FakeWearPermissions(
      statusResults: [
        ph.PermissionStatus.permanentlyDenied,
        ph.PermissionStatus.granted,
      ],
      requestResults: [ph.PermissionStatus.permanentlyDenied],
      settingsResults: [true],
    );

    await tester.pumpWidget(_harness(permissions));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    expect(permissions.openSettingsCalls, 1);
    expect(permissions.checkCalls, 2);
    expect(find.text('wear content'), findsOneWidget);
  });

  testWidgets('foreground resume rechecks permission and shows child', (
    tester,
  ) async {
    final permissions = _FakeWearPermissions(
      statusResults: [ph.PermissionStatus.denied, ph.PermissionStatus.granted],
      requestResults: [ph.PermissionStatus.denied],
    );

    await tester.pumpWidget(_harness(permissions));
    await tester.pumpAndSettle();

    expect(find.text('Grant Permission'), findsOneWidget);
    expect(permissions.checkCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(permissions.checkCalls, 2);
    expect(permissions.requestCalls, 1);
    expect(find.text('wear content'), findsOneWidget);
  });
}

Widget _harness(_FakeWearPermissions permissions) {
  return MaterialApp(
    home: WearPermissionWrapper(
      checkPermission: permissions.check,
      requestPermission: permissions.request,
      openSettings: permissions.openSettings,
      settingsReturnDelay: Duration.zero,
      child: const Scaffold(body: Center(child: Text('wear content'))),
    ),
  );
}

class _FakeWearPermissions {
  _FakeWearPermissions({
    this.statusResults = const [],
    this.requestResults = const [],
    this.settingsResults = const [],
    this.checkError,
  });

  final List<ph.PermissionStatus> statusResults;
  final List<ph.PermissionStatus> requestResults;
  final List<bool> settingsResults;
  final Object? checkError;

  int checkCalls = 0;
  int requestCalls = 0;
  int openSettingsCalls = 0;

  Future<ph.PermissionStatus> check() async {
    checkCalls++;
    if (checkError != null) {
      throw checkError!;
    }
    return _valueAt(statusResults, checkCalls - 1, ph.PermissionStatus.denied);
  }

  Future<ph.PermissionStatus> request() async {
    requestCalls++;
    return _valueAt(
      requestResults,
      requestCalls - 1,
      ph.PermissionStatus.denied,
    );
  }

  Future<bool> openSettings() async {
    openSettingsCalls++;
    return _valueAt(settingsResults, openSettingsCalls - 1, false);
  }
}

T _valueAt<T>(List<T> values, int index, T fallback) {
  if (values.isEmpty) return fallback;
  if (index < values.length) return values[index];
  return values.last;
}
