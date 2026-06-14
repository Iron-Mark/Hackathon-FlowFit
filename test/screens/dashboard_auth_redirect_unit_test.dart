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
  group('Dashboard Auth Redirect - Unit Tests', () {
    /// Test that unauthenticated state triggers navigation
    /// Requirements: 9.1, 9.3
    testWidgets('Unauthenticated state triggers navigation to welcome screen', (
      WidgetTester tester,
    ) async {
      // Arrange: Create an authenticated user initially
      final mockUser = User(
        id: 'test-user',
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

      final navigatedRoutes = <String>[];

      // Act: Build dashboard
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

      // Verify initial state
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Act: Change to unauthenticated state
      testNotifier.simulateAuthStateChange(AuthState.unauthenticated());
      await pumpDashboardRoute(tester);

      // Assert: Should navigate to welcome
      expect(
        find.text('Welcome Screen'),
        findsOneWidget,
        reason: 'Should navigate to welcome screen when unauthenticated',
      );

      expect(
        navigatedRoutes,
        contains('/welcome'),
        reason: 'Should have navigated to /welcome route',
      );

      container.dispose();
    });

    /// Test that navigation clears the stack
    /// Requirements: 9.1, 9.3
    testWidgets('Navigation to welcome clears navigation stack', (
      WidgetTester tester,
    ) async {
      // Arrange
      final mockUser = User(
        id: 'test-user',
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

      // Verify dashboard is displayed
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Act: Trigger auth state change
      testNotifier.simulateAuthStateChange(AuthState.unauthenticated());
      await pumpDashboardRoute(tester);

      // Assert: Dashboard should no longer be in the tree
      expect(
        find.byType(DashboardScreen),
        findsNothing,
        reason: 'Dashboard should be removed from navigation stack',
      );

      // Welcome screen should be displayed
      expect(
        find.text('Welcome Screen'),
        findsOneWidget,
        reason: 'Welcome screen should be displayed',
      );

      // Try to pop - should not be able to go back to dashboard
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(
        navigator.canPop(),
        isFalse,
        reason: 'Should not be able to pop back to dashboard',
      );

      container.dispose();
    });

    /// Test that the correct route is used
    /// Requirements: 9.1, 9.3
    testWidgets('Correct route (/welcome) is used for redirect', (
      WidgetTester tester,
    ) async {
      // Arrange
      final mockUser = User(
        id: 'test-user',
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

      String? lastNavigatedRoute;

      // Act: Build dashboard
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            initialRoute: '/dashboard',
            onGenerateRoute: (settings) {
              lastNavigatedRoute = settings.name;

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
              if (settings.name == '/login') {
                return MaterialPageRoute(
                  builder: (context) =>
                      const Scaffold(body: Text('Login Screen')),
                );
              }
              return null;
            },
          ),
        ),
      );

      await pumpDashboardRoute(tester);

      // Act: Trigger auth state change
      testNotifier.simulateAuthStateChange(AuthState.unauthenticated());
      await pumpDashboardRoute(tester);

      // Assert: Should use /welcome route, not /login
      expect(
        lastNavigatedRoute,
        equals('/welcome'),
        reason: 'Should navigate to /welcome route (not /login)',
      );

      // Verify welcome screen is displayed (not login)
      expect(find.text('Welcome Screen'), findsOneWidget);
      expect(find.text('Login Screen'), findsNothing);

      container.dispose();
    });

    /// Test that mounted check prevents navigation errors
    /// Requirements: 9.1, 9.3
    testWidgets('Mounted check prevents navigation when widget is disposed', (
      WidgetTester tester,
    ) async {
      // Arrange
      final mockUser = User(
        id: 'test-user',
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

      // Act: Dispose the widget tree
      await tester.pumpWidget(Container());
      await tester.pump();

      // Trigger auth state change after widget is disposed
      // This should not cause an error due to mounted check
      expect(
        () => testNotifier.simulateAuthStateChange(AuthState.unauthenticated()),
        returnsNormally,
        reason: 'Should not throw error when widget is not mounted',
      );

      await pumpDashboardRoute(tester);

      container.dispose();
    });

    /// Test initial auth check on dashboard init
    /// Requirements: 9.1
    testWidgets(
      'Dashboard redirects to welcome if user is not authenticated on init',
      (WidgetTester tester) async {
        // Arrange: Start with unauthenticated state
        TestAuthRepository.setMockUser(null);

        final testNotifier = TestAuthNotifier(AuthState.unauthenticated());

        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith((ref) => testNotifier),
            profileNotifierProvider.overrideWith(
              (ref, userId) => TestProfileNotifier(userId),
            ),
          ],
        );

        // Act: Build dashboard with unauthenticated user
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

        // Assert: Should redirect to welcome immediately
        expect(
          find.text('Welcome Screen'),
          findsOneWidget,
          reason: 'Should redirect to welcome when not authenticated on init',
        );

        expect(
          find.byType(DashboardScreen),
          findsNothing,
          reason: 'Dashboard should not be displayed',
        );

        container.dispose();
      },
    );
  });
}

Future<void> pumpDashboardRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

/// Test implementation of AuthNotifier for testing purposes
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
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    Map<String, dynamic>? metadata,
  }) async {
    throw UnimplementedError();
  }

  @override
  Stream<User?> authStateChanges() {
    return Stream.value(null);
  }
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
