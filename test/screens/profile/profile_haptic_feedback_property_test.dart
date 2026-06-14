import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/screens/profile/profile_screen.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/presentation/notifiers/auth_notifier.dart';
import 'package:flowfit/presentation/notifiers/profile_notifier.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/domain/entities/user.dart';
import 'package:flowfit/domain/entities/auth_state.dart' as domain;
import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Stub providers for sync status (not yet implemented in main code)
final syncStatusProvider = StreamProvider.family<SyncStatus, String>((
  ref,
  userId,
) {
  return Stream.value(SyncStatus.synced);
});

final pendingSyncCountProvider = FutureProvider<int>((ref) async => 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Haptic Feedback - Property Tests', () {
    late List<MethodCall> hapticCalls;

    setUp(() async {
      // Initialize SharedPreferences mock
      SharedPreferences.setMockInitialValues({});

      // Set up method channel mock for HapticFeedback
      hapticCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            MethodCall methodCall,
          ) async {
            if (methodCall.method == 'HapticFeedback.vibrate') {
              hapticCalls.add(methodCall);
            }
            return null;
          });
    });

    /// **Feature: dashboard-refactoring-merge, Property 7: Haptic feedback on photo picker**
    /// **Validates: Requirements 4.2**
    ///
    /// Property: For any photo picker modal open action, the system should
    /// trigger haptic feedback.
    testWidgets(
      'Property 7: For any photo picker open, haptic feedback is triggered',
      (WidgetTester tester) async {
        // Property-based test: Test multiple interactions that open photo picker
        final testScenarios = [
          {'description': 'Tap on profile avatar', 'tapCount': 1},
          {'description': 'Multiple taps on avatar', 'tapCount': 3},
          {'description': 'Single tap interaction', 'tapCount': 1},
        ];

        for (final scenario in testScenarios) {
          final description = scenario['description'] as String;
          final tapCount = scenario['tapCount'] as int;

          // Reset haptic calls for this iteration
          hapticCalls.clear();

          // Create mock user and profile
          final mockUser = User(
            id: 'test-user-123',
            email: 'test@example.com',
            fullName: 'Test User',
            createdAt: DateTime.now(),
          );

          final mockProfile = UserProfile(
            userId: 'test-user-123',
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
          );

          // Arrange: Build ProfileScreen with mocked providers
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authRepositoryProvider.overrideWithValue(MockAuthRepository()),
                authNotifierProvider.overrideWith((ref) {
                  final authRepo = ref.watch(authRepositoryProvider);
                  return AuthNotifier(authRepo)
                    ..state = domain.AuthState.authenticated(mockUser);
                }),
                profileNotifierProvider('test-user-123').overrideWith((ref) {
                  final mockRepo = MockCoreProfileRepository(mockProfile);
                  return ProfileNotifier(mockRepo, 'test-user-123');
                }),
                syncStatusProvider('test-user-123').overrideWith((ref) {
                  return Stream.value(SyncStatus.synced);
                }),
                pendingSyncCountProvider.overrideWith((ref) async => 0),
              ],
              child: const MaterialApp(home: ProfileScreen()),
            ),
          );

          // Wait for profile to load
          await tester.pumpAndSettle();

          // Debug: Print widget tree if avatar not found
          if (find.byType(CircleAvatar).evaluate().isEmpty) {
            debugPrint(
              'Widget tree: ${tester.allWidgets.map((w) => w.runtimeType).toList()}',
            );
          }

          // Act: Tap on profile avatar to open photo picker (multiple times)
          for (int i = 0; i < tapCount; i++) {
            final avatarFinder = find.byType(CircleAvatar);
            expect(avatarFinder, findsWidgets);

            await tester.tap(avatarFinder);
            await tester.pumpAndSettle();

            // Close the modal if it opened
            if (find.text('Change Profile Photo').evaluate().isNotEmpty) {
              await tester.tapAt(const Offset(10, 10)); // Tap outside modal
              await tester.pumpAndSettle();
            }
          }

          // Assert: Haptic feedback should be triggered for each tap
          expect(
            hapticCalls.length,
            equals(tapCount),
            reason:
                'For scenario "$description", haptic feedback should be triggered $tapCount time(s)',
          );

          // Verify the haptic feedback type is lightImpact
          for (final call in hapticCalls) {
            expect(
              call.method,
              equals('HapticFeedback.vibrate'),
              reason: 'Should call HapticFeedback.vibrate method',
            );
            expect(
              call.arguments,
              equals('HapticFeedbackType.lightImpact'),
              reason: 'Should use lightImpact for photo picker',
            );
          }
        }
      },
    );

    /// **Feature: dashboard-refactoring-merge, Property 12: Haptic feedback on edit profile**
    /// **Validates: Requirements 7.1**
    ///
    /// Property: For any edit profile button tap, the system should trigger
    /// haptic feedback.
    testWidgets(
      'Property 12: For any edit profile tap, haptic feedback is triggered',
      (WidgetTester tester) async {
        // Property-based test: Test edit profile interaction triggers haptic feedback
        // Reset haptic calls
        hapticCalls.clear();

        // Create mock user and profile
        final mockUser = User(
          id: 'test-user-123',
          email: 'test@example.com',
          fullName: 'Test User',
          createdAt: DateTime.now(),
        );

        final mockProfile = UserProfile(
          userId: 'test-user-123',
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
        );

        // Arrange: Build ProfileScreen with mocked providers
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(MockAuthRepository()),
              authNotifierProvider.overrideWith((ref) {
                final authRepo = ref.watch(authRepositoryProvider);
                return AuthNotifier(authRepo)
                  ..state = domain.AuthState.authenticated(mockUser);
              }),
              profileNotifierProvider('test-user-123').overrideWith((ref) {
                final mockRepo = MockCoreProfileRepository(mockProfile);
                return ProfileNotifier(mockRepo, 'test-user-123');
              }),
              syncStatusProvider('test-user-123').overrideWith((ref) {
                return Stream.value(SyncStatus.synced);
              }),
              pendingSyncCountProvider.overrideWith((ref) async => 0),
            ],
            child: MaterialApp(
              home: const ProfileScreen(),
              routes: {
                '/survey_basic_info': (context) => const Scaffold(
                  body: Center(child: Text('Survey Basic Info Screen')),
                ),
              },
            ),
          ),
        );

        // Wait for profile to load
        await tester.pumpAndSettle();

        // Act: Tap on edit profile button
        final editButtonFinder = find.byKey(const Key('edit_profile_button'));

        // Should find the edit button
        expect(editButtonFinder, findsOneWidget);

        // Tap the edit button
        await tester.tap(editButtonFinder);
        await tester.pumpAndSettle();

        // Assert: Haptic feedback should be triggered
        expect(
          hapticCalls.length,
          greaterThanOrEqualTo(1),
          reason: 'Haptic feedback should be triggered at least once',
        );

        // Verify the haptic feedback type is mediumImpact
        final mediumImpactCalls = hapticCalls.where(
          (call) =>
              call.method == 'HapticFeedback.vibrate' &&
              call.arguments == 'HapticFeedbackType.mediumImpact',
        );

        expect(
          mediumImpactCalls.length,
          greaterThanOrEqualTo(1),
          reason: 'Should use mediumImpact for edit profile',
        );
      },
    );
  });
}

