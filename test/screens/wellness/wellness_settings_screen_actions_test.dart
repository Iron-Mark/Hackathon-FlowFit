import 'package:flowfit/providers/wellness_state_provider.dart';
import 'package:flowfit/screens/wellness/wellness_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('wellness settings persist alert preferences', (tester) async {
    SharedPreferences.setMockInitialValues({
      'wellness_stress_alerts_enabled': true,
      'wellness_cardio_alerts_enabled': true,
      'wellness_alert_frequency_minutes': 30,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: WellnessSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stress Alerts'));
    await tester.pumpAndSettle();

    expect(prefs.getBool('wellness_stress_alerts_enabled'), isFalse);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 hour').last);
    await tester.pumpAndSettle();

    expect(prefs.getInt('wellness_alert_frequency_minutes'), 60);
  });

  testWidgets('privacy policy action opens the privacy route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: const WellnessSettingsScreen(),
          routes: {
            '/privacy-policy': (_) =>
                const Scaffold(body: Text('Privacy route opened')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Privacy Policy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();

    expect(find.text('Privacy route opened'), findsOneWidget);
  });

  testWidgets('clear wellness history copy is local-device scoped', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'wellness_history': '[]',
      'wellness_transitions': '[]',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: WellnessSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Clear Wellness History'));
    await tester.pumpAndSettle();
    expect(find.text('Clear local device wellness history'), findsOneWidget);

    await tester.tap(find.text('Clear Wellness History'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This clears local wellness state history and transitions on this device. It does not delete account, workout, heart-rate, or Supabase records.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Clear'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Local wellness history cleared'), findsOneWidget);
    expect(prefs.containsKey('wellness_history'), isFalse);
    expect(prefs.containsKey('wellness_transitions'), isFalse);
  });
}
