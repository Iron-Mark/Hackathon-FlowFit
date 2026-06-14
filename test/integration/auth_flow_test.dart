import 'package:flowfit/domain/entities/user.dart' as domain_user;
import 'package:flowfit/domain/entities/user_profile.dart' as domain_profile;
import 'package:flowfit/domain/exceptions/auth_exceptions.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/domain/repositories/i_profile_repository.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/screens/auth/signup_screen.dart';
import 'package:flowfit/screens/onboarding/age_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Complete Signup Flow Integration Tests', () {
    testWidgets(
      'INTEGRATION: Signup with verified email navigates to age gate',
      (tester) async {
        await _pumpSignupHarness(tester);

        await _enterSignupForm(
          tester,
          email: 'new_user@flowfit.test',
          password: 'TestPassword123!',
        );
        await _tapAndSettle(tester, find.text('Create Account'));

        expect(find.text('Welcome to FlowFit!'), findsOneWidget);
        expect(find.text("I'm 7-12 years old"), findsOneWidget);
        expect(find.text("I'm 13 or older"), findsOneWidget);
      },
    );

    testWidgets('INTEGRATION: Signup with duplicate email shows error', (
      tester,
    ) async {
      await _pumpSignupHarness(
        tester,
        authRepository: _FakeAuthRepository(
          duplicateEmails: {'existing@flowfit.test'},
        ),
      );

      await _enterSignupForm(
        tester,
        email: 'existing@flowfit.test',
        password: 'TestPassword123!',
      );
      await _tapAndSettle(tester, find.text('Create Account'));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('An account with this email already exists'),
        findsOneWidget,
      );
    });

    testWidgets(
      'INTEGRATION: Signup with invalid email shows validation error',
      (tester) async {
        await _pumpSignupHarness(tester);

        await _enterSignupForm(
          tester,
          email: 'notanemail',
          password: 'TestPassword123!',
        );
        await _tapAndSettle(tester, find.text('Create Account'));

        expect(find.text('Please enter a valid email'), findsOneWidget);
      },
    );
  });
}

Future<void> _pumpSignupHarness(
  WidgetTester tester, {
  _FakeAuthRepository? authRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          authRepository ?? _FakeAuthRepository(),
        ),
        profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
      ],
      child: MaterialApp(
        home: const SignUpScreen(),
        routes: {
          '/age-gate': (context) => const AgeGateScreen(),
          '/email_verification': (context) =>
              const _RouteMarker('Verify Your Email'),
          '/login': (context) => const _RouteMarker('Login'),
          '/dashboard': (context) => const _RouteMarker('Dashboard'),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enterSignupForm(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await _enterTextAndSettle(
    tester,
    find.widgetWithText(TextFormField, 'Enter your full name'),
    'Test User',
  );
  await _enterTextAndSettle(
    tester,
    find.widgetWithText(TextFormField, 'Enter your email'),
    email,
  );
  await _enterTextAndSettle(
    tester,
    find.widgetWithText(TextFormField, 'Enter your password'),
    password,
  );
  await _enterTextAndSettle(
    tester,
    find.widgetWithText(TextFormField, 'Re-enter your password'),
    password,
  );

  final checkboxes = find.byType(Checkbox);
  await _tapAndSettle(tester, checkboxes.at(0));
  await _tapAndSettle(tester, checkboxes.at(1));
}

Future<void> _enterTextAndSettle(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  final target = finder.first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.enterText(target, text);
  await tester.pumpAndSettle();
}

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  final target = finder.first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
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
  _FakeAuthRepository({Set<String>? duplicateEmails})
    : duplicateEmails = duplicateEmails ?? {};

  final Set<String> duplicateEmails;
  domain_user.User? currentUser;

  @override
  Future<domain_user.User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    if (duplicateEmails.contains(email)) {
      throw EmailAlreadyExistsException();
    }

    currentUser = domain_user.User(
      id: 'test-user',
      email: email,
      fullName: fullName,
      createdAt: DateTime(2025),
      emailConfirmedAt: DateTime(2025),
    );
    return currentUser!;
  }

  @override
  Future<domain_user.User> signIn({
    required String email,
    required String password,
  }) async {
    currentUser = domain_user.User(
      id: 'test-user',
      email: email,
      fullName: 'Test User',
      createdAt: DateTime(2025),
      emailConfirmedAt: DateTime(2025),
    );
    return currentUser!;
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
  }

  @override
  Future<domain_user.User?> getCurrentUser() async => currentUser;

  @override
  Stream<domain_user.User?> authStateChanges() => Stream.value(currentUser);
}

class _FakeProfileRepository implements IProfileRepository {
  final Map<String, domain_profile.UserProfile> _profiles = {};

  @override
  Future<domain_profile.UserProfile> createProfile(
    domain_profile.UserProfile profile,
  ) async {
    _profiles[profile.userId] = profile;
    return profile;
  }

  @override
  Future<domain_profile.UserProfile?> getProfile(String userId) async {
    return _profiles[userId];
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    return _profiles.containsKey(userId);
  }

  @override
  Future<domain_profile.UserProfile> updateProfile(
    domain_profile.UserProfile profile,
  ) async {
    _profiles[profile.userId] = profile;
    return profile;
  }
}
