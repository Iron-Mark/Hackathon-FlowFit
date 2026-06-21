import 'dart:async';

import 'package:flowfit/core/domain/entities/user_profile.dart' as core_profile;
import 'package:flowfit/core/domain/repositories/profile_repository.dart'
    as core_profile_repo;
import 'package:flowfit/domain/entities/user_profile.dart';
import 'package:flowfit/domain/repositories/i_profile_repository.dart';
import 'package:flowfit/presentation/notifiers/profile_notifier.dart';
import 'package:flowfit/presentation/providers/profile_providers.dart'
    as profile_providers;
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/screens/onboarding/survey_activity_goals_screen.dart';
import 'package:flowfit/screens/onboarding/survey_body_measurements_screen.dart';
import 'package:flowfit/screens/onboarding/survey_daily_targets_screen.dart';
import 'package:flowfit/services/survey_completion_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('body measurements validates inputs and saves selected units', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pumpBodyMeasurements(tester, container);

    var continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNull);

    await _enterText(
      tester,
      find.widgetWithText(TextFormField, 'Enter height'),
      '-1',
    );
    await _enterText(
      tester,
      find.widgetWithText(TextFormField, 'Enter weight'),
      '70',
    );

    continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNotNull);

    await _tap(tester, find.widgetWithText(ElevatedButton, 'Continue'));
    expect(find.text('Enter a valid height'), findsOneWidget);
    expect(find.text('route:activity-goals'), findsNothing);

    await _tap(tester, find.text('ft'));
    await _enterText(
      tester,
      find.widgetWithText(TextFormField, 'Enter height'),
      '5.13',
    );
    await _tap(tester, find.widgetWithText(ElevatedButton, 'Continue'));
    expect(find.text('Enter inches from 0 to 11'), findsOneWidget);
    expect(find.text('route:activity-goals'), findsNothing);

    await _enterText(
      tester,
      find.widgetWithText(TextFormField, 'Enter height'),
      '5.8',
    );
    await _tap(tester, find.text('ft'));
    await _tap(tester, find.text('lbs'));
    await _tap(tester, find.widgetWithText(ElevatedButton, 'Continue'));

    expect(find.text('route:activity-goals'), findsOneWidget);
    expect(container.read(surveyNotifierProvider).surveyData, {
      'height': 68.0,
      'heightInput': '5.8',
      'weight': 154.3,
      'heightUnit': 'ft',
      'weightUnit': 'lbs',
    });
  });

  testWidgets('body measurements convert entered values when units change', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pumpBodyMeasurements(tester, container);

    await _enterText(
      tester,
      find.widgetWithText(TextFormField, 'Enter height'),
      '170',
    );
    await _enterText(
      tester,
      find.widgetWithText(TextFormField, 'Enter weight'),
      '70',
    );

    await _tap(tester, find.text('ft'));
    expect(_fieldText(tester, 'Enter height'), '5.7');

    await _tap(tester, find.text('lbs'));
    expect(_fieldText(tester, 'Enter weight'), '154.3');

    await _tap(tester, find.widgetWithText(ElevatedButton, 'Continue'));

    expect(find.text('route:activity-goals'), findsOneWidget);
    expect(container.read(surveyNotifierProvider).surveyData, {
      'height': 67.0,
      'heightInput': '5.7',
      'weight': 154.3,
      'heightUnit': 'ft',
      'weightUnit': 'lbs',
    });
  });

  testWidgets('body measurements ignore duplicate continue taps while saving', (
    tester,
  ) async {
    final completionCompleter = Completer<void>();
    final completionHandler = _BlockingSurveyCompletionHandler(
      completionCompleter,
    );
    final container = _containerWithCompletionHandler(completionHandler);
    addTearDown(container.dispose);

    await _pumpBodyMeasurements(
      tester,
      container,
      args: const {'userId': 'body-user'},
    );

    await _enterText(
      tester,
      find.widgetWithText(TextFormField, 'Enter height'),
      '170',
    );
    await _enterText(
      tester,
      find.widgetWithText(TextFormField, 'Enter weight'),
      '70',
    );

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Continue'));
    final continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    final onPressed = continueButton.onPressed!;

    onPressed();
    onPressed();
    await tester.pump();

    expect(find.text('Saving...'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Saving...'),
          )
          .onPressed,
      isNull,
    );
    expect(completionHandler.completionCalls, 1);
    expect(find.text('route:activity-goals'), findsNothing);

    completionCompleter.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('route:activity-goals'), findsOneWidget);
    expect(completionHandler.completionCalls, 1);
  });

  testWidgets('activity goals require both selections before continuing', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pumpActivityGoals(tester, container);

    var continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNull);

    await _tap(tester, find.text('Sedentary'));
    continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNull);

    await _tap(tester, find.text('Lose Weight'));
    continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNotNull);

    await _tap(tester, find.text('Build Muscle'));
    await _tap(tester, find.widgetWithText(ElevatedButton, 'Continue'));

    expect(find.text('route:daily-targets'), findsOneWidget);
    expect(container.read(surveyNotifierProvider).surveyData, {
      'activityLevel': 'sedentary',
      'goals': ['lose_weight', 'build_muscle'],
    });
  });

  testWidgets('activity goals ignore duplicate continue taps while saving', (
    tester,
  ) async {
    final completionCompleter = Completer<void>();
    final completionHandler = _BlockingSurveyCompletionHandler(
      completionCompleter,
    );
    final container = _containerWithCompletionHandler(completionHandler);
    addTearDown(container.dispose);

    await _pumpActivityGoals(
      tester,
      container,
      args: const {'userId': 'activity-user'},
    );

    await _tap(tester, find.text('Sedentary'));
    await _tap(tester, find.text('Lose Weight'));

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pump();

    expect(find.text('Saving...'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Saving...'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Saving...'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('route:daily-targets'), findsNothing);

    completionCompleter.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('route:daily-targets'), findsOneWidget);
    expect(completionHandler.completionCalls, 1);
  });

  testWidgets('daily targets convert Imperial units and complete profile', (
    tester,
  ) async {
    final repository = _InMemoryProfileRepository();
    final container = _dailyTargetsContainer(repository);
    addTearDown(container.dispose);
    await _seedImperialSurveyData(container);

    await _pumpDailyTargets(
      tester,
      container,
      args: const {'userId': 'daily-user'},
    );

    await _tap(tester, find.text('Open Daily Targets'));
    expect(find.text('1541'), findsOneWidget);
    expect(find.text('5 ft 10 in • 70lbs'), findsOneWidget);

    tester.widget<Slider>(find.byType(Slider).at(0)).onChanged!(3);
    await tester.pump();
    expect(find.text('15,000 steps'), findsOneWidget);

    tester.widget<Slider>(find.byType(Slider).at(1)).onChanged!(3);
    await tester.pump();
    expect(find.text('60 minutes'), findsOneWidget);

    tester.widget<Slider>(find.byType(Slider).at(2)).onChanged!(3);
    await tester.pump();
    expect(find.text('3.0 liters'), findsOneWidget);

    await _tap(tester, find.text('Complete & Start App'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('route:dashboard'), findsOneWidget);

    final profile = await repository.getLocalProfile('daily-user');
    expect(profile, isNotNull);
    expect(profile!.height, 70.0);
    expect(profile.heightUnit, 'ft');
    expect(profile.weight, 70.0);
    expect(profile.weightUnit, 'lbs');
    expect(profile.dailyCalorieTarget, 1541);
    expect(profile.dailyStepsTarget, 15000);
    expect(profile.dailyActiveMinutesTarget, 60);
    expect(profile.dailyWaterTarget, 3.0);
  });
}

