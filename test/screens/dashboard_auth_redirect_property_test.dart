import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/core/domain/entities/user_profile.dart' as core_profile;
import 'package:flowfit/core/domain/repositories/profile_repository.dart'
    as core_profile_repo;
import 'package:flowfit/screens/dashboard_screen.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/domain/entities/auth_state.dart';
import 'package:flowfit/domain/entities/user.dart';
import 'package:flowfit/presentation/notifiers/auth_notifier.dart';
import 'package:flowfit/presentation/notifiers/profile_notifier.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';

void main() {
  group('DashboardScreen Auth State Redirect - Property Test', () {
    /// **Feature: dashboard-refactoring-merge, Property 14: Auth state change triggers redirect**
    /// **Validates: Requirements 9.2**
    ///
    /// Property: For any change in auth state from authenticated to unauthenticated,
    /// the system should redirect to the welcome/login screen.
    ///
    /// This property-based test verifies that auth state changes trigger proper redirects.
    testWidgets(
      'Property 14: Auth state change from authenticated to unauthenticated triggers redirect',
      (WidgetTester tester) async {
        // Arrange: Create an authenticated user
        final mockUser = User(
          id: 'test-user-auth',
          email: 'test@example.com',
          fullName: 'Test User',
          createdAt: DateTime.now(),
        );

        TestAuthRepository.setMockUser(mockUser);

        // Create a test notifier that starts authenticated
        final testNotifier = TestAuthNotifier(
          AuthState.authenticated(mockUser),
        );

        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith((ref) => testNotifier),
            profileNotifierProvider.overrideWith(
              (ref, userId) => TestProfileNotifier(userId),
            ),
          ],
        );

        // Track navigation events
        final navigatedRoutes = <String>[];
        // Act: Build app with dashboard
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              initialRoute: '/dashboard',
              onGenerateRoute: (settings) {
                navigatedRoutes.add(settings.name ?? 'unknown');

                if (settings.name == '/dashboard') {
                  return MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  );
                }
                if (settings.name == '/welcome') {
                  return MaterialPageRoute(
                    builder: (context) =>
                        const Scaffold(body: Text('Welcome Screen')),
                  );
                }
                return null;
              },
            ),
          ),
        );

        await pumpDashboardRoute(tester);

        // Verify dashboard is displayed initially
        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(navigatedRoutes, contains('/dashboard'));

        // Act: Simulate auth state change to unauthenticated
        // This simulates a logout or session expiration
        testNotifier.simulateAuthStateChange(AuthState.unauthenticated());

        // Wait for the listener to trigger and navigation to occur
        await pumpDashboardRoute(tester);

        // Assert: Should have navigated to welcome screen
        expect(
          find.text('Welcome Screen'),
          findsOneWidget,
          reason: 'Should navigate to welcome screen after auth state change',
        );

        expect(
          navigatedRoutes,
          contains('/welcome'),
          reason: 'Should have navigated to /welcome route',
        );

        // Verify dashboard is no longer in the tree (stack was cleared)
        expect(
          find.byType(DashboardScreen),
          findsNothing,
          reason: 'Dashboard should be removed from navigation stack',
        );

        // Clean up
        container.dispose();
      },
    );

    testWidgets(
      'Property 14: Multiple auth state changes all trigger redirects',
      (WidgetTester tester) async {
        // Test that the property holds for multiple state transitions
        final testCases = [
          {'userId': 'user1', 'email': 'user1@example.com'},
          {'userId': 'user2', 'email': 'user2@example.com'},
          {'userId': 'user3', 'email': 'user3@example.com'},
        ];

        for (final testCase in testCases) {
          // Arrange
          final mockUser = User(
            id: testCase['userId']!,
            email: testCase['email']!,
            fullName: 'Test User',
            createdAt: DateTime.now(),
          );

          TestAuthRepository.setMockUser(mockUser);

          final testNotifier = TestAuthNotifier(
            AuthState.authenticated(mockUser),
          );

          final container = ProviderContainer(
            overrides: [
              authNotifierProvider.overrideWith((ref) => testNotifier),
              profileNotifierProvider.overrideWith(
                (ref, userId) => TestProfileNotifier(userId),
              ),
            ],
          );

          // Act: Build dashboard
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                initialRoute: '/dashboard',
                onGenerateRoute: (settings) {
                  if (settings.name == '/dashboard') {
                    return MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    );
                  }
                  if (settings.name == '/welcome') {
                    return MaterialPageRoute(
                      builder: (context) =>
                          const Scaffold(body: Text('Welcome Screen')),
                    );
                  }
                  return null;
                },
              ),
            ),
          );

          await pumpDashboardRoute(tester);

          // Verify initial state
          expect(find.byType(DashboardScreen), findsOneWidget);

          // Act: Trigger auth state change
          testNotifier.simulateAuthStateChange(AuthState.unauthenticated());
          await pumpDashboardRoute(tester);

          // Assert: Should redirect to welcome
          expect(
            find.text('Welcome Screen'),
            findsOneWidget,
            reason: 'Should redirect to welcome for user ${testCase['userId']}',
          );

          // Clean up
          container.dispose();
          await tester.pumpWidget(Container());
          await pumpDashboardRoute(tester);
        }
      },
    );

    testWidgets('Property 14: Auth state change respects mounted check', (
      WidgetTester tester,
    ) async {
      // This test verifies that navigation only happens when widget is mounted
      // Arrange
      final mockUser = User(
        id: 'test-user-mounted',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
      );

      TestAuthRepository.setMockUser(mockUser);

      final testNotifier = TestAuthNotifier(AuthState.authenticated(mockUser));

      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith((ref) => testNotifier),
          profileNotifierProvider.overrideWith(
            (ref, userId) => TestProfileNotifier(userId),
          ),
        ],
      );

      // Act: Build dashboard
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            initialRoute: '/dashboard',
            onGenerateRoute: (settings) {
              if (settings.name == '/dashboard') {
                return MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                );
              }
              if (settings.name == '/welcome') {
                return MaterialPageRoute(
                  builder: (context) =>
                      const Scaffold(body: Text('Welcome Screen')),
                );
              }
              return null;
            },
          ),
        ),
      );

      await pumpDashboardRoute(tester);

      // Verify dashboard is mounted
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Act: Trigger auth state change while mounted
      testNotifier.simulateAuthStateChange(AuthState.unauthenticated());
      await pumpDashboardRoute(tester);

      // Assert: Should navigate successfully
      expect(find.text('Welcome Screen'), findsOneWidget);

      // Clean up
      container.dispose();
    });
  });
}

