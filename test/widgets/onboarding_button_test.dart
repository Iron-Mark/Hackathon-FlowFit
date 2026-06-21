import 'package:flowfit/widgets/onboarding_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('primary onboarding button invokes enabled action', (
    tester,
  ) async {
    var pressCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingButton(
            label: 'Continue',
            onPressed: () => pressCalls++,
          ),
        ),
      ),
    );

    expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(pressCalls, 1);
  });

  testWidgets('secondary onboarding button invokes enabled action', (
    tester,
  ) async {
    var pressCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingButton(
            label: 'Back',
            isPrimary: false,
            onPressed: () => pressCalls++,
          ),
        ),
      ),
    );

    expect(find.widgetWithText(OutlinedButton, 'Back'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pump();

    expect(pressCalls, 1);
  });

  testWidgets('disabled onboarding button does not invoke action', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OnboardingButton(label: 'Wait')),
      ),
    );

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Wait'),
    );

    expect(button.onPressed, isNull);
  });
}
