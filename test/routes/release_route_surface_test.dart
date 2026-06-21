import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const legacySurveyIntroRoute =
      '/survey'
      '-intro';
  const legacyBuddyCompletionRoute =
      '/buddy'
      '_completion';

  late String mainSource;
  late String buddyProfileSetupSource;
  late String profileSource;
  late int debugRouteGate;
  late Set<String> releaseRoutes;

  setUpAll(() {
    mainSource = File('lib/main.dart').readAsStringSync();
    buddyProfileSetupSource = File(
      'lib/screens/onboarding/buddy_profile_setup_screen.dart',
    ).readAsStringSync();
    profileSource = File(
      'lib/screens/profile/profile_screen.dart',
    ).readAsStringSync();
    debugRouteGate = mainSource.indexOf('if (kDebugMode) ...{');
    final releaseRouteSource = debugRouteGate == -1
        ? mainSource
        : mainSource.substring(0, debugRouteGate);
    releaseRoutes = RegExp(
      r'''['"](/[^'"]*)['"]\s*:''',
    ).allMatches(releaseRouteSource).map((match) => match.group(1)!).toSet();
  });

  test('debug-only named routes are gated from the production route map', () {
    expect(debugRouteGate, isNonNegative);
    expect(mainSource, contains("'/activity-classifier'"));
    expect(
      mainSource.substring(0, debugRouteGate),
      isNot(contains("'/font-demo'")),
    );
    expect(
      mainSource.substring(0, debugRouteGate),
      isNot(contains("'/yolo-debug'")),
    );
    expect(
      mainSource.substring(0, debugRouteGate),
      isNot(contains("'/trackertest'")),
    );
    expect(mainSource.substring(debugRouteGate), contains("'/font-demo'"));
    expect(mainSource.substring(debugRouteGate), contains("'/yolo-debug'"));
    expect(mainSource.substring(debugRouteGate), contains("'/trackertest'"));
  });

  test('debug route menu is not mounted in the production app shell', () {
    expect(
      mainSource,
      isNot(
        matches(
          RegExp(
            r"^\s*import\s+'widgets/debug_route_menu\.dart';",
            multiLine: true,
          ),
        ),
      ),
    );
    expect(
      mainSource,
      isNot(
        matches(RegExp(r'^\s*const\s+DebugRouteMenu\(\),', multiLine: true)),
      ),
    );
  });

  test('known onboarding named routes match the MaterialApp route table', () {
    expect(mainSource, contains("'/age-gate':"));
    expect(mainSource, contains("'/survey_intro':"));
    expect(mainSource, contains("'/buddy-completion':"));

    expect(profileSource, contains("'/survey_intro'"));
    expect(profileSource, isNot(contains("'$legacySurveyIntroRoute'")));

    expect(mainSource, contains("'/buddy_profile_setup':"));
    expect(mainSource, contains("'/goal-selection':"));
    expect(buddyProfileSetupSource, contains("'/goal-selection'"));
    expect(buddyProfileSetupSource, isNot(contains("'/buddy-completion'")));
    expect(
      buddyProfileSetupSource,
      isNot(contains("'$legacyBuddyCompletionRoute'")),
    );
  });

  test('release route table keeps the public feature routes wired', () {
    const requiredReleaseRoutes = <String>{
      '/',
      '/loading',
      '/welcome',
      '/login',
      '/signup',
      '/email_verification',
      '/age-gate',
      '/survey_intro',
      '/survey_basic_info',
      '/survey_body_measurements',
      '/survey_activity_goals',
      '/survey_daily_targets',
      '/dashboard',
      '/activity-classifier',
      '/mission',
      '/home',
      '/phone_heart_rate',
      '/privacy-policy',
      '/settings',
      '/notification-settings',
      '/app-integration',
      '/language-settings',
      '/unit-settings',
      '/terms-of-service',
      '/help-support',
      '/change-password',
      '/delete-account',
      '/weight-goals',
      '/fitness-goals',
      '/nutrition-goals',
      '/about-us',
      '/workout/select-type',
      '/workout/running/setup',
      '/workout/running/active',
      '/workout/running/summary',
      '/workout/running/share',
      '/workout/walking/options',
      '/workout/walking/mission',
      '/workout/walking/active',
      '/workout/walking/summary',
      '/workout/resistance/select-split',
      '/workout/resistance/active',
      '/workout/resistance/summary',
      '/wellness-tracker',
      '/wellness-onboarding',
      '/wellness-settings',
      '/buddy-welcome',
      '/buddy-intro',
      '/buddy-hatch',
      '/buddy-color-selection',
      '/buddy-naming',
      '/goal-selection',
      '/notification-permission',
      '/buddy-ready',
      '/buddy_profile_setup',
      '/buddy-completion',
      '/buddy-customization',
    };

    expect(releaseRoutes, containsAll(requiredReleaseRoutes));
  });

  test('direct named route references are registered in release MaterialApp', () {
    final directNamedRoutePattern = RegExp(
      r'''(?:pushNamed|pushReplacementNamed|pushNamedAndRemoveUntil)\s*\(\s*(?:context\s*,\s*)?['"](/[^'"]+)['"]''',
    );

    final referencedRoutes = <String, Set<String>>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final source = entity.readAsStringSync();
      for (final match in directNamedRoutePattern.allMatches(source)) {
        referencedRoutes
            .putIfAbsent(match.group(1)!, () => <String>{})
            .add(entity.path.replaceAll('\\', '/'));
      }
    }

    final missing =
        referencedRoutes.entries
            .where((entry) => !releaseRoutes.contains(entry.key))
            .map((entry) => '${entry.key}: ${entry.value.join(', ')}')
            .toList()
          ..sort();

    expect(missing, isEmpty);
  });
}
