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
  group('DashboardScreen Initial Tab Navigation - Property Test', () {
    /// **Feature: dashboard-refactoring-merge, Property 2: Initial tab navigation from route arguments**
    /// **Validates: Requirements 2.1**
    ///
    /// Property: For any valid initialTab parameter in route arguments,
    /// the dashboard should set its current index to that value.
    ///
    /// This property-based test verifies the behavior by checking the selected
    /// tab indicator in the BottomNavigationBar for all valid indices (0-4).
    testWidgets(
      'Property 2: For any valid initialTab (0-4), dashboard displays correct tab',
      (WidgetTester tester) async {
        // Property-based test: Test all valid tab indices (0-4)
        // This simulates "for any valid tab index" by testing each value
        final validTabIndices = [0, 1, 2, 3, 4];
        final tabLabels = ['Home', 'Health', 'Track', 'Progress', 'Profile'];

        for (int i = 0; i < validTabIndices.length; i++) {
          final tabIndex = validTabIndices[i];
          final expectedLabel = tabLabels[i];

          // Arrange: Create authenticated state
          final mockUser = User(
            id: 'test-user-$tabIndex',
            email: 'test$tabIndex@example.com',
            fullName: 'Test User $tabIndex',
            createdAt: DateTime.now(),
          );

          // Set the mock user so TestAuthRepository.getCurrentUser() returns it
          TestAuthRepository.setMockUser(mockUser);

          // Create a test notifier that's already authenticated
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

          // Act: Build app with dashboard as initial route with arguments
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                initialRoute: '/dashboard',
                onGenerateRoute: (settings) {
                  if (settings.name == '/dashboard') {
                    return MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                      settings: RouteSettings(
                        name: '/dashboard',
                        arguments: {'initialTab': tabIndex},
                      ),
                    );
                  }
                  if (settings.name == '/welcome') {
                    return MaterialPageRoute(
                      builder: (context) =>
                          const Scaffold(body: Text('Welcome')),
                    );
                  }
                  return null;
                },
              ),
            ),
          );

          // Wait for widget to build and settle
          await pumpDashboardRoute(tester);

          // Debug: Check what widgets are actually rendered
          final scaffoldFinder = find.byType(Scaffold);
          if (scaffoldFinder.evaluate().isEmpty) {
            fail('No Scaffold found in widget tree');
          }

          // Check if we were redirected to welcome screen
          final welcomeTextFinder = find.text('Welcome');
          if (welcomeTextFinder.evaluate().isNotEmpty) {
            fail('Dashboard redirected to Welcome screen - auth state issue');
          }

          // Assert: Verify the correct tab is selected by checking BottomNavigationBar
          final bottomNavBarFinder = find.byType(BottomNavigationBar);
          if (bottomNavBarFinder.evaluate().isEmpty) {
            // Print widget tree for debugging
            debugPrint(
              'Widget tree: ${tester.allWidgets.map((w) => w.runtimeType).toList()}',
            );
            fail('BottomNavigationBar not found in widget tree');
          }

          final bottomNavBar = tester.widget<BottomNavigationBar>(
            bottomNavBarFinder,
          );

          expect(
            bottomNavBar.currentIndex,
            equals(tabIndex),
            reason:
                'For initialTab=$tabIndex, currentIndex should be $tabIndex',
          );

          // Additional verification: Check that the correct tab label is highlighted
          // The selected item should have the primary color
          final selectedItem = bottomNavBar.items[tabIndex];
          expect(
            selectedItem.label,
            equals(expectedLabel),
            reason: 'Tab at index $tabIndex should be $expectedLabel',
          );

          // Clean up
          container.dispose();
          await tester.pumpWidget(Container());
          await pumpDashboardRoute(tester);
        }
      },
    );

    testWidgets('Property 2: Null initialTab defaults to tab 0 (Home)', (
      WidgetTester tester,
    ) async {
      // Arrange
      final mockUser = User(
        id: 'test-user-null',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
      );

      TestAuthRepository.setMockUser(mockUser);

      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith((ref) {
            return TestAuthNotifier(AuthState.authenticated(mockUser));
          }),
          profileNotifierProvider.overrideWith(
            (ref, userId) => TestProfileNotifier(userId),
          ),
        ],
      );

      // Act: Build without initialTab argument
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            initialRoute: '/dashboard',
            onGenerateRoute: (settings) {
              if (settings.name == '/dashboard') {
                return MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                  // No arguments - initialTab will be null
                );
              }
              if (settings.name == '/welcome') {
                return MaterialPageRoute(
                  builder: (context) => const Scaffold(body: Text('Welcome')),
                );
              }
              return null;
            },
          ),
        ),
      );

      await pumpDashboardRoute(tester);

      // Assert: Should default to tab 0
      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(
        bottomNavBar.currentIndex,
        equals(0),
        reason: 'When initialTab is null, currentIndex should default to 0',
      );

      container.dispose();
    });

    testWidgets('Property 2: Invalid initialTab (negative) defaults to tab 0', (
      WidgetTester tester,
    ) async {
      // Test multiple invalid negative values
      final invalidIndices = [-1, -5, -100];

      for (final tabIndex in invalidIndices) {
        // Arrange
        final mockUser = User(
          id: 'test-user-$tabIndex',
          email: 'test@example.com',
          fullName: 'Test User',
          createdAt: DateTime.now(),
        );

        TestAuthRepository.setMockUser(mockUser);

        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith((ref) {
              return TestAuthNotifier(AuthState.authenticated(mockUser));
            }),
            profileNotifierProvider.overrideWith(
              (ref, userId) => TestProfileNotifier(userId),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              initialRoute: '/dashboard',
              onGenerateRoute: (settings) {
                if (settings.name == '/dashboard') {
                  return MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                    settings: RouteSettings(
                      name: '/dashboard',
                      arguments: {'initialTab': tabIndex},
                    ),
                  );
                }
                if (settings.name == '/welcome') {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(body: Text('Welcome')),
                  );
                }
                return null;
              },
            ),
          ),
        );

        await pumpDashboardRoute(tester);

        // Assert: Should remain at 0 for invalid indices
        final bottomNavBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );

        expect(
          bottomNavBar.currentIndex,
          equals(0),
          reason:
              'For invalid initialTab=$tabIndex, currentIndex should remain 0',
        );

        // Clean up
        container.dispose();
        await tester.pumpWidget(Container());
        await pumpDashboardRoute(tester);
      }
    });

    testWidgets('Property 2: Invalid initialTab (> 4) defaults to tab 0', (
      WidgetTester tester,
    ) async {
      // Test multiple invalid values greater than max
      final invalidIndices = [5, 10, 100];

      for (final tabIndex in invalidIndices) {
        // Arrange
        final mockUser = User(
          id: 'test-user-$tabIndex',
          email: 'test@example.com',
          fullName: 'Test User',
          createdAt: DateTime.now(),
        );

        TestAuthRepository.setMockUser(mockUser);

        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith((ref) {
              return TestAuthNotifier(AuthState.authenticated(mockUser));
            }),
            profileNotifierProvider.overrideWith(
              (ref, userId) => TestProfileNotifier(userId),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              initialRoute: '/dashboard',
              onGenerateRoute: (settings) {
                if (settings.name == '/dashboard') {
                  return MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                    settings: RouteSettings(
                      name: '/dashboard',
                      arguments: {'initialTab': tabIndex},
                    ),
                  );
                }
                if (settings.name == '/welcome') {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(body: Text('Welcome')),
                  );
                }
                return null;
              },
            ),
          ),
        );

        await pumpDashboardRoute(tester);

        // Assert: Should remain at 0 for invalid indices
        final bottomNavBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );

        expect(
          bottomNavBar.currentIndex,
          equals(0),
          reason:
              'For invalid initialTab=$tabIndex, currentIndex should remain 0',
        );

        // Clean up
        container.dispose();
        await tester.pumpWidget(Container());
        await pumpDashboardRoute(tester);
      }
    });

    testWidgets('Home Drink Water action opens Health tab and logs a serving', (
      WidgetTester tester,
    ) async {
      final mockUser = User(
        id: 'test-user-dashboard-water',
        email: 'water@example.com',
        fullName: 'Water User',
        createdAt: DateTime.now(),
      );
      TestAuthRepository.setMockUser(mockUser);

      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith((ref) {
            return TestAuthNotifier(AuthState.authenticated(mockUser));
          }),
          profileNotifierProvider.overrideWith(
            (ref, userId) => TestProfileNotifier(userId),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            initialRoute: '/dashboard',
            routes: {
              '/dashboard': (_) => const DashboardScreen(),
              '/welcome': (_) => const Scaffold(body: Text('Welcome')),
            },
          ),
        ),
      );

      await pumpDashboardRoute(tester);
      await _scrollDashboardUntilVisible(tester, 'Drink Water');
      await tester.tap(find.text('Drink Water'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBar.currentIndex, 1);
      expect(find.text('1.8 / 2.0 L'), findsOneWidget);
      expect(
        find.text('Added 250 ml of water to today\'s log.'),
        findsOneWidget,
      );

      container.dispose();
    });

    testWidgets('Home Log Meal action opens Health tab with Add Food dialog', (
      WidgetTester tester,
    ) async {
      final mockUser = User(
        id: 'test-user-dashboard-meal',
        email: 'meal@example.com',
        fullName: 'Meal User',
        createdAt: DateTime.now(),
      );
      TestAuthRepository.setMockUser(mockUser);

      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith((ref) {
            return TestAuthNotifier(AuthState.authenticated(mockUser));
          }),
          profileNotifierProvider.overrideWith(
            (ref, userId) => TestProfileNotifier(userId),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            initialRoute: '/dashboard',
            routes: {
              '/dashboard': (_) => const DashboardScreen(),
              '/welcome': (_) => const Scaffold(body: Text('Welcome')),
            },
          ),
        ),
      );

      await pumpDashboardRoute(tester);
      await _scrollDashboardUntilVisible(tester, 'Log Meal');
      await tester.tap(find.text('Log Meal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBar.currentIndex, 1);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Add Food'),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Food Name'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Calories'), findsOneWidget);

      container.dispose();
    });
  });
}

Future<void> pumpDashboardRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

Future<void> _scrollDashboardUntilVisible(
  WidgetTester tester,
  String label,
) async {
  await tester.scrollUntilVisible(
    find.text(label),
    300,
    scrollable: find
        .descendant(
          of: find.byType(DashboardScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pump();
}

/// Test implementation of AuthNotifier for testing purposes
/// This notifier starts with a pre-set authenticated state and doesn't
/// call the async _init() method that would override it.
class TestAuthNotifier extends AuthNotifier {
  final AuthState _initialState;

  TestAuthNotifier(this._initialState) : super(TestAuthRepository()) {
    // Set the state immediately after construction
    // This happens after the parent constructor but before any async init
    state = _initialState;
  }

  @override
  Future<void> initialize() async {
    // Override to prevent the async _init() from changing our test state
    // Keep the state we set in the constructor
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
