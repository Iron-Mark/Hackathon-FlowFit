import 'package:flowfit/domain/entities/user.dart' as domain_user;
import 'package:flowfit/domain/entities/user_profile.dart' as domain_profile;
import 'package:flowfit/domain/exceptions/auth_exceptions.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/domain/repositories/i_profile_repository.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/screens/auth/login_screen.dart';
import 'package:flowfit/screens/onboarding/age_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow Integration Tests', () {
    testWidgets(
      'INTEGRATION: Login with complete profile navigates to dashboard',
      (tester) async {
        await _pumpLoginHarness(
          tester,
          profileRepository: _FakeProfileRepository(
            completedUsers: {'test-user'},
          ),
        );

        await _enterLoginForm(
          tester,
          email: 'complete_user@flowfit.test',
          password: 'TestPassword123!',
        );
        await _tapAndSettle(tester, find.text('Log In').last);

        expect(find.text('Dashboard'), findsOneWidget);
      },
    );

    testWidgets(
      'INTEGRATION: Login with incomplete profile navigates to age gate',
      (tester) async {
        await _pumpLoginHarness(tester);

        await _enterLoginForm(
          tester,
          email: 'incomplete_user@flowfit.test',
          password: 'TestPassword123!',
        );
        await _tapAndSettle(tester, find.text('Log In').last);

        expect(find.text('Welcome to FlowFit!'), findsOneWidget);
        expect(find.text("I'm 13 or older"), findsOneWidget);
      },
    );

    testWidgets('INTEGRATION: Login with invalid credentials shows error', (
      tester,
    ) async {
      await _pumpLoginHarness(
        tester,
        authRepository: _FakeAuthRepository(
          invalidCredentialEmails: {'nonexistent@flowfit.test'},
        ),
      );

      await _enterLoginForm(
        tester,
        email: 'nonexistent@flowfit.test',
        password: 'WrongPassword123!',
      );
      await _tapAndSettle(tester, find.text('Log In').last);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Invalid email or password'), findsOneWidget);
    });

    testWidgets(
      'INTEGRATION: profile lookup failure does not navigate to dashboard',
      (tester) async {
        await _pumpLoginHarness(
          tester,
          profileRepository: _FakeProfileRepository(throwOnLookup: true),
        );

        await _enterLoginForm(
          tester,
          email: 'lookup_failure@flowfit.test',
          password: 'TestPassword123!',
        );
        await _tapAndSettle(tester, find.text('Log In').last);

        expect(find.text('Dashboard'), findsNothing);
        expect(find.text('Welcome Back!'), findsOneWidget);
        expect(
          find.text(
            'Could not check onboarding status. Check your connection and try again.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('INTEGRATION: Session persistence redirects existing user', (
      tester,
    ) async {
      await _pumpLoginHarness(
        tester,
        authRepository: _FakeAuthRepository(
          initialUser: _testUser(email: 'session_test@flowfit.test'),
        ),
        profileRepository: _FakeProfileRepository(
          completedUsers: {'test-user'},
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Welcome Back!'), findsNothing);
    });
  });

  group('Unavailable social sign-in shortcuts', () {
    testWidgets('Login screen does not expose fake social auth buttons', (
      tester,
    ) async {
      await _pumpLoginHarness(tester);

      expect(find.text('Sign in with Google'), findsNothing);
      expect(find.text('Sign in with Apple'), findsNothing);
      expect(find.text('Or sign in with'), findsNothing);
      expect(find.text('Welcome Back!'), findsOneWidget);
    });
  });
}

Future<void> _pumpLoginHarness(
  WidgetTester tester, {
  _FakeAuthRepository? authRepository,
  _FakeProfileRepository? profileRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          authRepository ?? _FakeAuthRepository(),
        ),
        profileRepositoryProvider.overrideWithValue(
          profileRepository ?? _FakeProfileRepository(),
        ),
      ],
      child: MaterialApp(
        home: const LoginScreen(),
        routes: {
          '/age-gate': (context) => const AgeGateScreen(),
          '/dashboard': (context) => const _RouteMarker('Dashboard'),
          '/signup': (context) => const _RouteMarker('Sign Up'),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enterLoginForm(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
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

domain_user.User _testUser({required String email}) {
  return domain_user.User(
    id: 'test-user',
    email: email,
    fullName: 'Test User',
    createdAt: DateTime(2025),
    emailConfirmedAt: DateTime(2025),
  );
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
  _FakeAuthRepository({this.initialUser, Set<String>? invalidCredentialEmails})
    : invalidCredentialEmails = invalidCredentialEmails ?? {},
      currentUser = initialUser;

  final domain_user.User? initialUser;
  final Set<String> invalidCredentialEmails;
  domain_user.User? currentUser;

  @override
  Future<domain_user.User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    currentUser = _testUser(email: email).copyWith(fullName: fullName);
    return currentUser!;
  }

  @override
  Future<domain_user.User> signIn({
    required String email,
    required String password,
  }) async {
    if (invalidCredentialEmails.contains(email)) {
      throw InvalidCredentialsException();
    }

    currentUser = _testUser(email: email);
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
  _FakeProfileRepository({
    Set<String>? completedUsers,
    this.throwOnLookup = false,
  }) : completedUsers = completedUsers ?? {};

  final Set<String> completedUsers;
  final bool throwOnLookup;
  final Map<String, domain_profile.UserProfile> _profiles = {};

  @override
  Future<domain_profile.UserProfile> createProfile(
    domain_profile.UserProfile profile,
  ) async {
    _profiles[profile.userId] = profile;
    completedUsers.add(profile.userId);
    return profile;
  }

  @override
  Future<domain_profile.UserProfile?> getProfile(String userId) async {
    return _profiles[userId];
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    if (throwOnLookup) {
      throw StateError('profile lookup unavailable');
    }
    return completedUsers.contains(userId) || _profiles.containsKey(userId);
  }

  @override
  Future<domain_profile.UserProfile> updateProfile(
    domain_profile.UserProfile profile,
  ) async {
    _profiles[profile.userId] = profile;
    completedUsers.add(profile.userId);
    return profile;
  }
}
