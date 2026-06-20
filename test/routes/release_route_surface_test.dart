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

  test('direct named route references are registered in MaterialApp', () {
    final definedRoutes = RegExp(
      r'''['"](/[^'"]+)['"]\s*:''',
    ).allMatches(mainSource).map((match) => match.group(1)!).toSet();

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
            .where((entry) => !definedRoutes.contains(entry.key))
            .map((entry) => '${entry.key}: ${entry.value.join(', ')}')
            .toList()
          ..sort();

    expect(missing, isEmpty);
  });
}
