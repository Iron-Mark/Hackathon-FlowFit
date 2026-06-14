import 'package:flowfit/core/domain/entities/user_profile.dart' as core_profile;
import 'package:flowfit/core/domain/repositories/profile_repository.dart'
    as core_profile_repo;
import 'package:flowfit/domain/entities/user.dart' as domain_user;
import 'package:flowfit/domain/entities/user_profile.dart' as domain_profile;
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/domain/repositories/i_profile_repository.dart';
import 'package:flowfit/presentation/notifiers/profile_notifier.dart';
import 'package:flowfit/presentation/providers/profile_providers.dart'
    as profile_providers;
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/screens/onboarding/survey_activity_goals_screen.dart';
import 'package:flowfit/screens/onboarding/survey_basic_info_screen.dart';
import 'package:flowfit/screens/onboarding/survey_body_measurements_screen.dart';
import 'package:flowfit/screens/onboarding/survey_daily_targets_screen.dart';
import 'package:flowfit/screens/onboarding/survey_intro_screen.dart';
import 'package:flowfit/services/survey_completion_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Survey Back Button Navigation Tests', () {
    late ProviderContainer container;
    late _InMemoryProfileRepository coreRepository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      coreRepository = _InMemoryProfileRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          profileRepositoryProvider.overrideWithValue(
            _FakeSurveyProfileRepository(),
          ),
          profile_providers.profileRepositoryProvider.overrideWith(
            (ref) async => coreRepository,
          ),
          profile_providers.surveyCompletionHandlerProvider.overrideWith(
            (ref) async =>
                SurveyCompletionHandler(profileRepository: coreRepository),
          ),
          profile_providers.profileNotifierProvider.overrideWith(
            (ref, userId) => ProfileNotifier(coreRepository, userId),
          ),
          profile_providers.syncStatusProvider.overrideWith(
            (ref, userId) => coreRepository.watchSyncStatus(userId),
          ),
          profile_providers.pendingSyncCountProvider.overrideWith(
            (ref) async => coreRepository.pendingSyncCount,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Back button navigates from Basic Info to Survey Intro', (
      tester,
    ) async {
      await _pumpSurveyHarness(
        tester,
        container,
        initialRoute: '/survey_intro',
      );

      await _tapAndSettle(tester, find.text('Start Survey'));
      expect(find.text('Quick Setup'), findsOneWidget);

      await _tapAndSettle(tester, find.text('Let\'s Personalize'));
      expect(find.text('Tell us about yourself'), findsOneWidget);

      await _tapAndSettle(tester, find.byIcon(Icons.arrow_back));
      expect(find.text('Quick Setup'), findsOneWidget);
      expect(find.text('2 Minutes'), findsOneWidget);
    });

    testWidgets(
      'Data is preserved when navigating back from Body Measurements',
      (tester) async {
        await _pumpSurveyHarness(
          tester,
          container,
          initialRoute: '/survey_basic_info',
        );

        await _tapAndSettle(tester, find.text('Start Survey'));
        await _tapAndSettle(tester, find.text('Male'));
        await _enterTextAndSettle(
          tester,
          find.byType(TextFormField).first,
          '30',
        );
        await _tapAndSettle(tester, find.text('Continue'));

        expect(find.text('Your measurements'), findsOneWidget);

        await _tapAndSettle(tester, find.byIcon(Icons.arrow_back));
        expect(find.text('Tell us about yourself'), findsOneWidget);

        final surveyState = container.read(surveyNotifierProvider);
        expect(surveyState.surveyData['age'], 30);
        expect(surveyState.surveyData['gender'], 'male');
      },
    );

    testWidgets('Back button works through all survey steps', (tester) async {
      await _pumpSurveyHarness(
        tester,
        container,
        initialRoute: '/survey_intro',
      );

      await _tapAndSettle(tester, find.text('Start Survey'));
      expect(find.text('Quick Setup'), findsOneWidget);

      await _tapAndSettle(tester, find.text('Let\'s Personalize'));
      expect(find.text('Tell us about yourself'), findsOneWidget);

      await _tapAndSettle(tester, find.text('Male'));
      await _enterTextAndSettle(tester, find.byType(TextFormField).first, '30');
      await _tapAndSettle(tester, find.text('Continue'));

      expect(find.text('Your measurements'), findsOneWidget);
      await _enterTextAndSettle(
        tester,
        find.widgetWithText(TextFormField, 'Enter height'),
        '175',
      );
      await _enterTextAndSettle(
        tester,
        find.widgetWithText(TextFormField, 'Enter weight'),
        '75',
      );
      await _tapAndSettle(tester, find.text('Continue'));

      expect(find.text('Activity & Goals'), findsOneWidget);
      await _tapAndSettle(tester, find.text('Moderately Active'));
      await _tapAndSettle(tester, find.text('Lose Weight'));
      await _tapAndSettle(tester, find.text('Continue'));

      expect(find.text('Your Daily Targets'), findsOneWidget);

      await _tapAndSettle(tester, find.byIcon(Icons.arrow_back));
      expect(find.text('Activity & Goals'), findsOneWidget);

      await _tapAndSettle(tester, find.byIcon(Icons.arrow_back));
      expect(find.text('Your measurements'), findsOneWidget);

      await _tapAndSettle(tester, find.byIcon(Icons.arrow_back));
      expect(find.text('Tell us about yourself'), findsOneWidget);

      await _tapAndSettle(tester, find.byIcon(Icons.arrow_back));
      expect(find.text('Quick Setup'), findsOneWidget);

      final surveyState = container.read(surveyNotifierProvider);
      expect(surveyState.surveyData['age'], 30);
      expect(surveyState.surveyData['gender'], 'male');
      expect(surveyState.surveyData['weight'], 75.0);
      expect(surveyState.surveyData['height'], 175.0);
    });

    testWidgets('Forward and backward navigation preserves saved data', (
      tester,
    ) async {
      await _pumpSurveyHarness(
        tester,
        container,
        initialRoute: '/survey_basic_info',
      );

      await _tapAndSettle(tester, find.text('Start Survey'));
      await _tapAndSettle(tester, find.text('Female'));
      await _enterTextAndSettle(tester, find.byType(TextFormField).first, '25');
      await _tapAndSettle(tester, find.text('Continue'));

      await _enterTextAndSettle(
        tester,
        find.widgetWithText(TextFormField, 'Enter height'),
        '165',
      );
      await _enterTextAndSettle(
        tester,
        find.widgetWithText(TextFormField, 'Enter weight'),
        '60',
      );
      await _tapAndSettle(tester, find.text('Continue'));

      expect(find.text('Activity & Goals'), findsOneWidget);

      await _tapAndSettle(tester, find.byIcon(Icons.arrow_back));
      expect(find.text('Your measurements'), findsOneWidget);

      await _tapAndSettle(tester, find.byIcon(Icons.arrow_back));
      expect(find.text('Tell us about yourself'), findsOneWidget);

      var surveyState = container.read(surveyNotifierProvider);
      expect(surveyState.surveyData['age'], 25);
      expect(surveyState.surveyData['gender'], 'female');
      expect(surveyState.surveyData['weight'], 60.0);
      expect(surveyState.surveyData['height'], 165.0);

      await _tapAndSettle(tester, find.text('Continue'));
      expect(find.text('Your measurements'), findsOneWidget);

      surveyState = container.read(surveyNotifierProvider);
      expect(surveyState.surveyData['age'], 25);
      expect(surveyState.surveyData['gender'], 'female');
      expect(surveyState.surveyData['weight'], 60.0);
      expect(surveyState.surveyData['height'], 165.0);
    });

    testWidgets('No black screen appears when using back button', (
      tester,
    ) async {
      await _pumpSurveyHarness(
        tester,
        container,
        initialRoute: '/survey_basic_info',
      );

      await _tapAndSettle(tester, find.text('Start Survey'));
      await _tapAndSettle(tester, find.text('Male'));
      await _enterTextAndSettle(tester, find.byType(TextFormField).first, '30');
      await _tapAndSettle(tester, find.text('Continue'));

      expect(find.text('Your measurements'), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);

      await _tapAndSettle(tester, find.byIcon(Icons.arrow_back));

      expect(find.text('Tell us about yourself'), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpSurveyHarness(
  WidgetTester tester,
  ProviderContainer container, {
  required String initialRoute,
}) async {
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
                      initialRoute,
                      arguments: const {
                        'userId': 'test-user-id',
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
          '/survey_intro': (context) => const SurveyIntroScreen(),
          '/survey_basic_info': (context) => const SurveyBasicInfoScreen(),
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
}

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

class _FakeAuthRepository implements IAuthRepository {
  final domain_user.User _user = domain_user.User(
    id: 'test-user-id',
    email: 'test@example.com',
    fullName: 'Test User',
    createdAt: DateTime(2025),
    emailConfirmedAt: DateTime(2025),
  );

  @override
  Future<domain_user.User?> getCurrentUser() async => _user;

  @override
  Stream<domain_user.User?> authStateChanges() => Stream.value(_user);

  @override
  Future<void> signOut() async {}

  @override
  Future<domain_user.User> signIn({
    required String email,
    required String password,
  }) async {
    return _user.copyWith(email: email);
  }

  @override
  Future<domain_user.User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    return _user.copyWith(email: email, fullName: fullName);
  }
}

class _FakeSurveyProfileRepository implements IProfileRepository {
  final Map<String, domain_profile.UserProfile> _profiles = {};

  @override
  Future<domain_profile.UserProfile> createProfile(
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

  @override
  Future<domain_profile.UserProfile> updateProfile(
    domain_profile.UserProfile profile,
  ) async {
    _profiles[profile.userId] = profile;
    return profile;
  }
}

class _InMemoryProfileRepository
    implements core_profile_repo.ProfileRepository {
  final Map<String, core_profile.UserProfile> _profiles = {};

  int get pendingSyncCount {
    return _profiles.values.where((profile) => !profile.isSynced).length;
  }

  @override
  Future<void> deleteLocalProfile(String userId) async {
    _profiles.remove(userId);
  }

  @override
  Future<core_profile.UserProfile?> getBackendProfile(String userId) async {
    return _profiles[userId];
  }

  @override
  Future<core_profile.UserProfile?> getLocalProfile(String userId) async {
    return _profiles[userId];
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    return _profiles.containsKey(userId);
  }

  @override
  Future<bool> hasPendingSync(String userId) async {
    return _profiles[userId]?.isSynced == false;
  }

  @override
  Future<void> saveBackendProfile(core_profile.UserProfile profile) async {
    _profiles[profile.userId] = profile.copyWith(isSynced: true);
  }

  @override
  Future<void> saveLocalProfile(core_profile.UserProfile profile) async {
    _profiles[profile.userId] = profile;
  }

  @override
  Future<void> syncProfile(String userId) async {
    final profile = _profiles[userId];
    if (profile != null) {
      _profiles[userId] = profile.copyWith(isSynced: true);
    }
  }

  @override
  Stream<core_profile_repo.SyncStatus> watchSyncStatus(String userId) {
    final profile = _profiles[userId];
    if (profile == null || profile.isSynced) {
      return Stream.value(core_profile_repo.SyncStatus.synced);
    }

    return Stream.value(core_profile_repo.SyncStatus.pendingSync);
  }
}
