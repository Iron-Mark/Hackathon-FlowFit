import 'package:flowfit/domain/entities/user.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/presentation/providers/providers.dart'
    hide profileRepositoryProvider;
import 'package:flowfit/presentation/providers/profile_providers.dart'
    as profile_providers;
import 'package:flowfit/screens/auth/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildHarness({
    IAuthRepository? authRepository,
    ProfileRepository? profileRepository,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          authRepository ?? _FakeAuthRepository(),
        ),
        profile_providers.profileRepositoryProvider.overrideWith(
          (ref) async => profileRepository ?? _FakeProfileRepository(),
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

    expect(find.text('Find Your Flow'), findsOneWidget);
    expect(find.textContaining('parent or guardian'), findsOneWidget);

    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('route:signup'), findsOneWidget);
  });

  testWidgets('Log In opens login', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Log In'));
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

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({
    Set<String>? completedUsers,
    this.throwOnLookup = false,
  }) : completedUsers = completedUsers ?? {};

  final Set<String> completedUsers;
  final bool throwOnLookup;

  @override
  Future<bool> hasCompletedSurveyOnBackend(String userId) async {
    if (throwOnLookup) {
      throw StateError('profile lookup unavailable');
    }
    return completedUsers.contains(userId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}
