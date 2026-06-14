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

  setUpAll(() {
    mainSource = File('lib/main.dart').readAsStringSync();
    buddyProfileSetupSource = File(
      'lib/screens/onboarding/buddy_profile_setup_screen.dart',
    ).readAsStringSync();
    profileSource = File(
      'lib/screens/profile/profile_screen.dart',
    ).readAsStringSync();
  });

  test('debug-only named routes are gated from the production route map', () {
    final debugRouteGate = mainSource.indexOf('if (kDebugMode) ...{');

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

  test('known onboarding named routes match the MaterialApp route table', () {
    expect(mainSource, contains("'/survey_intro':"));
    expect(mainSource, contains("'/buddy-completion':"));

    expect(profileSource, contains("'/survey_intro'"));
    expect(profileSource, isNot(contains("'$legacySurveyIntroRoute'")));

    expect(buddyProfileSetupSource, contains("'/buddy-completion'"));
    expect(
      buddyProfileSetupSource,
      isNot(contains("'$legacyBuddyCompletionRoute'")),
    );
  });
}
