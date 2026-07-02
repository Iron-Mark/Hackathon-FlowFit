import 'dart:io';

import 'package:flowfit/domain/entities/user.dart';
import 'package:flowfit/domain/entities/user_profile.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/domain/repositories/i_profile_repository.dart';
import 'package:flowfit/main.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/providers/buddy_profile_provider.dart' as buddy_profile;
import 'package:flowfit/providers/wellness_state_provider.dart' as wellness;
import 'package:flowfit/widgets/buddy_pending_sync_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('welcome actions navigate through the production route table', (
    tester,
  ) async {
    await _pumpFlowFitAppAt(tester, '/welcome');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);

    final readTerms = find.text('Read Terms');
    await tester.ensureVisible(readTerms);
    await tester.pumpAndSettle();
    await tester.tap(readTerms);
    await tester.pumpAndSettle();

    expect(find.text('Terms of Service'), findsWidgets);

    Navigator.of(tester.element(find.byType(Scaffold))).pop();
    await tester.pumpAndSettle();

    final readPolicy = find.text('Read Policy');
    await tester.ensureVisible(readPolicy);
    await tester.pumpAndSettle();
    await tester.tap(readPolicy);
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsWidgets);

    Navigator.of(tester.element(find.byType(Scaffold))).pop();
    await tester.pumpAndSettle();

    final loginLink = find.text('Log In').last;
    await tester.ensureVisible(loginLink);
    await tester.pumpAndSettle();
    await tester.tap(loginLink);
    await tester.pumpAndSettle();

    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('login sign-up action returns to the production signup route', (
    tester,
  ) async {
    await _pumpFlowFitAppAt(tester, '/login');

    final signUpLink = find.text('Sign Up').last;
    await tester.ensureVisible(signUpLink);
    await tester.pumpAndSettle();
    await tester.tap(signUpLink);
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('workout type actions open their production setup routes', (
    tester,
  ) async {
    await _pumpFlowFitAppAt(tester, '/workout/select-type');

    await tester.tap(find.text('Running'));
    await tester.pumpAndSettle();

    expect(find.text('Running Setup'), findsOneWidget);
    expect(find.text('Start Running'), findsOneWidget);

    await _pumpFlowFitAppAt(tester, '/workout/select-type');

    await tester.tap(find.text('Walking'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Walking Mode'), findsOneWidget);
    expect(find.text('Start Free Walk'), findsOneWidget);

    await _pumpFlowFitAppAt(tester, '/workout/select-type');

    await tester.ensureVisible(find.text('Resistance Training'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resistance Training'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Your Split'), findsOneWidget);
    expect(find.text('Chest, Back, Shoulders, Arms'), findsOneWidget);
  });

  const settingsDestinations = <String, String>{
    'Privacy Policy': 'FlowFit is built for fitness',
    'Notification Reminder': 'Achievement Notifications',
    'App Integration': 'Set up Galaxy Watch sensors',
    'Language': 'Select your preferred language',
    'Units': 'Measurement System',
    'Delete Account': 'Submitting this request will:',
    'Terms of Service': 'Acceptance of Terms',
    'Help & Support': 'Email Support',
    'About Us': 'Meet the team behind FlowFit',
  };

  for (final destination in settingsDestinations.entries) {
    testWidgets('settings ${destination.key} opens its production route', (
      tester,
    ) async {
      await _pumpFlowFitAppAt(tester, '/settings');

      final item = find.text(destination.key);
      await tester.ensureVisible(item);
      await tester.pumpAndSettle();
      await tester.tap(item);
      await tester.pumpAndSettle();

      expect(find.textContaining(destination.value), findsWidgets);
    });
  }

  const routeEntryExpectations = <String, _RouteEntryExpectation>{
    '/landing': _RouteEntryExpectation('Start in the browser'),
    '/welcome': _RouteEntryExpectation('Find Your Flow'),
    '/login': _RouteEntryExpectation('Welcome Back!'),
    '/signup': _RouteEntryExpectation('Create Your Account'),
    '/age-gate': _RouteEntryExpectation('Welcome to FlowFit!'),
    '/survey_intro': _RouteEntryExpectation('Quick Setup'),
    '/survey_basic_info': _RouteEntryExpectation('Tell us about yourself'),
    '/survey_body_measurements': _RouteEntryExpectation('Your measurements'),
    '/survey_activity_goals': _RouteEntryExpectation('Activity & Goals'),
    '/survey_daily_targets': _RouteEntryExpectation('Your Daily Targets'),
    '/onboarding1': _RouteEntryExpectation('Track Your Heart Rate'),
    '/dashboard': _RouteEntryExpectation('Find Your Flow'),
    '/home': _RouteEntryExpectation('FlowFit'),
    '/phone_heart_rate': _RouteEntryExpectation('Watch Heart Rate Data'),
    '/privacy-policy': _RouteEntryExpectation('FlowFit is built for fitness'),
    '/settings': _RouteEntryExpectation('General Settings'),
    '/notification-settings': _RouteEntryExpectation(
      'Achievement Notifications',
    ),
    '/app-integration': _RouteEntryExpectation('Set up Galaxy Watch sensors'),
    '/language-settings': _RouteEntryExpectation(
      'Select your preferred language',
    ),
    '/unit-settings': _RouteEntryExpectation('Measurement System'),
    '/terms-of-service': _RouteEntryExpectation('Acceptance of Terms'),
    '/help-support': _RouteEntryExpectation('Email Support'),
    '/change-password': _RouteEntryExpectation('Change Password'),
    '/delete-account': _RouteEntryExpectation('Submitting this request will:'),
    '/weight-goals': _RouteEntryExpectation('Weight Goals'),
    '/fitness-goals': _RouteEntryExpectation('Fitness Goals'),
    '/nutrition-goals': _RouteEntryExpectation('Nutrition Goals'),
    '/about-us': _RouteEntryExpectation('Meet the team behind FlowFit'),
    '/workout/select-type': _RouteEntryExpectation('Choose Your Workout'),
    '/workout/running/setup': _RouteEntryExpectation('Running Setup'),
    '/workout/running/summary': _RouteEntryExpectation('Back to Dashboard'),
    '/workout/running/share': _RouteEntryExpectation(
      'No running session is available to share.',
    ),
    '/workout/walking/options': _RouteEntryExpectation('Choose Walking Mode'),
    '/workout/walking/mission': _RouteEntryExpectation('Create Mission'),
    '/workout/walking/active': _RouteEntryExpectation(
      'No active walking session',
    ),
    '/workout/walking/summary': _RouteEntryExpectation('Back to Dashboard'),
    '/workout/resistance/select-split': _RouteEntryExpectation(
      'Choose Your Split',
    ),
    '/workout/resistance/active': _RouteEntryExpectation(
      'No active resistance workout',
    ),
    '/workout/resistance/summary': _RouteEntryExpectation(
      'No completed workout available',
    ),
    '/wellness-tracker': _RouteEntryExpectation('Welcome to Wellness Tracker'),
    '/wellness-onboarding': _RouteEntryExpectation(
      'Welcome to Wellness Tracker',
    ),
    '/wellness-settings': _RouteEntryExpectation('Wellness Settings'),
    '/buddy-welcome': _RouteEntryExpectation('Fitness Buddy'),
    '/buddy-intro': _RouteEntryExpectation('Splash splash'),
    '/buddy-color-selection': _RouteEntryExpectation(
      'Choose your Whale Color!',
    ),
    '/buddy-naming': _RouteEntryExpectation(
      'What do you want to name your baby whale?',
    ),
    '/goal-selection': _RouteEntryExpectation(
      'What areas would you like support with?',
    ),
    '/notification-permission': _RouteEntryExpectation('Maybe later'),
    '/buddy-ready': _RouteEntryExpectation('START ADVENTURE!'),
    '/buddy_profile_setup': _RouteEntryExpectation(
      'Tell Buddy about yourself!',
    ),
    '/buddy-completion': _RouteEntryExpectation('START FIRST MISSION'),
    '/buddy-customization': _RouteEntryExpectation(
      'Please log in to customize your Buddy',
    ),
  };

  test(
    'release routes have route-entry smoke coverage or reviewed exemption',
    () {
      final untestedRoutes = _releaseRoutes()
          .difference(routeEntryExpectations.keys.toSet())
          .difference(_routeEntrySmokeExemptions);

      expect(
        untestedRoutes,
        isEmpty,
        reason:
            'Every production route should render an offline entry state in this '
            'smoke test, or be listed in _routeEntrySmokeExemptions with a '
            'reason.',
      );
    },
  );

  for (final route in routeEntryExpectations.entries) {
    testWidgets('production route ${route.key} renders an entry state', (
      tester,
    ) async {
      final expectation = route.value;
      await _pumpFlowFitAppAt(tester, route.key, settleAfterRoute: false);

      expect(find.textContaining(expectation.text), findsWidgets);
    });
  }
}

const _routeEntrySmokeExemptions = <String>{
  // The root route is the app startup splash path. Dedicated splash tests cover
  // its auth/profile resolution instead of treating it as a static entry page.
  '/',
  // The web app CTA uses this startup splash route before resolving auth state.
  '/app',
  // Loading has a startup redirect timer that is covered by loading_screen_test.
  '/loading',
  // The route listens to Supabase auth state directly. Injected email
  // verification actions are covered in the auth screen tests.
  '/email_verification',
  // The active running route starts delayed workout/device detection timers.
  // Dedicated active-workout tests cover its offline empty/control states.
  '/workout/running/active',
  // The classifier route loads native TFLite at startup. Domain/platform
  // classifier tests cover the route behavior without requiring the VM DLL.
  '/activity-classifier',
  // The maps mission route starts watch/location services and keeps device
  // timers alive. Mission widgets and dialogs are covered in focused tests.
  '/mission',
  // Buddy hatch intentionally auto-advances on a timer. The Buddy entry-flow
  // tests cover the timer-driven transition.
  '/buddy-hatch',
};

Set<String> _releaseRoutes() {
  final mainSource = File('lib/main.dart').readAsStringSync();
  final debugRoutesStart = mainSource.indexOf('if (kDebugMode)');
  final releaseSource = debugRoutesStart == -1
      ? mainSource
      : mainSource.substring(0, debugRoutesStart);

  return RegExp(
    r"'(/[^']+)'\s*:",
  ).allMatches(releaseSource).map((match) => match.group(1)!).toSet();
}

class _RouteEntryExpectation {
  const _RouteEntryExpectation(this.text);

  final String text;
}

Future<void> _pumpFlowFitAppAt(
  WidgetTester tester,
  String routeName, {
  bool settleAfterRoute = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_UnauthenticatedAuth()),
        profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
        buddy_profile.buddyCustomizationCurrentUserIdProvider.overrideWithValue(
          null,
        ),
        buddyPendingSyncUserIdProvider.overrideWithValue(null),
        buddyPendingSyncActionProvider.overrideWithValue(() async {}),
        wellness.sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FlowFitPhoneApp(),
    ),
  );
  await tester.pump();

  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  navigator.pushReplacementNamed(routeName);
  if (settleAfterRoute) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  await tester.pump(const Duration(seconds: 3));
  if (settleAfterRoute) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

class _UnauthenticatedAuth implements IAuthRepository {
  User? _currentUser;

  @override
  Stream<User?> authStateChanges() => const Stream<User?>.empty();

  @override
  Future<User?> getCurrentUser() async => _currentUser;

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    _currentUser = _fakeAuthUser(email: email);
    return _currentUser!;
  }

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    _currentUser = _fakeAuthUser(email: email, fullName: fullName);
    return _currentUser!;
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