Future<void> _pumpBodyMeasurements(
  WidgetTester tester,
  ProviderContainer container, {
  Map<String, dynamic>? args,
}) async {
  await _setPhoneViewport(tester);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        initialRoute: '/survey_body_measurements',
        onGenerateRoute: (settings) {
          if (settings.name == '/survey_body_measurements') {
            return MaterialPageRoute<void>(
              settings: RouteSettings(name: settings.name, arguments: args),
              builder: (_) => const SurveyBodyMeasurementsScreen(),
            );
          }

          return null;
        },
        routes: {
          '/survey_activity_goals': (_) =>
              const Scaffold(body: Text('route:activity-goals')),
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _pumpActivityGoals(
  WidgetTester tester,
  ProviderContainer container, {
  Map<String, dynamic>? args,
}) async {
  final routeArgs = args;
  await _setPhoneViewport(tester);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        initialRoute: '/survey_activity_goals',
        onGenerateRoute: (settings) {
          if (settings.name == '/survey_activity_goals') {
            return MaterialPageRoute<void>(
              settings: RouteSettings(
                name: settings.name,
                arguments: routeArgs,
              ),
              builder: (_) => const SurveyActivityGoalsScreen(),
            );
          }

          return null;
        },
        routes: {
          '/survey_daily_targets': (_) =>
              const Scaffold(body: Text('route:daily-targets')),
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _pumpDailyTargets(
  WidgetTester tester,
  ProviderContainer container, {
  required Map<String, dynamic> args,
}) async {
  await _setPhoneViewport(tester);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/survey_daily_targets',
                    arguments: args,
                  );
                },
                child: const Text('Open Daily Targets'),
              ),
            ),
          ),
        ),
        onGenerateRoute: (settings) {
          if (settings.name == '/survey_daily_targets') {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const SurveyDailyTargetsScreen(),
            );
          }

          return null;
        },
        routes: {
          '/dashboard': (_) => const Scaffold(body: Text('route:dashboard')),
        },
      ),
    ),
  );
  await tester.pump();
}

