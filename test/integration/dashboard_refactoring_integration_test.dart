import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/domain/entities/auth_state.dart';
import 'package:flowfit/domain/entities/user.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/presentation/providers/profile_providers.dart'
    as profile_providers;
import 'package:flowfit/presentation/notifiers/auth_notifier.dart';
import 'package:flowfit/presentation/notifiers/profile_notifier.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/screens/dashboard_screen.dart';
import 'package:flowfit/screens/profile/kids_profile_screen.dart';

/// Integration tests for dashboard refactoring merge feature.
///
/// These tests verify:
/// - Initial tab navigation from route arguments
/// - Default and invalid tab index handling
///
/// Requirements: All requirements from dashboard-refactoring-merge spec
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dashboard Refactoring Integration Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    /// Helper to create test container with mocked providers
    ProviderContainer createTestContainer({
      required User user,
      required UserProfile profile,
      required MockProfileRepository repository,
    }) {
      return ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith((ref) {
            return MockAuthNotifier(user);
          }),
          profile_providers.profileRepositoryProvider.overrideWith(
            (ref) => Future.value(repository),
          ),
          profile_providers
              .profileNotifierProvider(user.id)
              .overrideWith(
                (ref) =>
                    ProfileNotifier(repository, user.id)
                      ..state = AsyncValue.data(profile),
              ),
        ],
      );
    }

    testWidgets(
      'INTEGRATION: Initial tab navigation from route arguments',
      (WidgetTester tester) async {
        // Create test data
        const testUserId = 'test-user-tab-nav';
        final testProfile = UserProfile(
          userId: testUserId,
          fullName: 'Tab Test User',
          age: 30,
          gender: 'Male',
          height: 175.0,
          weight: 75.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        final mockRepository = MockProfileRepository();
        await mockRepository.saveLocalProfile(testProfile);

        final mockUser = User(
          id: testUserId,
          email: 'test@example.com',
          fullName: 'Tab Test User',
          createdAt: DateTime.now(),
        );

        final container = createTestContainer(
          user: mockUser,
          profile: testProfile,
          repository: mockRepository,
        );

        // Build app with dashboard and initial tab argument
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/dashboard',
                            arguments: {'initialTab': 4}, // Navigate to Profile
                          );
                        },
                        child: const Text('Open Dashboard'),
                      ),
                    ),
                  );
                },
              ),
              routes: {
                '/dashboard': (context) => const DashboardScreen(),
                '/welcome': (context) =>
                    const Scaffold(body: Center(child: Text('Welcome'))),
              },
            ),
          ),
        );
        await pumpRouteTransition(tester);

        // Tap button to navigate to dashboard with initial tab
        await tester.tap(find.text('Open Dashboard'));
        await pumpRouteTransition(tester);

        // Verify we're on the dashboard
        expect(find.byType(DashboardScreen), findsOneWidget);

        // Verify Profile tab is selected (index 4)
        final bottomNavBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNavBar.currentIndex, 4);

        // Dashboard now routes the profile tab to the kids profile surface.
        expect(find.byType(KidsProfileScreen), findsOneWidget);

        container.dispose();
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'INTEGRATION: Default tab navigation when no arguments',
      (WidgetTester tester) async {
        const testUserId = 'test-user-default-tab';
        final testProfile = UserProfile(
          userId: testUserId,
          fullName: 'Default Tab User',
          age: 25,
          gender: 'Female',
          height: 160.0,
          weight: 55.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        final mockRepository = MockProfileRepository();
        await mockRepository.saveLocalProfile(testProfile);

        final mockUser = User(
          id: testUserId,
          email: 'default@example.com',
          fullName: 'Default Tab User',
          createdAt: DateTime.now(),
        );

        final container = createTestContainer(
          user: mockUser,
          profile: testProfile,
          repository: mockRepository,
        );

        // Build dashboard without initial tab argument
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: const DashboardScreen(),
              routes: {
                '/welcome': (context) =>
                    const Scaffold(body: Center(child: Text('Welcome'))),
              },
            ),
          ),
        );
        await pumpRouteTransition(tester);

        // Verify we're on the dashboard
        expect(find.byType(DashboardScreen), findsOneWidget);

        // Verify Home tab is selected by default (index 0)
        final bottomNavBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNavBar.currentIndex, 0);

        container.dispose();
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'INTEGRATION: Invalid tab index defaults to home',
      (WidgetTester tester) async {
        const testUserId = 'test-user-invalid-tab';
        final testProfile = UserProfile(
          userId: testUserId,
          fullName: 'Invalid Tab User',
          age: 27,
          gender: 'Male',
          height: 178.0,
          weight: 78.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        final mockRepository = MockProfileRepository();
        await mockRepository.saveLocalProfile(testProfile);

        final mockUser = User(
          id: testUserId,
          email: 'invalid@example.com',
          fullName: 'Invalid Tab User',
          createdAt: DateTime.now(),
        );

        final container = createTestContainer(
          user: mockUser,
          profile: testProfile,
          repository: mockRepository,
        );

        // Build app with invalid tab index
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/dashboard',
                            arguments: {'initialTab': 10}, // Invalid index
                          );
                        },
                        child: const Text('Open Dashboard'),
                      ),
                    ),
                  );
                },
              ),
              routes: {
                '/dashboard': (context) => const DashboardScreen(),
                '/welcome': (context) =>
                    const Scaffold(body: Center(child: Text('Welcome'))),
              },
            ),
          ),
        );
        await pumpRouteTransition(tester);

        // Navigate to dashboard
        await tester.tap(find.text('Open Dashboard'));
        await pumpRouteTransition(tester);

        // Verify we're on the dashboard
        expect(find.byType(DashboardScreen), findsOneWidget);

        // Verify Home tab is selected (defaults to 0 for invalid index)
        final bottomNavBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNavBar.currentIndex, 0);

        container.dispose();
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
  });
}

