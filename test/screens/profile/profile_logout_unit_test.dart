import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/screens/profile/profile_screen.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/presentation/notifiers/profile_notifier.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/core/domain/entities/user_profile.dart' as core;
import 'package:flowfit/domain/entities/user_profile.dart' as domain;
import 'package:flowfit/domain/repositories/i_profile_repository.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Logout - Unit Tests', () {
    setUp(() async {
      // Initialize SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
    });

    /// Test: Confirmation dialog appears when logout is tapped
    /// Requirements: 8.1
    testWidgets('confirmation dialog appears when logout is tapped', (
      WidgetTester tester,
    ) async {
      // Arrange: Build ProfileScreen with mock auth repository
      final mockAuthRepo = MockAuthRepository();
      final mockProfileRepo = MockProfileRepository();
      final mockCoreProfileRepo = MockCoreProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifier(mockCoreProfileRepo, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.synced),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(
            home: const ProfileScreen(),
            routes: {
              '/welcome': (context) =>
                  const Scaffold(body: Center(child: Text('Welcome Screen'))),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the logout text
      final logoutText = find.text('Logout');
      expect(logoutText, findsOneWidget);

      // Ensure the widget is visible by scrolling
      await tester.ensureVisible(logoutText);
      await tester.pumpAndSettle();

      // Act: Tap the logout list item
      await tester.tap(logoutText, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Assert: Confirmation dialog should appear
      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Logout'), findsOneWidget);

      // Verify the dialog has the correct structure
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    /// Test: Cancel button closes dialog without signing out
    /// Requirements: 8.3
    testWidgets('cancel button closes dialog without signing out', (
      WidgetTester tester,
    ) async {
      // Arrange: Build ProfileScreen with mock auth repository
      final mockAuthRepo = MockAuthRepositoryWithTracking();
      final mockProfileRepo = MockProfileRepository();
      final mockCoreProfileRepo = MockCoreProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifier(mockCoreProfileRepo, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.synced),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(
            home: const ProfileScreen(),
            routes: {
              '/welcome': (context) =>
                  const Scaffold(body: Center(child: Text('Welcome Screen'))),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap logout
      final logoutText = find.text('Logout');
      await tester.ensureVisible(logoutText);
      await tester.pumpAndSettle();
      await tester.tap(logoutText, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);

      // Act: Tap the Cancel button
      final cancelButton = find.widgetWithText(TextButton, 'Cancel');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Assert: Dialog should be closed
      expect(find.byType(AlertDialog), findsNothing);

      // signOut should NOT have been called
      expect(mockAuthRepo.signOutCallCount, equals(0));

      // Should still be on profile screen
      expect(find.text('Profile'), findsOneWidget);
    });

    /// Test: Confirm button triggers signOut
    /// Requirements: 8.2
    testWidgets('confirm button triggers signOut', (WidgetTester tester) async {
      // Arrange: Build ProfileScreen with tracking mock
      final mockAuthRepo = MockAuthRepositoryWithTracking();
      final mockProfileRepo = MockProfileRepository();
      final mockCoreProfileRepo = MockCoreProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifier(mockCoreProfileRepo, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.synced),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(
            home: const ProfileScreen(),
            routes: {
              '/welcome': (context) =>
                  const Scaffold(body: Center(child: Text('Welcome Screen'))),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap logout
      final logoutText = find.text('Logout');
      await tester.ensureVisible(logoutText);
      await tester.pumpAndSettle();
      await tester.tap(logoutText, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Act: Tap the Logout confirmation button
      final confirmButton = find.widgetWithText(TextButton, 'Logout');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Assert: signOut should have been called
      expect(mockAuthRepo.signOutCallCount, equals(1));
    });

    /// Test: Navigation occurs on successful logout
    /// Requirements: 8.3
    testWidgets('navigation to welcome screen occurs on success', (
      WidgetTester tester,
    ) async {
      // Arrange: Build ProfileScreen with mock auth repository
      final mockAuthRepo = MockAuthRepository();
      final mockProfileRepo = MockProfileRepository();
      final mockCoreProfileRepo = MockCoreProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifier(mockCoreProfileRepo, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.synced),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(
            home: const ProfileScreen(),
            routes: {
              '/welcome': (context) =>
                  const Scaffold(body: Center(child: Text('Welcome Screen'))),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap logout
      final logoutText = find.text('Logout');
      await tester.ensureVisible(logoutText);
      await tester.pumpAndSettle();
      await tester.tap(logoutText, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Act: Confirm logout
      final confirmButton = find.widgetWithText(TextButton, 'Logout');
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Assert: Should navigate to welcome screen
      expect(find.text('Welcome Screen'), findsOneWidget);

      // Should not be able to go back (navigation stack cleared)
      expect(find.text('Profile'), findsNothing);
    });

    /// Test: Error handling keeps the user on Profile when signOut fails.
    /// Requirements: 8.4, 8.5
    testWidgets('logout failure shows an error and does not navigate', (
      WidgetTester tester,
    ) async {
      // Arrange: Build ProfileScreen with mock auth repository
      final mockAuthRepo = MockAuthRepositoryWithError();
      final mockProfileRepo = MockProfileRepository();
      final mockCoreProfileRepo = MockCoreProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifier(mockCoreProfileRepo, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.synced),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(
            home: const ProfileScreen(),
            routes: {
              '/welcome': (context) =>
                  const Scaffold(body: Center(child: Text('Welcome Screen'))),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap logout
      final logoutText = find.text('Logout');
      await tester.ensureVisible(logoutText);
      await tester.pumpAndSettle();
      await tester.tap(logoutText, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Act: Confirm logout
      final confirmButton = find.widgetWithText(TextButton, 'Logout');
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Assert: The app should not navigate as if logout succeeded.
      expect(find.text('Welcome Screen'), findsNothing);
      expect(find.text('Profile'), findsOneWidget);
      expect(
        find.text('Could not sign out. Check your connection and try again.'),
        findsOneWidget,
      );
    });

    /// Test: Logout button has red styling
    /// Requirements: 8.1
    testWidgets('logout button in dialog has red styling', (
      WidgetTester tester,
    ) async {
      // Arrange: Build ProfileScreen
      final mockAuthRepo = MockAuthRepository();
      final mockProfileRepo = MockProfileRepository();
      final mockCoreProfileRepo = MockCoreProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifier(mockCoreProfileRepo, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.synced),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(
            home: const ProfileScreen(),
            routes: {
              '/welcome': (context) =>
                  const Scaffold(body: Center(child: Text('Welcome Screen'))),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap logout
      final logoutText = find.text('Logout');
      await tester.ensureVisible(logoutText);
      await tester.pumpAndSettle();
      await tester.tap(logoutText, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Assert: Find the logout button in the dialog
      final logoutButton = find.widgetWithText(TextButton, 'Logout');
      expect(logoutButton, findsOneWidget);

      // Verify it has red styling
      final textButton = tester.widget<TextButton>(logoutButton);
      expect(
        textButton.style?.foregroundColor?.resolve({}),
        equals(Colors.red),
      );
    });
  });
}

/// Mock AuthRepository for basic testing
class MockAuthRepository implements IAuthRepository {
  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    return User(
      id: 'test-user-123',
      email: email,
      fullName: fullName,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    return User(
      id: 'test-user-123',
      email: email,
      fullName: 'Test User',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> signOut() async {
    // Mock successful sign out
  }

  @override
  Future<User?> getCurrentUser() async {
    return User(
      id: 'test-user-123',
      email: 'test@example.com',
      fullName: 'Test User',
      createdAt: DateTime.now(),
    );
  }

  @override
  Stream<User?> authStateChanges() {
    return Stream.value(
      User(
        id: 'test-user-123',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
      ),
    );
  }
}

/// Mock AuthRepository that tracks signOut calls
class MockAuthRepositoryWithTracking implements IAuthRepository {
  int signOutCallCount = 0;

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    return User(
      id: 'test-user-123',
      email: email,
      fullName: fullName,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    return User(
      id: 'test-user-123',
      email: email,
      fullName: 'Test User',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
  }

  @override
  Future<User?> getCurrentUser() async {
    return User(
      id: 'test-user-123',
      email: 'test@example.com',
      fullName: 'Test User',
      createdAt: DateTime.now(),
    );
  }

  @override
  Stream<User?> authStateChanges() {
    return Stream.value(
      User(
        id: 'test-user-123',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
      ),
    );
  }
}

/// Mock AuthRepository that throws an error on signOut
class MockAuthRepositoryWithError implements IAuthRepository {
  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    return User(
      id: 'test-user-123',
      email: email,
      fullName: fullName,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    return User(
      id: 'test-user-123',
      email: email,
      fullName: 'Test User',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> signOut() async {
    throw Exception('Network error');
  }

  @override
  Future<User?> getCurrentUser() async {
    return User(
      id: 'test-user-123',
      email: 'test@example.com',
      fullName: 'Test User',
      createdAt: DateTime.now(),
    );
  }

  @override
  Stream<User?> authStateChanges() {
    return Stream.value(
      User(
        id: 'test-user-123',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
      ),
    );
  }
}

/// Mock ProfileRepository for IProfileRepository interface
class MockProfileRepository implements IProfileRepository {
  @override
  Future<domain.UserProfile> createProfile(domain.UserProfile profile) async {
    return profile;
  }

  @override
  Future<domain.UserProfile> updateProfile(domain.UserProfile profile) async {
    return profile;
  }

  @override
  Future<domain.UserProfile?> getProfile(String userId) async {
    return domain.UserProfile(
      userId: userId,
      fullName: 'Test User',
      age: 30,
      gender: 'Male',
      weight: 70.0,
      weightUnit: 'kg',
      height: 175.0,
      heightUnit: 'cm',
      activityLevel: 'Moderate',
      goals: ['Fitness'],
      dailyCalorieTarget: 2000,
      surveyCompleted: true,
    );
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    return true;
  }
}

/// Mock ProfileRepository for ProfileRepository (core domain)
class MockCoreProfileRepository implements ProfileRepository {
  final SyncStatus syncStatus;

  MockCoreProfileRepository({this.syncStatus = SyncStatus.synced});

  @override
  Future<core.UserProfile?> getLocalProfile(String userId) async {
    return core.UserProfile(
      userId: userId,
      fullName: 'Test User',
      age: 30,
      gender: 'Male',
      weight: 70.0,
      weightUnit: 'kg',
      height: 175.0,
      heightUnit: 'cm',
      activityLevel: 'Moderate',
      goals: ['Fitness'],
      dailyCalorieTarget: 2000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: true,
    );
  }

  @override
  Future<void> saveLocalProfile(core.UserProfile profile) async {
    // Mock save
  }

  @override
  Future<void> deleteLocalProfile(String userId) async {
    // Mock delete
  }

  @override
  Future<core.UserProfile?> getBackendProfile(String userId) async {
    return getLocalProfile(userId);
  }

  @override
  Future<void> saveBackendProfile(core.UserProfile profile) async {
    // Mock save
  }

  @override
  Future<void> syncProfile(String userId) async {
    // Mock sync
  }

  @override
  Future<bool> hasPendingSync(String userId) async {
    return false;
  }

  @override
  Stream<SyncStatus> watchSyncStatus(String userId) {
    return Stream.value(syncStatus);
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    return true;
  }
}

/// Mock ProfileNotifier
class MockProfileNotifier extends ProfileNotifier {
  MockProfileNotifier(super.repository, super.userId);

  @override
  Future<void> loadProfile() async {
    state = AsyncValue.data(
      core.UserProfile(
        userId: userId,
        fullName: 'Test User',
        age: 30,
        gender: 'Male',
        weight: 70.0,
        weightUnit: 'kg',
        height: 175.0,
        heightUnit: 'cm',
        activityLevel: 'Moderate',
        goals: ['Fitness'],
        dailyCalorieTarget: 2000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: true,
      ),
    );
  }
}
