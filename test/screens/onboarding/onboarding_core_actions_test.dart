import 'package:flowfit/providers/buddy_offline_storage_provider.dart';
import 'package:flowfit/providers/buddy_onboarding_provider.dart';
import 'package:flowfit/screens/onboarding/goal_selection_screen.dart';
import 'package:flowfit/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('classic onboarding advances pages and opens dashboard', (
    tester,
  ) async {
    await _pumpClassicOnboarding(tester);

    expect(find.text('Track Your Heart Rate'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Next'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
    await tester.pumpAndSettle();

    expect(find.text('Personalized Workouts'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
    await tester.pumpAndSettle();

    expect(find.text('Track Your Progress'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Get Started'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('route:dashboard'), findsOneWidget);
  });

  testWidgets('classic onboarding skip opens dashboard immediately', (
    tester,
  ) async {
    await _pumpClassicOnboarding(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('route:dashboard'), findsOneWidget);
  });

  testWidgets('goal selection toggles selected goals and continues', (
    tester,
  ) async {
    final container = _buddyContainer();
    addTearDown(container.dispose);

    await _pumpGoalSelection(tester, container);

    await tester.tap(find.text('Boost focus and productivity'));
    await tester.pump();
    expect(container.read(buddyOnboardingProvider).selectedGoals, ['focus']);

    await tester.tap(find.text('Stay fresh and clean'));
    await tester.pump();
    expect(container.read(buddyOnboardingProvider).selectedGoals, [
      'focus',
      'hygiene',
    ]);

    await tester.tap(find.text('Boost focus and productivity'));
    await tester.pump();
    expect(container.read(buddyOnboardingProvider).selectedGoals, ['hygiene']);

    await tester.tap(find.widgetWithText(ElevatedButton, 'NEXT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('route:notification-permission'), findsOneWidget);
  });
}

Future<void> _pumpClassicOnboarding(WidgetTester tester) async {
  await _setPhoneViewport(tester);

  await tester.pumpWidget(
    MaterialApp(
      home: const OnboardingScreen(),
      routes: {
        '/dashboard': (_) => const Scaffold(body: Text('route:dashboard')),
      },
    ),
  );
  await tester.pump();
}

Future<void> _pumpGoalSelection(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await _setPhoneViewport(tester);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: const GoalSelectionScreen(),
        routes: {
          '/notification-permission': (_) =>
              const Scaffold(body: Text('route:notification-permission')),
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

ProviderContainer _buddyContainer() {
  return ProviderContainer(
    overrides: [buddyOfflineStorageProvider.overrideWithValue(null)],
  );
}

Future<void> _setPhoneViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
