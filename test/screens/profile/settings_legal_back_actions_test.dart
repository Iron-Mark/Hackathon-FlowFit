import 'package:flowfit/screens/profile/settings/general/about_us_screen.dart';
import 'package:flowfit/screens/profile/settings/general/privacy_policy_screen.dart';
import 'package:flowfit/screens/profile/settings/general/terms_of_service_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const legalDestinations = <String, Widget>{
    'about': AboutUsScreen(),
    'privacy': PrivacyPolicyScreen(),
    'terms': TermsOfServiceScreen(),
  };

  for (final destination in legalDestinations.entries) {
    testWidgets('${destination.key} screen back button pops to settings', (
      tester,
    ) async {
      await tester.pumpWidget(
        _settingsBackHarness(
          route: '/${destination.key}',
          child: destination.value,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      expect(find.text('route:settings'), findsOneWidget);
    });
  }
}

Widget _settingsBackHarness({required String route, required Widget child}) {
  return MaterialApp(
    initialRoute: route,
    routes: {
      '/': (_) => const Scaffold(body: Text('route:settings')),
      route: (_) => child,
    },
  );
}
