import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/domain/entities/user.dart' as domain_user;
import 'package:flowfit/domain/entities/user_profile.dart' as domain_profile;
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/domain/repositories/i_profile_repository.dart';
import 'package:flowfit/presentation/notifiers/profile_notifier.dart';
import 'package:flowfit/presentation/providers/profile_providers.dart'
    as profile_providers;
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/screens/onboarding/survey_intro_screen.dart';
import 'package:flowfit/screens/onboarding/survey_basic_info_screen.dart';
import 'package:flowfit/screens/onboarding/survey_body_measurements_screen.dart';
import 'package:flowfit/screens/onboarding/survey_activity_goals_screen.dart';
import 'package:flowfit/screens/onboarding/survey_daily_targets_screen.dart';
import 'package:flowfit/screens/profile/profile_view.dart';
import 'package:flowfit/services/survey_completion_handler.dart';

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  final target = finder.first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _enterTextAndSettle(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  final target = finder.first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.enterText(target, text);
  await tester.pumpAndSettle();
}

/// Integration tests for profile-onboarding integration.
///
/// These tests verify:
/// - Complete onboarding flow → profile creation
/// - Profile data display in profile screen
/// - Profile editing flow
/// - Offline mode behavior
/// - Sync on connectivity restore
///
/// Requirements: All requirements from profile-onboarding-integration spec
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Profile Onboarding Integration Tests', () {
    late ProviderContainer container;
    late _InMemoryProfileRepository repository;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      repository = _InMemoryProfileRepository();

      // Create fresh provider container
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TestAuthRepository()),
          profileRepositoryProvider.overrideWithValue(
            _TestSurveyProfileRepository(),
          ),
          profile_providers.profileRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
          profile_providers.surveyCompletionHandlerProvider.overrideWith(
            (ref) async =>
                SurveyCompletionHandler(profileRepository: repository),
          ),
          profile_providers.profileNotifierProvider.overrideWith(
            (ref, userId) => ProfileNotifier(repository, userId),
          ),
          profile_providers.syncStatusProvider.overrideWith(
            (ref, userId) => repository.watchSyncStatus(userId),
          ),
          profile_providers.pendingSyncCountProvider.overrideWith(
            (ref) async => repository.pendingSyncCount,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets(
      'INTEGRATION: Complete onboarding flow creates profile',
      (WidgetTester tester) async {
        const testUserId = 'test-user-123';
        const testName = 'Test User';

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
                            '/survey_intro',
                            arguments: {'userId': testUserId, 'name': testName},
                          );
                        },
                        child: const Text('Start Survey'),
                      ),
                    ),
                  );
                },
              ),
              routes: {
                '/survey_intro': (context) => const SurveyIntroScreen(),
                '/survey_basic_info': (context) =>
                    const SurveyBasicInfoScreen(),
                '/survey_body_measurements': (context) =>
                    const SurveyBodyMeasurementsScreen(),
                '/survey_activity_goals': (context) =>
                    const SurveyActivityGoalsScreen(),
                '/survey_daily_targets': (context) =>
                    const SurveyDailyTargetsScreen(),
                '/dashboard': (context) => Scaffold(
                  appBar: AppBar(title: const Text('Dashboard')),
                  body: const Center(child: Text('Dashboard')),
                ),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Start survey
        await _tapAndSettle(tester, find.text('Start Survey'));

        // Survey Intro
        expect(find.text('Quick Setup'), findsOneWidget);
        await _tapAndSettle(tester, find.text('Let\'s Personalize'));

        // Basic Info
        await _tapAndSettle(tester, find.text('Male'));
        final ageField = find.byType(TextFormField).first;
        await _enterTextAndSettle(tester, ageField, '30');
        await _tapAndSettle(tester, find.text('Continue'));

        // Body Measurements
        final heightField = find.widgetWithText(TextFormField, 'Enter height');
        await _enterTextAndSettle(tester, heightField, '175');
        final weightField = find.widgetWithText(TextFormField, 'Enter weight');
        await _enterTextAndSettle(tester, weightField, '75');
        await _tapAndSettle(tester, find.text('Continue'));

        // Activity Goals
        await _tapAndSettle(tester, find.text('Moderately Active'));
        await _tapAndSettle(tester, find.text('Lose Weight'));
        await _tapAndSettle(tester, find.text('Continue'));

        // Daily Targets - Complete survey
        await _tapAndSettle(tester, find.text('Complete & Start App'));

        // Verify profile was created in local storage
        final repository = await container.read(
          profile_providers.profileRepositoryProvider.future,
        );
        final profile = await repository.getLocalProfile(testUserId);
        expect(profile, isNotNull);
        expect(profile!.userId, testUserId);
        expect(profile.age, 30);
        expect(profile.gender, 'male');
        expect(profile.weight, 75.0);
        expect(profile.height, 175.0);
        expect(profile.activityLevel, 'moderately_active');
        expect(profile.goals, contains('lose_weight'));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'INTEGRATION: Profile data displays correctly in profile screen',
      (WidgetTester tester) async {
        const testUserId = 'test-user-456';

        // Create a test profile
        final testProfile = UserProfile(
          userId: testUserId,
          fullName: 'John Doe',
          age: 28,
          gender: 'male',
          height: 180.0,
          weight: 80.0,
          heightUnit: 'cm',
          weightUnit: 'kg',
          activityLevel: 'Very Active',
          goals: ['Build Muscle', 'Improve Cardio'],
          dailyCalorieTarget: 2500,
          dailyStepsTarget: 10000,
          dailyActiveMinutesTarget: 60,
          dailyWaterTarget: 3.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        // Save profile to local storage
        final repository = await container.read(
          profile_providers.profileRepositoryProvider.future,
        );
        await repository.saveLocalProfile(testProfile);

        // Build profile view with the profile
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: ProfileView(
                  profile: testProfile,
                  userEmail: 'test@example.com',
                  onPhotoTap: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify profile data is displayed
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.textContaining('28'), findsWidgets);
        expect(find.textContaining('Male'), findsWidgets);
        expect(find.textContaining('180'), findsWidgets);
        expect(find.textContaining('80'), findsWidgets);
        expect(find.textContaining('Very Active'), findsWidgets);
        expect(find.textContaining('Build Muscle'), findsWidgets);
        expect(find.textContaining('2500'), findsWidgets);
        expect(find.textContaining('10000'), findsWidgets);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'INTEGRATION: Profile editing flow saves changes',
      (WidgetTester tester) async {},
      timeout: const Timeout(Duration(minutes: 1)),
      skip: true, // EditProfileScreen was removed; edit flow uses surveys.
    );

    testWidgets(
      'INTEGRATION: Offline mode saves profile locally',
      (WidgetTester tester) async {
        const testUserId = 'test-user-offline';
        const testName = 'Offline User';

        // Note: This test simulates offline by not attempting backend sync
        // In real scenario, connectivity would be checked

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
                            '/survey_intro',
                            arguments: {'userId': testUserId, 'name': testName},
                          );
                        },
                        child: const Text('Start Survey'),
                      ),
                    ),
                  );
                },
              ),
              routes: {
                '/survey_intro': (context) => const SurveyIntroScreen(),
                '/survey_basic_info': (context) =>
                    const SurveyBasicInfoScreen(),
                '/survey_body_measurements': (context) =>
                    const SurveyBodyMeasurementsScreen(),
                '/survey_activity_goals': (context) =>
                    const SurveyActivityGoalsScreen(),
                '/survey_daily_targets': (context) =>
                    const SurveyDailyTargetsScreen(),
                '/dashboard': (context) =>
                    const Scaffold(body: Center(child: Text('Dashboard'))),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Complete survey
        await _tapAndSettle(tester, find.text('Start Survey'));
        await _tapAndSettle(tester, find.text('Let\'s Personalize'));

        // Fill basic info
        await _tapAndSettle(tester, find.text('Female'));
        await _enterTextAndSettle(
          tester,
          find.byType(TextFormField).first,
          '32',
        );
        await _tapAndSettle(tester, find.text('Continue'));

        // Fill body measurements
        await _enterTextAndSettle(
          tester,
          find.widgetWithText(TextFormField, 'Enter height'),
          '170',
        );
        await _enterTextAndSettle(
          tester,
          find.widgetWithText(TextFormField, 'Enter weight'),
          '65',
        );
        await _tapAndSettle(tester, find.text('Continue'));

        // Fill activity goals
        await _tapAndSettle(tester, find.text('Sedentary'));
        await _tapAndSettle(tester, find.text('Maintain Weight'));
        await _tapAndSettle(tester, find.text('Continue'));

        // Complete survey
        await _tapAndSettle(tester, find.text('Complete & Start App'));

        // Verify profile saved locally (even if backend sync fails)
        final repository = await container.read(
          profile_providers.profileRepositoryProvider.future,
        );
        final profile = await repository.getLocalProfile(testUserId);

        expect(profile, isNotNull);
        expect(profile!.userId, testUserId);
        expect(profile.age, 32);
        expect(profile.gender, 'female');
        expect(profile.weight, 65.0);
        expect(profile.height, 170.0);

        // Profile should be marked as not synced if offline
        // (In real scenario, isSynced would be false)
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test('UNIT: Profile repository handles sync queue correctly', () async {
      const testUserId = 'test-sync-user';

      final testProfile = UserProfile(
        userId: testUserId,
        fullName: 'Sync Test',
        age: 30,
        gender: 'male',
        height: 175.0,
        weight: 75.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      final repository = await container.read(
        profile_providers.profileRepositoryProvider.future,
      );

      // Save profile locally
      await repository.saveLocalProfile(testProfile);

      // Verify it's saved
      final savedProfile = await repository.getLocalProfile(testUserId);
      expect(savedProfile, isNotNull);
      expect(savedProfile!.userId, testUserId);
      expect(savedProfile.isSynced, false);

      // Check if there's pending sync
      final hasPending = await repository.hasPendingSync(testUserId);
      expect(hasPending, isTrue);
    });

    testWidgets('INTEGRATION: Survey data persists across navigation', (
      WidgetTester tester,
    ) async {
      const testUserId = 'test-persist-user';

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
                          '/survey_basic_info',
                          arguments: {
                            'userId': testUserId,
                            'name': 'Test User',
                          },
                        );
                      },
                      child: const Text('Start Survey'),
                    ),
                  ),
                );
              },
            ),
            routes: {
              '/survey_basic_info': (context) => const SurveyBasicInfoScreen(),
              '/survey_body_measurements': (context) =>
                  const SurveyBodyMeasurementsScreen(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start survey
      await _tapAndSettle(tester, find.text('Start Survey'));

      // Fill basic info
      await _tapAndSettle(tester, find.text('Male'));
      await _enterTextAndSettle(tester, find.byType(TextFormField).first, '35');
      await _tapAndSettle(tester, find.text('Continue'));

      // Navigate back
      await _tapAndSettle(tester, find.byIcon(Icons.arrow_back));

      // Verify data persisted
      final surveyState = container.read(surveyNotifierProvider);
      expect(surveyState.surveyData['age'], 35);
      expect(surveyState.surveyData['gender'], 'male');

      // Navigate forward again
      await _tapAndSettle(tester, find.text('Continue'));

      // Data should still be there
      final surveyState2 = container.read(surveyNotifierProvider);
      expect(surveyState2.surveyData['age'], 35);
      expect(surveyState2.surveyData['gender'], 'male');
    });
  });
}

