import 'package:flowfit/screens/profile/settings/general/app_integration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const AppIntegrationScreen(),
        routes: {
          '/wellness-onboarding': (_) =>
              const Scaffold(body: Text('Wellness setup opened')),
        },
      ),
    );
  }

  testWidgets('unsupported providers are visible but not actionable', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Connect'), findsNothing);
    expect(find.textContaining('Connect with'), findsNothing);
    expect(find.textContaining('Sync'), findsNothing);
    expect(find.textContaining('Import'), findsNothing);
    expect(find.text('Details'), findsNothing);
    expect(find.text('Not supported'), findsWidgets);
    expect(find.text('Not supported in this build'), findsWidgets);

    await tester.tap(find.text('Google Fit'));
    await tester.pumpAndSettle();

    expect(find.text('Google Fit'), findsWidgets);
    expect(
      find.text(
        'Direct account sync for this provider is not available in this build.',
      ),
      findsNothing,
    );
  });

  testWidgets('Samsung Health setup opens the wellness onboarding route', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.ensureVisible(find.text('Samsung Health'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set Up'));
    await tester.pumpAndSettle();

    expect(find.text('Wellness setup opened'), findsOneWidget);
  });
}
