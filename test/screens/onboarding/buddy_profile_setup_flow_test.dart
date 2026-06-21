import 'package:flowfit/providers/buddy_onboarding_provider.dart';
import 'package:flowfit/screens/onboarding/buddy_naming_screen.dart';
import 'package:flowfit/screens/onboarding/buddy_profile_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpFlow(
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
          home: const BuddyNamingScreen(),
          routes: {
            '/buddy_profile_setup': (_) => const BuddyProfileSetupScreen(),
            '/goal-selection': (_) =>
                const Scaffold(body: Text('route:goal-selection')),
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> completeNaming(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter a name...'),
      'Bubbles',
    );
    await tester.pump();
    await tester.tap(find.text('THAT\'S PERFECT!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('naming opens profile setup before goals', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await pumpFlow(tester, container);

    await completeNaming(tester);

    expect(find.text('Tell Bubbles about yourself!'), findsOneWidget);
    expect(find.text('Your Nickname (optional)'), findsOneWidget);
  });

  testWidgets('naming suggestion fills the input and can be submitted', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await pumpFlow(tester, container);

    await tester.ensureVisible(find.text('Splash'));
    await tester.tap(find.text('Splash'));
    await tester.pump();

    expect(find.widgetWithText(TextField, 'Splash'), findsOneWidget);

    await tester.tap(find.text('THAT\'S PERFECT!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(buddyOnboardingProvider).buddyName, 'Splash');
    expect(find.text('Tell Splash about yourself!'), findsOneWidget);
  });

  testWidgets('profile setup continue saves optional info and opens goals', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await pumpFlow(tester, container);

    await completeNaming(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'What should we call you?'),
      'Captain',
    );
    await tester.pump();
    await tester.tap(find.text('9'));
    await tester.pump();
    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final state = container.read(buddyOnboardingProvider);
    expect(state.buddyName, 'Bubbles');
    expect(state.userNickname, 'Captain');
    expect(state.userAge, 9);
    expect(find.text('route:goal-selection'), findsOneWidget);
  });

  testWidgets('profile setup skip opens goals without overwriting info', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await pumpFlow(tester, container);

    await completeNaming(tester);

    await tester.tap(find.text('SKIP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final state = container.read(buddyOnboardingProvider);
    expect(state.buddyName, 'Bubbles');
    expect(state.userNickname, isNull);
    expect(state.userAge, isNull);
    expect(find.text('route:goal-selection'), findsOneWidget);
  });
}
