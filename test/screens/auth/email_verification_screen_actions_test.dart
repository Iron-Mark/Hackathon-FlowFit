import 'package:flowfit/screens/auth/email_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gotrue/gotrue.dart' as gotrue;

void main() {
  testWidgets('manual check shows a message when email is not verified yet', (
    tester,
  ) async {
    var checkCalls = 0;

    await tester.pumpWidget(
      _harness(
        checkVerificationStatus: () async {
          checkCalls++;
          return false;
        },
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('I\'ve Verified My Email'));

    expect(checkCalls, 1);
    expect(
      find.text('Email not verified yet. Please check your inbox.'),
      findsOneWidget,
    );
  });

  testWidgets('manual check navigates to age gate when email is verified', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        checkVerificationStatus: () async => true,
        navigationDelay: Duration.zero,
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('I\'ve Verified My Email'));
    await tester.pumpAndSettle();

    expect(find.text('route:age-gate:user-123'), findsOneWidget);
  });

  testWidgets('resend sends verification email and starts cooldown', (
    tester,
  ) async {
    final resentEmails = <String>[];

    await tester.pumpWidget(
      _harness(
        resendVerificationEmail: (email) async {
          resentEmails.add(email);
        },
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Resend Verification Email'));
    await tester.pump();

    expect(resentEmails, ['member@flowfit.test']);
    expect(find.textContaining('Verification email sent'), findsOneWidget);
    expect(find.text('Resend in 60s'), findsOneWidget);
  });

  testWidgets('resend surfaces missing email route arguments', (tester) async {
    var resendCalls = 0;

    await tester.pumpWidget(
      _harness(
        email: null,
        resendVerificationEmail: (_) async {
          resendCalls++;
        },
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Resend Verification Email'));
    await tester.pump();

    expect(resendCalls, 0);
    expect(find.textContaining('Error sending email:'), findsOneWidget);
  });
}

Widget _harness({
  String? email = 'member@flowfit.test',
  EmailVerificationStatusChecker? checkVerificationStatus,
  EmailVerificationEmailResender? resendVerificationEmail,
  Duration navigationDelay = const Duration(milliseconds: 500),
}) {
  return ProviderScope(
    child: MaterialApp(
      initialRoute: '/email-verification',
      onGenerateRoute: (settings) {
        if (settings.name == '/age-gate') {
          final args = settings.arguments! as Map<String, dynamic>;
          return MaterialPageRoute<void>(
            builder: (_) =>
                Scaffold(body: Text('route:age-gate:${args['userId']}')),
          );
        }

        return MaterialPageRoute<void>(
          settings: RouteSettings(
            name: '/email-verification',
            arguments: {
              'name': 'Test Member',
              if (email != null) 'email': email,
              'userId': 'user-123',
            },
          ),
          builder: (_) => EmailVerificationScreen(
            checkVerificationStatus: checkVerificationStatus,
            resendVerificationEmail: resendVerificationEmail,
            authStateChanges: () => const Stream<gotrue.AuthState>.empty(),
            autoCheckInterval: null,
            navigationDelay: navigationDelay,
          ),
        );
      },
    ),
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}
