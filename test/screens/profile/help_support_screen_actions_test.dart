import 'package:flowfit/core/config/flowfit_runtime_config.dart';
import 'package:flowfit/screens/profile/settings/general/help_support_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Email Support opens a mailto support request', (tester) async {
    final launchedUris = <Uri>[];

    await tester.pumpWidget(
      _harness(
        launchSupportEmail: (uri) async {
          launchedUris.add(uri);
          return true;
        },
      ),
    );

    await tester.tap(find.text('Email Support'));
    await tester.pump();

    expect(launchedUris, hasLength(1));
    expect(launchedUris.single.scheme, 'mailto');
    expect(launchedUris.single.path, FlowFitRuntimeConfig.supportEmail);
    expect(
      launchedUris.single.queryParameters['subject'],
      'FlowFit support request',
    );
    expect(launchedUris.single.queryParameters.containsKey('body'), isFalse);
  });

  testWidgets('Message Support opens a prefilled support email', (
    tester,
  ) async {
    final launchedUris = <Uri>[];

    await tester.pumpWidget(
      _harness(
        launchSupportEmail: (uri) async {
          launchedUris.add(uri);
          return true;
        },
      ),
    );

    await tester.tap(find.text('Message Support'));
    await tester.pump();

    expect(launchedUris, hasLength(1));
    expect(
      launchedUris.single.queryParameters['subject'],
      'FlowFit support request',
    );
    expect(
      launchedUris.single.queryParameters['body'],
      startsWith('Hi FlowFit support,'),
    );
  });

  testWidgets('Report a Bug opens a bug report email template', (tester) async {
    final launchedUris = <Uri>[];

    await tester.pumpWidget(
      _harness(
        launchSupportEmail: (uri) async {
          launchedUris.add(uri);
          return true;
        },
      ),
    );

    await tester.tap(find.text('Report a Bug'));
    await tester.pump();

    expect(launchedUris, hasLength(1));
    expect(
      launchedUris.single.queryParameters['subject'],
      'FlowFit bug report',
    );
    expect(
      launchedUris.single.queryParameters['body'],
      contains('Steps to reproduce:'),
    );
  });

  testWidgets(
    'support email actions show fallback when mail app is unavailable',
    (tester) async {
      await tester.pumpWidget(_harness(launchSupportEmail: (_) async => false));

      await tester.tap(find.text('Email Support'));
      await tester.pump();

      expect(
        find.text(
          'Email app unavailable. Contact ${FlowFitRuntimeConfig.supportEmail}.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('integration FAQ only promises supported Samsung setup', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(launchSupportEmail: (_) async => true));

    await tester.ensureVisible(find.text('How do I sync with other apps?'));
    await tester.tap(find.text('How do I sync with other apps?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Samsung Health Sensor API'), findsOneWidget);
    expect(
      find.textContaining('favorite health and fitness apps'),
      findsNothing,
    );
  });

  testWidgets('contact section does not claim unverified support hours', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(launchSupportEmail: (_) async => true));

    await tester.ensureVisible(find.text('Support Channel'));

    expect(find.text('Email support'), findsOneWidget);
    expect(find.textContaining('Mon-Fri'), findsNothing);
    expect(find.textContaining('EST'), findsNothing);
  });

  testWidgets('back button pops Help & Support', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/help',
        routes: {
          '/': (_) => const Scaffold(body: Text('route:root')),
          '/help': (_) => const HelpSupportScreen(),
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('route:root'), findsOneWidget);
  });
}

Widget _harness({required SupportEmailLauncher launchSupportEmail}) {
  return MaterialApp(
    home: HelpSupportScreen(launchSupportEmail: launchSupportEmail),
  );
}
