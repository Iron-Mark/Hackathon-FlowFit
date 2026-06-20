import 'package:flowfit/providers/buddy_onboarding_provider.dart';
import 'package:flowfit/providers/buddy_offline_storage_provider.dart';
import 'package:flowfit/screens/onboarding/age_gate_screen.dart';
import 'package:flowfit/screens/onboarding/buddy_intro_screen.dart';
import 'package:flowfit/screens/onboarding/buddy_welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('age gate sends kids to Buddy onboarding', (tester) async {
    await _pumpWithRoutes(
      tester,
      home: const AgeGateScreen(),
      routes: {
        '/buddy-welcome': (_) =>
            const Scaffold(body: Text('route:buddy-welcome')),
        '/survey_intro': (_) => const Scaffold(body: Text('route:survey')),
      },
    );

    await tester.tap(find.text("I'm 7-12 years old"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('route:buddy-welcome'), findsOneWidget);
    expect(find.text('route:survey'), findsNothing);
  });

  testWidgets('age gate sends teens and adults to survey onboarding', (
    tester,
  ) async {
    await _pumpWithRoutes(
      tester,
      home: const AgeGateScreen(),
      routes: {
        '/buddy-welcome': (_) =>
            const Scaffold(body: Text('route:buddy-welcome')),
        '/survey_intro': (_) => const Scaffold(body: Text('route:survey')),
      },
    );

    await tester.tap(find.text("I'm 13 or older"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('route:survey'), findsOneWidget);
    expect(find.text('route:buddy-welcome'), findsNothing);
  });

  testWidgets('Buddy welcome CTA opens the intro screen route', (tester) async {
    await _pumpWithRoutes(
      tester,
      home: const BuddyWelcomeScreen(),
      routes: {
        '/buddy-intro': (_) => const Scaffold(body: Text('route:buddy-intro')),
      },
    );

    await tester.tap(find.text("LET'S GO!"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('route:buddy-intro'), findsOneWidget);
  });

  testWidgets('Buddy intro skip opens hatch without writing a user name', (
    tester,
  ) async {
    final container = _buddyTestContainer();
    addTearDown(container.dispose);

    await _pumpBuddyIntro(tester, container);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('route:buddy-hatch'), findsOneWidget);
    expect(container.read(buddyOnboardingProvider).userName, isNull);
  });

  testWidgets('Buddy intro NEXT saves the user name before opening hatch', (
    tester,
  ) async {
    final container = _buddyTestContainer();
    addTearDown(container.dispose);

    await _pumpBuddyIntro(tester, container);

    final nextButton = find.widgetWithText(ElevatedButton, 'NEXT');
    expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Mark');
    await tester.pump();

    expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNotNull);

    await tester.tap(find.text('NEXT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(buddyOnboardingProvider).userName, 'Mark');
    expect(find.text('route:buddy-hatch'), findsOneWidget);
  });
}

Future<void> _pumpWithRoutes(
  WidgetTester tester, {
  required Widget home,
  required Map<String, WidgetBuilder> routes,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: home, routes: routes),
    ),
  );
  await tester.pump();
}

Future<void> _pumpBuddyIntro(
  WidgetTester tester,
  ProviderContainer container,
) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: const BuddyIntroScreen(),
        routes: {
          '/buddy-hatch': (_) =>
              const Scaffold(body: Text('route:buddy-hatch')),
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

ProviderContainer _buddyTestContainer() {
  return ProviderContainer(
    overrides: [buddyOfflineStorageProvider.overrideWithValue(null)],
  );
}
