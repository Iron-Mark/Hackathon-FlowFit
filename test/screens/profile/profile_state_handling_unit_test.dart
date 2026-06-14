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

  group('Profile State Handling - Unit Tests', () {
    setUp(() async {
      // Initialize SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
    });

    /// Test: Loading state displays spinner
    /// Requirements: 10.5
    testWidgets('loading state displays spinner', (WidgetTester tester) async {
      // Arrange: Build ProfileScreen with loading state
      final mockAuthRepo = MockAuthRepository();
      final mockProfileRepo = MockProfileRepository();
      final mockCoreProfileRepo = MockCoreProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifierLoading(mockCoreProfileRepo, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.synced),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      // Act: Wait for widget to build
      await tester.pump();

      // Assert: CircularProgressIndicator should be displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Verify it's centered
      final center = find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(Center),
      );
      expect(center, findsOneWidget);
    });

    /// Test: Error state displays error message with retry button
    /// Requirements: 10.5
    testWidgets('error state displays error message with retry button', (
      WidgetTester tester,
    ) async {
      // Arrange: Build ProfileScreen with error state
      final mockAuthRepo = MockAuthRepository();
      final mockProfileRepo = MockProfileRepository();
      final mockCoreProfileRepo = MockCoreProfileRepository();
      const errorMessage = 'Failed to load profile data';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifierError(
                mockCoreProfileRepo,
                userId,
                errorMessage,
              );
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.synced),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      // Act: Wait for widget to build
      await tester.pumpAndSettle();

      // Assert: Error message should be displayed
      expect(find.text('Failed to load profile'), findsOneWidget);
      expect(find.textContaining(errorMessage), findsOneWidget);

      // Retry button should be present
      expect(find.text('Retry'), findsOneWidget);
    });

    /// Test: Empty state displays onboarding prompt
    /// Requirements: 10.5
    testWidgets('empty state displays onboarding prompt', (
      WidgetTester tester,
    ) async {
      // Arrange: Build ProfileScreen with empty/null profile state
      final mockAuthRepo = MockAuthRepository();
      final mockProfileRepo = MockProfileRepository();
      final mockCoreProfileRepo = MockCoreProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifierEmpty(mockCoreProfileRepo, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.synced),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(
            home: const ProfileScreen(),
            routes: {
              '/survey_intro': (context) => const Scaffold(
                body: Center(child: Text('Survey Intro Screen')),
              ),
            },
          ),
        ),
      );

      // Act: Wait for widget to build
      await tester.pumpAndSettle();

      // Assert: Empty state message should be displayed
      expect(find.text('Complete Your Profile'), findsOneWidget);
      expect(
        find.text(
          'Get started by completing the onboarding survey to set up your profile.',
        ),
        findsOneWidget,
      );

      // Complete Onboarding button should be present
      expect(
        find.widgetWithText(ElevatedButton, 'Complete Onboarding'),
        findsOneWidget,
      );
    });

    /// Test: Empty state button navigates to survey_intro
    /// Requirements: 10.5
    testWidgets('empty state button navigates to survey_intro', (
      WidgetTester tester,
    ) async {
      // Arrange: Build ProfileScreen with empty state
      final mockAuthRepo = MockAuthRepository();
      final mockProfileRepo = MockProfileRepository();
      final mockCoreProfileRepo = MockCoreProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifierEmpty(mockCoreProfileRepo, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.synced),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(
            home: const ProfileScreen(),
            routes: {
              '/survey_intro': (context) => const Scaffold(
                body: Center(child: Text('Survey Intro Screen')),
              ),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act: Tap the Complete Onboarding button
      final onboardingButton = find.widgetWithText(
        ElevatedButton,
        'Complete Onboarding',
      );
      await tester.tap(onboardingButton);
      await tester.pumpAndSettle();

      // Assert: Should navigate to survey_intro screen
      expect(find.text('Survey Intro Screen'), findsOneWidget);
    });

    /// Test: Data state displays profile information
    /// Requirements: 10.4, 10.5
    testWidgets('data state displays profile information', (
      WidgetTester tester,
    ) async {
      // Arrange: Build ProfileScreen with profile data
      final mockAuthRepo = MockAuthRepository();
      final mockProfileRepo = MockProfileRepository();
      final mockCoreProfileRepo = MockCoreProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifierWithData(mockCoreProfileRepo, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.synced),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      // Act: Wait for widget to build
      await tester.pumpAndSettle();

      // Assert: Profile information should be displayed
      expect(find.text('John Doe'), findsOneWidget);
      // Email appears in both header and My Account section
      expect(find.text('test@example.com'), findsWidgets);
      expect(find.textContaining('Age: 30'), findsWidgets);
      expect(find.textContaining('Moderate'), findsWidgets);

      // My Account section should be present
      expect(find.text('My Account'), findsOneWidget);

      // My Goals section should be present
      expect(find.text('My Goals'), findsOneWidget);
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
      fullName: 'John Doe',
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
      fullName: 'John Doe',
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

/// Mock ProfileNotifier with loading state
class MockProfileNotifierLoading extends ProfileNotifier {
  MockProfileNotifierLoading(super.repository, super.userId) {
    // Set loading state immediately in constructor
    state = const AsyncValue.loading();
  }

  @override
  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
  }
}

/// Mock ProfileNotifier with error state
class MockProfileNotifierError extends ProfileNotifier {
  final String errorMessage;

  MockProfileNotifierError(super.repository, super.userId, this.errorMessage) {
    // Set error state immediately in constructor
    state = AsyncValue.error(Exception(errorMessage), StackTrace.current);
  }

  @override
  Future<void> loadProfile() async {
    state = AsyncValue.error(Exception(errorMessage), StackTrace.current);
  }
}

/// Mock ProfileNotifier with empty/null profile
class MockProfileNotifierEmpty extends ProfileNotifier {
  MockProfileNotifierEmpty(super.repository, super.userId) {
    // Set empty state immediately in constructor
    state = const AsyncValue.data(null);
  }

  @override
  Future<void> loadProfile() async {
    state = const AsyncValue.data(null);
  }
}

/// Mock ProfileNotifier with actual data
class MockProfileNotifierWithData extends ProfileNotifier {
  MockProfileNotifierWithData(super.repository, super.userId) {
    // Set data state immediately in constructor
    state = AsyncValue.data(
      core.UserProfile(
        userId: userId,
        fullName: 'John Doe',
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

  @override
  Future<void> loadProfile() async {
    state = AsyncValue.data(
      core.UserProfile(
        userId: userId,
        fullName: 'John Doe',
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
