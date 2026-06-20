import 'package:flowfit/screens/wear/sensor_permission_rationale_screen.dart';
import 'package:flowfit/services/watch_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Grant Access returns true when permission is granted', (
    tester,
  ) async {
    final bridge = _FakeWatchBridge(requestPermissionResult: true);
    bool? result;

    await tester.pumpWidget(
      _pushHarness(bridge: bridge, onResult: (value) => result = value),
    );

    await tester.tap(find.text('Open Rationale'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grant Access'));
    await tester.pumpAndSettle();

    expect(bridge.requestPermissionCalls, 1);
    expect(result, isTrue);
    expect(find.text('Open Rationale'), findsOneWidget);
  });

  testWidgets('Grant Access denial restores actions with feedback', (
    tester,
  ) async {
    final bridge = _FakeWatchBridge(requestPermissionResult: false);

    await tester.pumpWidget(_screenHarness(bridge: bridge));

    await tester.tap(find.text('Grant Access'));
    await tester.pumpAndSettle();

    expect(bridge.requestPermissionCalls, 1);
    expect(find.text('Grant Access'), findsOneWidget);
    expect(
      find.text('Permission denied. Please grant access to continue.'),
      findsOneWidget,
    );
  });

  testWidgets('Grant Access failure restores actions with error feedback', (
    tester,
  ) async {
    final bridge = _FakeWatchBridge(
      requestPermissionError: StateError('permission channel unavailable'),
    );

    await tester.pumpWidget(_screenHarness(bridge: bridge));

    await tester.tap(find.text('Grant Access'));
    await tester.pumpAndSettle();

    expect(find.text('Grant Access'), findsOneWidget);
    expect(find.textContaining('Error requesting permission:'), findsOneWidget);
  });

  testWidgets('Open Settings failure explains manual recovery', (tester) async {
    final bridge = _FakeWatchBridge(checkPermissionResult: 'denied');

    await tester.pumpWidget(
      _screenHarness(bridge: bridge, openSettings: () async => false),
    );

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Open Settings'), findsOneWidget);
    expect(find.textContaining('Could not open app settings'), findsOneWidget);
  });

  testWidgets(
    'Open Settings denied return explains permission still disabled',
    (tester) async {
      final bridge = _FakeWatchBridge(checkPermissionResult: 'denied');

      await tester.pumpWidget(
        _screenHarness(bridge: bridge, openSettings: () async => true),
      );

      await tester.tap(find.text('Open Settings'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(bridge.checkPermissionCalls, 1);
      expect(find.text('Open Settings'), findsOneWidget);
      expect(
        find.textContaining('Sensor access is still disabled'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Open Settings granted return pops true', (tester) async {
    final bridge = _FakeWatchBridge(checkPermissionResult: 'granted');
    bool? result;

    await tester.pumpWidget(
      _pushHarness(
        bridge: bridge,
        openSettings: () async => true,
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.text('Open Rationale'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Settings'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(bridge.checkPermissionCalls, 1);
    expect(result, isTrue);
    expect(find.text('Open Rationale'), findsOneWidget);
  });
}

Widget _screenHarness({
  required WatchBridgeService bridge,
  SensorPermissionSettingsOpener? openSettings,
}) {
  return MaterialApp(
    home: SensorPermissionRationaleScreen(
      watchBridgeFactory: () => bridge,
      openSettings: openSettings,
    ),
  );
}

Widget _pushHarness({
  required WatchBridgeService bridge,
  SensorPermissionSettingsOpener? openSettings,
  required ValueChanged<bool?> onResult,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final value = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => SensorPermissionRationaleScreen(
                      watchBridgeFactory: () => bridge,
                      openSettings: openSettings,
                    ),
                  ),
                );
                onResult(value);
              },
              child: const Text('Open Rationale'),
            ),
          ),
        );
      },
    ),
  );
}

class _FakeWatchBridge extends WatchBridgeService {
  _FakeWatchBridge({
    this.requestPermissionResult = false,
    this.requestPermissionError,
    this.checkPermissionResult = 'denied',
  });

  final bool requestPermissionResult;
  final Object? requestPermissionError;
  final String checkPermissionResult;
  int requestPermissionCalls = 0;
  int checkPermissionCalls = 0;

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    if (requestPermissionError != null) {
      throw requestPermissionError!;
    }
    return requestPermissionResult;
  }

  @override
  Future<String> checkPermission() async {
    checkPermissionCalls++;
    return checkPermissionResult;
  }

  @override
  void dispose() {}
}
