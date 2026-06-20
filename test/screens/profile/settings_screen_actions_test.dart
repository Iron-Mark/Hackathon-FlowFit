import 'package:flowfit/screens/profile/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const settingsRoutes = <String, String>{
    'Privacy Policy': '/privacy-policy',
    'Notification Reminder': '/notification-settings',
    'App Integration': '/app-integration',
    'Language': '/language-settings',
    'Units': '/unit-settings',
    'Delete Account': '/delete-account',
    'Terms of Service': '/terms-of-service',
    'Help & Support': '/help-support',
    'About Us': '/about-us',
  };

  Widget buildHarness() {
    return MaterialApp(
      home: const SettingsScreen(),
      routes: {
        for (final route in settingsRoutes.values)
          route: (_) => Scaffold(body: Text('route:$route')),
      },
    );
  }

  testWidgets(
    'App Integration copy does not overpromise unsupported providers',
    (tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      expect(find.text('Manage supported integrations'), findsOneWidget);
      expect(find.text('Connect with other apps'), findsNothing);
    },
  );

  for (final entry in settingsRoutes.entries) {
    testWidgets('${entry.key} opens ${entry.value}', (tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(entry.key));
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();

      expect(find.text('route:${entry.value}'), findsOneWidget);
    });
  }
}
