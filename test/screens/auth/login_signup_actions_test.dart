import 'dart:async';

import 'package:flowfit/domain/entities/user.dart' as domain_user;
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/screens/auth/login_screen.dart';
import 'package:flowfit/screens/auth/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginScreen actions', () {
    testWidgets('forgot password requires a valid email before sending', (
      tester,
    ) async {
      var resetCalls = 0;

      await tester.pumpWidget(
        _loginHarness(
          sendPasswordReset: (_, {redirectTo}) async {
            resetCalls++;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(resetCalls, 0);
      expect(find.text('Enter your email address first'), findsOneWidget);
    });

    testWidgets('forgot password sends reset email with redirect URL', (
      tester,
    ) async {
      final calls = <_ResetCall>[];

      await tester.pumpWidget(
        _loginHarness(
          sendPasswordReset: (email, {redirectTo}) async {
            calls.add(_ResetCall(email, redirectTo));
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your email'),
        'member@flowfit.test',
      );
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(calls, hasLength(1));
      expect(calls.single.email, 'member@flowfit.test');
      expect(calls.single.redirectTo, 'com.msiazondev.flowfit://auth-callback');
      expect(
        find.text('Password reset email sent. Check your inbox.'),
        findsOneWidget,
      );
    });

    testWidgets('forgot password surfaces reset failures', (tester) async {
      await tester.pumpWidget(
        _loginHarness(
          sendPasswordReset: (_, {redirectTo}) async {
            throw StateError('mail unavailable');
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your email'),
        'member@flowfit.test',
      );
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not send reset email. Try again later.'),
        findsOneWidget,
      );
    });

    testWidgets('signup link opens the signup route', (tester) async {
      await tester.pumpWidget(_loginHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('route:signup'), findsOneWidget);
    });
  });

  group('SignUpScreen actions', () {
    testWidgets('required consent blocks account creation', (tester) async {
      final authRepository = _FakeAuthRepository();

      await tester.pumpWidget(_signupHarness(authRepository: authRepository));
      await tester.pumpAndSettle();

      await _enterSignupFields(tester);
      await _tapCreateAccount(tester);

      expect(authRepository.signUpCalls, 0);
      expect(
        find.text('Please accept required terms to continue'),
        findsOneWidget,
      );
    });

    testWidgets('verified signup opens age gate with consent metadata', (
      tester,
    ) async {
      final authRepository = _FakeAuthRepository();

      await tester.pumpWidget(_signupHarness(authRepository: authRepository));
      await tester.pumpAndSettle();

      await _enterSignupFields(tester);
      await _acceptRequiredSignupConsent(tester);
      await _tapCreateAccount(tester);

      expect(authRepository.signUpCalls, 1);
      expect(authRepository.lastSignUpEmail, 'member@flowfit.test');
      expect(authRepository.lastSignUpFullName, 'Test Member');
      expect(authRepository.lastSignUpMetadata, {
        'terms_accepted': true,
        'watch_data_consent': true,
        'marketing_opt_in': false,
      });
      expect(find.text('route:age-gate:test-user'), findsOneWidget);
    });

    testWidgets('create account ignores duplicate submit while pending', (
      tester,
    ) async {
      final signUpCompleter = Completer<void>();
      final authRepository = _FakeAuthRepository(
        signUpCompleter: signUpCompleter,
      );

      await tester.pumpWidget(_signupHarness(authRepository: authRepository));
      await tester.pumpAndSettle();

      await _enterSignupFields(tester);
      await _acceptRequiredSignupConsent(tester);

      final createButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create Account'),
      );

      createButton.onPressed!();
      createButton.onPressed!();
      await tester.pump();

      expect(authRepository.signUpCalls, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      signUpCompleter.complete();
      await tester.pumpAndSettle();

      expect(authRepository.signUpCalls, 1);
      expect(find.text('route:age-gate:test-user'), findsOneWidget);
    });

    testWidgets('unverified signup opens email verification with user args', (
      tester,
    ) async {
      final authRepository = _FakeAuthRepository(signedUpEmailVerified: false);

      await tester.pumpWidget(_signupHarness(authRepository: authRepository));
      await tester.pumpAndSettle();

      await _enterSignupFields(tester);
      await _acceptRequiredSignupConsent(tester);
      await _tapCreateAccount(tester);

      expect(authRepository.signUpCalls, 1);
      expect(
        find.text('route:email:Test Member:member@flowfit.test:test-user'),
        findsOneWidget,
      );
    });

    testWidgets('Read Terms opens the terms route', (tester) async {
      await tester.pumpWidget(_signupHarness());
      await tester.pumpAndSettle();

      await _tapConsentLink(tester, 'Read Terms');

      expect(find.text('route:terms'), findsOneWidget);
    });

    testWidgets('Read Policy opens the privacy route', (tester) async {
      await tester.pumpWidget(_signupHarness());
      await tester.pumpAndSettle();

      await _tapConsentLink(tester, 'Read Policy');

      expect(find.text('route:privacy'), findsOneWidget);
    });

    testWidgets('login link opens the login route', (tester) async {
      await tester.pumpWidget(_signupHarness());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Log In'));
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('route:login'), findsOneWidget);
    });
  });
}

Widget _loginHarness({PasswordResetSender? sendPasswordReset}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    ],
    child: MaterialApp(
      home: LoginScreen(sendPasswordReset: sendPasswordReset),
      routes: {
        '/dashboard': (_) => const _RouteMarker('route:dashboard'),
        '/signup': (_) => const _RouteMarker('route:signup'),
      },
    ),
  );
}

Widget _signupHarness({_FakeAuthRepository? authRepository}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        authRepository ?? _FakeAuthRepository(),
      ),
    ],
    child: MaterialApp(
      home: const SignUpScreen(),
      routes: {
        '/login': (_) => const _RouteMarker('route:login'),
        '/terms-of-service': (_) => const _RouteMarker('route:terms'),
        '/privacy-policy': (_) => const _RouteMarker('route:privacy'),
        '/age-gate': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments!
                  as Map<String, dynamic>;
          return _RouteMarker('route:age-gate:${args['userId']}');
        },
        '/email_verification': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments!
                  as Map<String, dynamic>;
          return _RouteMarker(
            'route:email:${args['name']}:${args['email']}:${args['userId']}',
          );
        },
      },
    ),
  );
}

