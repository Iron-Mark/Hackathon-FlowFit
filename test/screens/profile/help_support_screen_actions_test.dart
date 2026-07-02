import 'dart:async';

import 'package:flowfit/core/config/flowfit_runtime_config.dart';
import 'package:flowfit/screens/profile/settings/general/help_support_screen.dart';
import 'package:flowfit/services/support_request_service.dart';
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

  testWidgets('Message Support submits an in-app support request', (
    tester,
  ) async {
    SupportRequestDraft? submittedDraft;

    await tester.pumpWidget(
      _harness(
        submitSupportRequest: (draft) async {
          submittedDraft = draft;
          return 'support-request-id';
        },
      ),
    );

    await tester.tap(find.text('Message Support'));
    await tester.pumpAndSettle();

    expect(find.text('Send support request'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Message'),
      'I need help with my FlowFit account.',
    );
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(submittedDraft, isNotNull);
    expect(submittedDraft?.category, 'support');
    expect(submittedDraft?.subject, 'FlowFit support request');
    expect(submittedDraft?.message, 'I need help with my FlowFit account.');
    expect(find.text('Support request sent.'), findsOneWidget);
  });

  testWidgets('Report a Bug submits an in-app bug report template', (
    tester,
  ) async {
    SupportRequestDraft? submittedDraft;

    await tester.pumpWidget(
      _harness(
        submitSupportRequest: (draft) async {
          submittedDraft = draft;
          return 'bug-request-id';
        },
      ),
    );

    await tester.tap(find.text('Report a Bug'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(submittedDraft, isNotNull);
    expect(submittedDraft?.category, 'bug');
    expect(submittedDraft?.subject, 'FlowFit bug report');
    expect(submittedDraft?.message, contains('Steps to reproduce:'));
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

  testWidgets('support email actions ignore duplicate taps while pending', (
    tester,
  ) async {
    final launchedUris = <Uri>[];
    final launchCompleter = Completer<bool>();

    await tester.pumpWidget(
      _harness(
        launchSupportEmail: (uri) {
          launchedUris.add(uri);
          return launchCompleter.future;
        },
      ),
    );

    await tester.tap(find.text('Email Support'));
    await tester.tap(find.text('Email Support'), warnIfMissed: false);
    await tester.pump();

    expect(launchedUris, hasLength(1));

    launchCompleter.complete(true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Email Support'));
    await tester.pump();

    expect(launchedUris, hasLength(2));
  });

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

    expect(find.text('In-app requests'), findsOneWidget);
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

Widget _harness({
  SupportEmailLauncher? launchSupportEmail,
  SupportRequestSubmitter? submitSupportRequest,
}) {
  return MaterialApp(
    home: HelpSupportScreen(
      launchSupportEmail: launchSupportEmail ?? (_) async => true,
      submitSupportRequest:
          submitSupportRequest ?? (_) async => 'support-request-id',
    ),
  );
}