Future<void> pumpDashboardRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

/// Test implementation of AuthNotifier for testing purposes
/// This notifier allows us to simulate auth state changes
class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier(AuthState initialState) : super(TestAuthRepository()) {
    state = initialState;
  }

  @override
  Future<void> initialize() async {
    // Override to prevent async init from changing our test state
  }

  /// Simulate an auth state change for testing
  void simulateAuthStateChange(AuthState newState) {
    state = newState;
  }
}

/// Test implementation of IAuthRepository for testing purposes
class TestAuthRepository implements IAuthRepository {
  static User? _mockUser;

  static void setMockUser(User? user) {
    _mockUser = user;
  }

  @override
  Future<User?> getCurrentUser() async => _mockUser;

  @override
  Future<User> signIn({required String email, required String password}) async {
    _mockUser = _fakeAuthUser(email: email);
    return _mockUser!;
  }

  @override
  Future<void> signOut() async {
    _mockUser = null;
  }

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    Map<String, dynamic>? metadata,
  }) async {
    _mockUser = _fakeAuthUser(email: email, fullName: fullName);
    return _mockUser!;
  }

  @override
  Stream<User?> authStateChanges() {
    return Stream.value(null);
  }
}

User _fakeAuthUser({required String email, String? fullName}) {
  return User(
    id: 'test-auth-user',
    email: email,
    fullName: fullName,
    createdAt: DateTime.utc(2026),
    emailConfirmedAt: DateTime.utc(2026),
  );
}

class TestProfileNotifier extends ProfileNotifier {
  TestProfileNotifier(String userId) : super(TestProfileRepository(), userId);

  @override
  Future<void> loadProfile() async {
    state = const AsyncValue.data(null);
  }
}

class TestProfileRepository implements core_profile_repo.ProfileRepository {
  @override
  Future<void> deleteLocalProfile(String userId) async {}

  @override
  Future<core_profile.UserProfile?> getBackendProfile(String userId) async {
    return null;
  }

  @override
  Future<core_profile.UserProfile?> getLocalProfile(String userId) async {
    return null;
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    return true;
  }

  @override
  Future<bool> hasPendingSync(String userId) async {
    return false;
  }

  @override
  Future<void> saveBackendProfile(core_profile.UserProfile profile) async {}

  @override
  Future<void> saveLocalProfile(core_profile.UserProfile profile) async {}

  @override
  Future<void> syncProfile(String userId) async {}

  @override
  Stream<core_profile_repo.SyncStatus> watchSyncStatus(String userId) {
    return Stream.value(core_profile_repo.SyncStatus.synced);
  }
}
