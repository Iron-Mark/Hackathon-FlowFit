import 'dart:async';

import 'package:flowfit/core/config/flowfit_runtime_config.dart';
import 'package:flowfit/screens/profile/settings/general/help_support_screen.dart';
import 'package:flowfit/services/support_request_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Message Support is the primary in-app support action', (
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
    expect(find.text('Email Support'), findsNothing);
    expect(find.text(FlowFitRuntimeConfig.supportEmail), findsOneWidget);
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

  testWidgets('support requests ignore duplicate submits while pending', (
    tester,
  ) async {
    final submitCompleter = Completer<String>();
    var submitCalls = 0;

    await tester.pumpWidget(
      _harness(
        submitSupportRequest: (_) {
          submitCalls++;
          return submitCompleter.future;
        },
      ),
    );

    await tester.tap(find.text('Message Support'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Message'),
      'I need help with my FlowFit account.',
    );
    await tester.tap(find.text('Send'));
    await tester.pump();

    await tester.tap(find.text('Message Support'), warnIfMissed: false);
    await tester.pump();

    expect(submitCalls, 1);

    submitCompleter.complete('support-request-id');
    await tester.pumpAndSettle();

    expect(find.text('Support request sent.'), findsOneWidget);
  });

  testWidgets('integration FAQ only promises supported Samsung setup', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());

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
    await tester.pumpWidget(_harness());

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

Widget _harness({SupportRequestSubmitter? submitSupportRequest}) {
  return MaterialApp(
    home: HelpSupportScreen(
      submitSupportRequest:
          submitSupportRequest ?? (_) async => 'support-request-id',
    ),
  );
}