Future<void> _enterSignupFields(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Enter your full name'),
    'Test Member',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Enter your email'),
    'member@flowfit.test',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Enter your password'),
    'TestPassword123!',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Re-enter your password'),
    'TestPassword123!',
  );
}

Future<void> _acceptRequiredSignupConsent(WidgetTester tester) async {
  final checkboxes = find.byType(Checkbox);
  await tester.ensureVisible(checkboxes.at(0));
  await tester.tap(checkboxes.at(0));
  await tester.pumpAndSettle();
  await tester.ensureVisible(checkboxes.at(1));
  await tester.tap(checkboxes.at(1));
  await tester.pumpAndSettle();
}

Future<void> _tapCreateAccount(WidgetTester tester) async {
  final button = find.text('Create Account');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _tapConsentLink(WidgetTester tester, String label) async {
  final link = find.text(label);
  await tester.ensureVisible(link);
  await tester.pumpAndSettle();
  await tester.tap(link);
  await tester.pumpAndSettle();
}

class _ResetCall {
  const _ResetCall(this.email, this.redirectTo);

  final String email;
  final String? redirectTo;
}

class _RouteMarker extends StatelessWidget {
  const _RouteMarker(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

class _FakeAuthRepository implements IAuthRepository {
  _FakeAuthRepository({
    this.signedUpEmailVerified = true,
    this.signUpCompleter,
  });

  final bool signedUpEmailVerified;
  final Completer<void>? signUpCompleter;
  int signUpCalls = 0;
  domain_user.User? currentUser;
  String? lastSignUpEmail;
  String? lastSignUpFullName;
  Map<String, dynamic>? lastSignUpMetadata;

  @override
  Stream<domain_user.User?> authStateChanges() => Stream.value(currentUser);

  @override
  Future<domain_user.User?> getCurrentUser() async => currentUser;

  @override
  Future<domain_user.User> signIn({
    required String email,
    required String password,
  }) async {
    currentUser = _user(email: email);
    return currentUser!;
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
  }

  @override
  Future<domain_user.User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    signUpCalls++;
    lastSignUpEmail = email;
    lastSignUpFullName = fullName;
    lastSignUpMetadata = Map<String, dynamic>.from(metadata);
    await signUpCompleter?.future;
    currentUser = _user(
      email: email,
      fullName: fullName,
      emailConfirmed: signedUpEmailVerified,
    );
    return currentUser!;
  }

  domain_user.User _user({
    required String email,
    String? fullName,
    bool emailConfirmed = true,
  }) {
    return domain_user.User(
      id: 'test-user',
      email: email,
      fullName: fullName,
      createdAt: DateTime(2026),
      emailConfirmedAt: emailConfirmed ? DateTime(2026) : null,
    );
  }
}
