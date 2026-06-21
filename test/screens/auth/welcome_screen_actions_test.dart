import 'package:flowfit/domain/entities/user.dart';
import 'package:flowfit/domain/entities/user_profile.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/domain/repositories/i_profile_repository.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/screens/auth/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildHarness({
    IAuthRepository? authRepository,
    IProfileRepository? profileRepository,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          authRepository ?? _FakeAuthRepository(),
        ),
        profileRepositoryProvider.overrideWithValue(
          profileRepository ?? _FakeProfileRepository(),
        ),
      ],
      child: MaterialApp(
        home: const WelcomeScreen(),
        routes: {
          '/signup': (_) => const Scaffold(body: Text('route:signup')),
          '/login': (_) => const Scaffold(body: Text('route:login')),
          '/dashboard': (_) => const Scaffold(body: Text('route:dashboard')),
          '/age-gate': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return Scaffold(body: Text('route:age-gate:${args?['userId']}'));
          },
        },
      ),
    );
  }

  testWidgets('Get Started opens signup', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('route:signup'), findsOneWidget);
  });

  testWidgets('Log In opens login', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('route:login'), findsOneWidget);
  });

  testWidgets('authenticated completed user opens dashboard', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        authRepository: _FakeAuthRepository(initialUser: _testUser()),
        profileRepository: _FakeProfileRepository(completedUsers: {'user-123'}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('route:dashboard'), findsOneWidget);
  });

  testWidgets('authenticated incomplete user opens age gate', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        authRepository: _FakeAuthRepository(initialUser: _testUser()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('route:age-gate:user-123'), findsOneWidget);
    expect(find.text('route:dashboard'), findsNothing);
  });

  testWidgets('profile lookup failure keeps welcome visible', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        authRepository: _FakeAuthRepository(initialUser: _testUser()),
        profileRepository: _FakeProfileRepository(throwOnLookup: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Find Your Flow'), findsOneWidget);
    expect(
      find.text(
        'Could not check onboarding status. Check your connection and try again.',
      ),
      findsOneWidget,
    );
  });
}

User _testUser() {
  return User(
    id: 'user-123',
    email: 'member@flowfit.test',
    fullName: 'FlowFit Member',
    createdAt: DateTime(2026),
  );
}

class _FakeAuthRepository implements IAuthRepository {
  _FakeAuthRepository({this.initialUser}) : currentUser = initialUser;

  final User? initialUser;
  User? currentUser;

  @override
  Stream<User?> authStateChanges() => const Stream<User?>.empty();

  @override
  Future<User?> getCurrentUser() async => currentUser;

  @override
  Future<void> signOut() async {
    currentUser = null;
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    currentUser = _testUser();
    return currentUser!;
  }

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    currentUser = _testUser();
    return currentUser!;
  }
}

class _FakeProfileRepository implements IProfileRepository {
  _FakeProfileRepository({
    Set<String>? completedUsers,
    this.throwOnLookup = false,
  }) : completedUsers = completedUsers ?? {};

  final Set<String> completedUsers;
  final bool throwOnLookup;

  @override
  Future<UserProfile> createProfile(UserProfile profile) async {
    completedUsers.add(profile.userId);
    return profile;
  }

  @override
  Future<UserProfile?> getProfile(String userId) async => null;

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    if (throwOnLookup) {
      throw StateError('profile lookup unavailable');
    }
    return completedUsers.contains(userId);
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    completedUsers.add(profile.userId);
    return profile;
  }
}
