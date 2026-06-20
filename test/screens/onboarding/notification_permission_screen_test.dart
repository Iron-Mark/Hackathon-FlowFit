import 'dart:async';

import 'package:flowfit/screens/onboarding/notification_permission_screen.dart';
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

  testWidgets('Maybe later continues without requesting permission', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Maybe later'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

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
