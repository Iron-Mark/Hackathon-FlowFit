import 'package:flowfit/domain/entities/user.dart';
import 'package:flowfit/domain/entities/user_profile.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/domain/repositories/i_profile_repository.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('unauthenticated startup opens welcome', (tester) async {
    await _pumpSplash(tester, authRepository: _FakeAuthRepository());

    await tester.pumpAndSettle();

    expect(find.text('route:welcome'), findsOneWidget);
  });

  testWidgets('completed profile startup opens dashboard', (tester) async {
    await _pumpSplash(
      tester,
      authRepository: _FakeAuthRepository(initialUser: _testUser()),
      profileRepository: _FakeProfileRepository(completedUsers: {'user-123'}),
    );

    await tester.pumpAndSettle();

    expect(find.text('route:dashboard'), findsOneWidget);
  });

  testWidgets('incomplete profile startup opens age gate with user id', (
    tester,
  ) async {
    await _pumpSplash(
      tester,
      authRepository: _FakeAuthRepository(initialUser: _testUser()),
      profileRepository: _FakeProfileRepository(),
    );

    await tester.pumpAndSettle();

    expect(find.text('route:age-gate:user-123'), findsOneWidget);
  });

  testWidgets('profile lookup failure stays on splash and retries', (
    tester,
  ) async {
    final profileRepository = _FakeProfileRepository(throwOnLookup: true);

    await _pumpSplash(
      tester,
      authRepository: _FakeAuthRepository(initialUser: _testUser()),
      profileRepository: profileRepository,
    );

    await tester.pumpAndSettle();

    expect(find.text('route:dashboard'), findsNothing);
    expect(
      find.text(
        'Could not check your account setup. Check your connection and try again.',
      ),
      findsOneWidget,
    );

    profileRepository
      ..throwOnLookup = false
      ..completedUsers.add('user-123');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Try Again'));
    await tester.pumpAndSettle();

    expect(find.text('route:dashboard'), findsOneWidget);
  });
}

Future<void> _pumpSplash(
  WidgetTester tester, {
  required IAuthRepository authRepository,
  IProfileRepository? profileRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        profileRepositoryProvider.overrideWithValue(
          profileRepository ?? _FakeProfileRepository(),
        ),
      ],
      child: MaterialApp(
        home: const SplashScreen(minimumDisplayDuration: Duration.zero),
        routes: {
          '/welcome': (_) => const Scaffold(body: Text('route:welcome')),
          '/dashboard': (_) => const Scaffold(body: Text('route:dashboard')),
          '/age-gate': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return Scaffold(body: Text('route:age-gate:${args?['userId']}'));
          },
        },
      ),
    ),
  );
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
  Stream<User?> authStateChanges() => Stream.value(currentUser);

  @override
  Future<User?> getCurrentUser() async => currentUser;

  @override
  Future<User> signIn({required String email, required String password}) async {
    currentUser = _testUser();
    return currentUser!;
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
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
  bool throwOnLookup;

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
