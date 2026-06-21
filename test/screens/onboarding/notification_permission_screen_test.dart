import 'dart:async';

import 'package:flowfit/screens/onboarding/notification_permission_screen.dart';
import 'package:flowfit/providers/buddy_onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const permissionChannel = MethodChannel(
    'flutter.baseflow.com/permissions/methods',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, null);
  });

  Widget buildHarness() {
    return ProviderScope(
      child: MaterialApp(
        home: const NotificationPermissionScreen(),
        routes: {
          '/buddy-ready': (_) =>
              const Scaffold(body: Text('route:buddy-ready')),
        },
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> pumpScreenWithContainer(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: const NotificationPermissionScreen(),
          routes: {
            '/buddy-ready': (_) =>
                const Scaffold(body: Text('route:buddy-ready')),
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('Maybe later continues without requesting permission', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Maybe later'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('route:buddy-ready'), findsOneWidget);
  });

  testWidgets('Turn on notifications stores granted permission and continues', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (call) async {
          calls.add(call);
          if (call.method == 'requestPermissions') {
            return <int, int>{17: 1};
          }
          return null;
        });

    await pumpScreenWithContainer(tester, container);

    await tester.tap(find.text('TURN ON NOTIFICATIONS'));
    await tester.pumpAndSettle();

    expect(
      calls.where((call) => call.method == 'requestPermissions'),
      hasLength(1),
    );
    expect(
      container.read(buddyOnboardingProvider).notificationsGranted,
      isTrue,
    );
    expect(find.text('route:buddy-ready'), findsOneWidget);
  });

  testWidgets('Turn on notifications ignores duplicate in-flight requests', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final permissionCompleter = Completer<Map<int, int>>();
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (call) async {
          calls.add(call);
          if (call.method == 'requestPermissions') {
            return permissionCompleter.future;
          }
          return null;
        });

    await pumpScreenWithContainer(tester, container);

    final turnOnButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'TURN ON NOTIFICATIONS'),
    );
    final onPressed = turnOnButton.onPressed!;

    onPressed();
    onPressed();
    await tester.pump();

    expect(find.text('REQUESTING...'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'REQUESTING...'),
          )
          .onPressed,
      isNull,
    );
    expect(
      calls.where((call) => call.method == 'requestPermissions'),
      hasLength(1),
    );
    expect(find.text('route:buddy-ready'), findsNothing);

    permissionCompleter.complete(<int, int>{17: 1});
    await tester.pumpAndSettle();

    expect(
      calls.where((call) => call.method == 'requestPermissions'),
      hasLength(1),
    );
    expect(
      container.read(buddyOnboardingProvider).notificationsGranted,
      isTrue,
    );
    expect(find.text('route:buddy-ready'), findsOneWidget);
  });

  testWidgets('permission request failure resets button and stays on screen', (
    tester,
  ) async {
    final permissionCompleter = Completer<void>();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (call) async {
          await permissionCompleter.future;
          throw PlatformException(
            code: 'permission_error',
            message: 'Permission API unavailable',
          );
        });

    await pumpScreen(tester);

    await tester.tap(find.text('TURN ON NOTIFICATIONS'));
    await tester.pump();
    expect(find.text('REQUESTING...'), findsOneWidget);

    permissionCompleter.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('route:buddy-ready'), findsNothing);
    expect(find.text('TURN ON NOTIFICATIONS'), findsOneWidget);
    expect(
      find.text(
        'Could not request notifications. You can try again or continue without reminders.',
      ),
      findsOneWidget,
    );
  });
}