Future<void> pumpRouteTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

/// Mock AuthNotifier for testing
class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(User user) : super(MockAuthRepository(user)) {
    // Set initial authenticated state
    state = AuthState.authenticated(user);
  }

  @override
  Future<void> signOut() async {
    state = AuthState.unauthenticated();
  }
}

/// Mock AuthRepository for testing
class MockAuthRepository implements IAuthRepository {
  final User _user;

  MockAuthRepository(this._user);

  @override
  Future<User?> getCurrentUser() async => _user;

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    Map<String, dynamic>? metadata,
  }) async => _user;

  @override
  Future<User> signIn({
    required String email,
    required String password,
  }) async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Stream<User?> authStateChanges() {
    return Stream.value(_user);
  }
}

/// Mock ProfileRepository for testing
class MockProfileRepository implements ProfileRepository {
  final Map<String, UserProfile> _profiles = {};

  @override
  Future<UserProfile?> getLocalProfile(String userId) async {
    return _profiles[userId];
  }

  @override
  Future<void> saveLocalProfile(UserProfile profile) async {
    _profiles[profile.userId] = profile;
  }

  @override
  Future<void> deleteLocalProfile(String userId) async {
    _profiles.remove(userId);
  }

  @override
  Future<void> syncProfile(String userId) async {
    // No-op for testing
  }

  @override
  Future<UserProfile?> getBackendProfile(String userId) async {
    return _profiles[userId];
  }

  @override
  Future<void> saveBackendProfile(UserProfile profile) async {
    _profiles[profile.userId] = profile;
  }

  @override
  Future<bool> hasPendingSync(String userId) async {
    return false;
  }

  @override
  Stream<SyncStatus> watchSyncStatus(String userId) {
    return Stream.value(SyncStatus.synced);
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    return _profiles[userId] != null;
  }

  @override
  Future<bool> hasCompletedSurveyOnBackend(String userId) async => false;
}
