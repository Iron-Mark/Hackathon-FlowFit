import 'package:flowfit/screens/wellness/wellness_onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpOnboarding(
    WidgetTester tester, {
    required WellnessSetupChecker setupChecker,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WellnessOnboardingScreen(setupChecker: setupChecker),
        routes: {
          '/wellness-tracker': (_) =>
              const Scaffold(body: Text('Wellness tracker opened')),
        },
      ),
    );
  }

  Future<void> moveToSetupStep(WidgetTester tester) async {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }

  testWidgets('successful setup check unlocks onboarding completion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var checks = 0;

    await pumpOnboarding(
      tester,
      setupChecker: () async {
        checks += 1;
        return const WellnessSetupStatus(
          hasPermissions: true,
          isWatchConnected: true,
          message: 'Setup verified. You can start wellness tracking.',
        );
      },
    );

    await moveToSetupStep(tester);
    await tester.tap(find.text('Check Setup'));
    await tester.pumpAndSettle();

    expect(checks, 1);
    expect(find.text('Granted'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(
      find.text('Setup verified. You can start wellness tracking.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Wellness tracker opened'), findsOneWidget);
    expect(prefs.getBool('wellness_onboarding_complete'), isTrue);
  });

  testWidgets('failed setup check keeps onboarding incomplete', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await pumpOnboarding(
      tester,
      setupChecker: () async {
        return const WellnessSetupStatus(
          hasPermissions: false,
          isWatchConnected: false,
          message:
              'Still needed: body sensors permission, location permission, Samsung Galaxy Watch connection.',
        );
      },
    );

    await moveToSetupStep(tester);
    await tester.tap(find.text('Check Setup'));
    await tester.pumpAndSettle();

    expect(find.text('Check Setup'), findsOneWidget);
    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Not Connected'), findsOneWidget);
    expect(
      find.text(
        'Still needed: body sensors permission, location permission, Samsung Galaxy Watch connection.',
      ),
      findsWidgets,
    );
    expect(find.text('Wellness tracker opened'), findsNothing);
    expect(prefs.getBool('wellness_onboarding_complete'), isNull);
  });
}