/// Mock AuthRepository for testing
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
    // Mock sign out
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

/// Mock AuthNotifier for testing
class MockAuthNotifier extends StateNotifier<domain.AuthState> {
  MockAuthNotifier(User user) : super(domain.AuthState.authenticated(user));

  Future<void> signOut() async {
    state = domain.AuthState.unauthenticated();
  }
}

/// Mock ProfileNotifier for testing
class MockProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  MockProfileNotifier(UserProfile profile) : super(AsyncValue.data(profile));

  Future<void> loadProfile() async {
    // Mock load profile
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = AsyncValue.data(profile);
  }
}

/// Mock Core ProfileRepository for testing
class MockCoreProfileRepository implements ProfileRepository {
  MockCoreProfileRepository(this.profile);

  final UserProfile profile;

  @override
  Future<UserProfile?> getLocalProfile(String userId) async => profile;

  @override
  Future<void> saveLocalProfile(UserProfile profile) async {}

  @override
  Future<void> deleteLocalProfile(String userId) async {}

  @override
  Future<UserProfile?> getBackendProfile(String userId) async => profile;

  @override
  Future<void> saveBackendProfile(UserProfile profile) async {}

  @override
  Future<void> syncProfile(String userId) async {}

  @override
  Future<bool> hasPendingSync(String userId) async => false;

  @override
  Stream<SyncStatus> watchSyncStatus(String userId) {
    return Stream.value(SyncStatus.synced);
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async => false;
}
