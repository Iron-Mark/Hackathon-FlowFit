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

  group('Profile Logout - Property Tests', () {
    setUp(() async {
      // Initialize SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
    });

    /// **Feature: dashboard-refactoring-merge, Property 13: Logout confirmation triggers signOut**
    /// **Validates: Requirements 8.2**
    ///
    /// Property: For any confirmed logout action, the authentication service
    /// signOut method should be called.
    testWidgets('Property 13: For any confirmed logout, signOut is called', (
      WidgetTester tester,
    ) async {
      // Create a mock auth repository that tracks signOut calls
      final mockAuthRepo = MockAuthRepositoryWithTracking();
      final mockProfileRepo = MockProfileRepository();
      final mockCoreProfileRepo = MockCoreProfileRepository();

      // Arrange: Build ProfileScreen with mock auth repository
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
      expect(logoutText, findsOneWidget, reason: 'Logout button should exist');

      // Ensure the widget is visible by scrolling
      await tester.ensureVisible(logoutText);
      await tester.pumpAndSettle();

      // Act: Tap the logout list item
      await tester.tap(logoutText, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(
        find.text('Are you sure you want to logout?'),
        findsOneWidget,
        reason: 'Confirmation dialog should appear',
      );

      // Find and tap the "Logout" button in the dialog (red button)
      final confirmButtonFinder = find.widgetWithText(TextButton, 'Logout');
      expect(
        confirmButtonFinder,
        findsOneWidget,
        reason: 'Logout confirmation button should exist',
      );

      await tester.tap(confirmButtonFinder);
      await tester.pumpAndSettle();

      // Wait for navigation to complete
      await tester.pumpAndSettle();

      // Assert: signOut should be called exactly once
      expect(
        mockAuthRepo.signOutCallCount,
        equals(1),
        reason: 'signOut should be called when logout is confirmed',
      );

      // Verify navigation to welcome screen occurred
      expect(
        find.text('Welcome Screen'),
        findsOneWidget,
        reason: 'Should navigate to welcome screen after logout',
      );
    });

    /// Property: For any cancelled logout action, the signOut method should
    /// NOT be called.
    testWidgets(
      'Property 13 (inverse): For any cancelled logout, signOut is NOT called',
      (WidgetTester tester) async {
        // Create a mock auth repository that tracks signOut calls
        final mockAuthRepo = MockAuthRepositoryWithTracking();
        final mockProfileRepo = MockProfileRepository();
        final mockCoreProfileRepo = MockCoreProfileRepository();

        // Arrange: Build ProfileScreen with mock auth repository
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
        expect(
          logoutText,
          findsOneWidget,
          reason: 'Logout button should exist',
        );

        // Ensure the widget is visible by scrolling
        await tester.ensureVisible(logoutText);
        await tester.pumpAndSettle();

        // Act: Tap the logout list item
        await tester.tap(logoutText, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Verify confirmation dialog appears
        expect(
          find.text('Are you sure you want to logout?'),
          findsOneWidget,
          reason: 'Confirmation dialog should appear',
        );

        // Find and tap the "Cancel" button in the dialog
        final cancelButtonFinder = find.widgetWithText(TextButton, 'Cancel');
        expect(
          cancelButtonFinder,
          findsOneWidget,
          reason: 'Cancel button should exist',
        );

        await tester.tap(cancelButtonFinder);
        await tester.pumpAndSettle();

        // Assert: signOut should NOT be called when cancelled
        expect(
          mockAuthRepo.signOutCallCount,
          equals(0),
          reason: 'signOut should NOT be called when logout is cancelled',
        );

        // Verify we're still on the profile screen
        expect(
          find.text('Logout'),
          findsOneWidget,
          reason: 'Should remain on profile screen after cancelling',
        );
      },
    );
  });
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
    // Track the signOut call
    signOutCallCount++;
    // Mock sign out - no actual operation needed
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
    // Mock auth state changes stream
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