Future<void> _enterText(WidgetTester tester, Finder finder, String text) async {
  final target = finder.first;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.enterText(target, text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  final target = finder.first;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

String _fieldText(WidgetTester tester, String hintText) {
  return tester
      .widget<TextFormField>(find.widgetWithText(TextFormField, hintText))
      .controller!
      .text;
}

ProviderContainer _container() {
  return ProviderContainer(
    overrides: [
      profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
    ],
  );
}

ProviderContainer _containerWithCompletionHandler(
  SurveyCompletionHandler completionHandler,
) {
  return ProviderContainer(
    overrides: [
      profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
      profile_providers.surveyCompletionHandlerProvider.overrideWith(
        (ref) async => completionHandler,
      ),
    ],
  );
}

ProviderContainer _dailyTargetsContainer(
  _InMemoryProfileRepository repository,
) {
  return ProviderContainer(
    overrides: [
      profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
      profile_providers.profileRepositoryProvider.overrideWith(
        (ref) async => repository,
      ),
      profile_providers.surveyCompletionHandlerProvider.overrideWith(
        (ref) async => SurveyCompletionHandler(profileRepository: repository),
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
}

Future<void> _seedImperialSurveyData(ProviderContainer container) async {
  final notifier = container.read(surveyNotifierProvider.notifier);
  await notifier.updateSurveyData('fullName', 'Daily User');
  await notifier.updateSurveyData('age', 30);
  await notifier.updateSurveyData('gender', 'male');
  await notifier.updateSurveyData('height', 70.0);
  await notifier.updateSurveyData('heightInput', '5.10');
  await notifier.updateSurveyData('heightUnit', 'ft');
  await notifier.updateSurveyData('weight', 70.0);
  await notifier.updateSurveyData('weightUnit', 'lbs');
  await notifier.updateSurveyData('activityLevel', 'sedentary');
  await notifier.updateSurveyData('goals', ['maintain_weight']);
}

Future<void> _setPhoneViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _FakeProfileRepository implements IProfileRepository {
  @override
  Future<UserProfile> createProfile(UserProfile profile) async => profile;

  @override
  Future<UserProfile?> getProfile(String userId) async => null;

  @override
  Future<bool> hasCompletedSurvey(String userId) async => false;

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async => profile;
}

class _InMemoryProfileRepository
    implements core_profile_repo.ProfileRepository {
  final Map<String, core_profile.UserProfile> _profiles = {};

  int get pendingSyncCount =>
      _profiles.values.where((profile) => !profile.isSynced).length;

  @override
  Future<core_profile.UserProfile?> getLocalProfile(String userId) async {
    return _profiles[userId];
  }

  @override
  Future<void> saveLocalProfile(core_profile.UserProfile profile) async {
    _profiles[profile.userId] = profile;
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
  Future<void> saveBackendProfile(core_profile.UserProfile profile) async {
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
  Stream<core_profile_repo.SyncStatus> watchSyncStatus(String userId) {
    final profile = _profiles[userId];
    if (profile == null || profile.isSynced) {
      return Stream.value(core_profile_repo.SyncStatus.synced);
    }

    return Stream.value(core_profile_repo.SyncStatus.pendingSync);
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    return _profiles.containsKey(userId);
  }
}

class _BlockingSurveyCompletionHandler extends SurveyCompletionHandler {
  _BlockingSurveyCompletionHandler(this.completer)
    : super(profileRepository: _InMemoryProfileRepository());

  final Completer<void> completer;
  int completionCalls = 0;

  @override
  Future<bool> completeSurvey(
    String userId,
    Map<String, dynamic> surveyData,
  ) async {
    completionCalls++;
    await completer.future;
    return true;
  }
}