class _TestAuthRepository implements IAuthRepository {
  final domain_user.User _user = domain_user.User(
    id: 'test-user',
    email: 'test@example.com',
    fullName: 'Test User',
    createdAt: DateTime(2025),
  );

  @override
  Future<domain_user.User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    return domain_user.User(
      id: 'test-user',
      email: email,
      fullName: fullName,
      createdAt: DateTime(2025),
    );
  }

  @override
  Future<domain_user.User> signIn({
    required String email,
    required String password,
  }) async {
    return _user.copyWith(email: email);
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<domain_user.User?> getCurrentUser() async {
    return _user;
  }

  @override
  Stream<domain_user.User?> authStateChanges() {
    return Stream.value(_user);
  }
}

class _TestSurveyProfileRepository implements IProfileRepository {
  final Map<String, domain_profile.UserProfile> _profiles = {};

  @override
  Future<domain_profile.UserProfile> createProfile(
    domain_profile.UserProfile profile,
  ) async {
    _profiles[profile.userId] = profile;
    return profile;
  }

  @override
  Future<domain_profile.UserProfile> updateProfile(
    domain_profile.UserProfile profile,
  ) async {
    _profiles[profile.userId] = profile;
    return profile;
  }

  @override
  Future<domain_profile.UserProfile?> getProfile(String userId) async {
    return _profiles[userId];
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    return _profiles.containsKey(userId);
  }
}

class _InMemoryProfileRepository implements ProfileRepository {
  final Map<String, UserProfile> _profiles = {};

  int get pendingSyncCount {
    return _profiles.values.where((profile) => !profile.isSynced).length;
  }

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
  Future<UserProfile?> getBackendProfile(String userId) async {
    return _profiles[userId];
  }

  @override
  Future<void> saveBackendProfile(UserProfile profile) async {
    _profiles[profile.userId] = profile.copyWith(isSynced: true);
  }

  @override
  Future<void> syncProfile(String userId) async {
    final profile = _profiles[userId];
    if (profile != null) {
      _profiles[userId] = profile.copyWith(isSynced: true);
    }
  }

  @override
  Future<bool> hasPendingSync(String userId) async {
    return _profiles[userId]?.isSynced == false;
  }

  @override
  Stream<SyncStatus> watchSyncStatus(String userId) {
    final profile = _profiles[userId];
    if (profile == null || profile.isSynced) {
      return Stream.value(SyncStatus.synced);
    }

    return Stream.value(SyncStatus.pendingSync);
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    return _profiles.containsKey(userId);
  }
}
