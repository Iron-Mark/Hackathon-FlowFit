import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('survey middle steps use named route transitions', () {
    final bodyMeasurements = File(
      'lib/screens/onboarding/survey_body_measurements_screen.dart',
    ).readAsStringSync();
    final activityGoals = File(
      'lib/screens/onboarding/survey_activity_goals_screen.dart',
    ).readAsStringSync();

    expect(bodyMeasurements, contains("Navigator.pushNamed("));
    expect(bodyMeasurements, contains("'/survey_activity_goals'"));
    expect(bodyMeasurements, isNot(contains('MaterialPageRoute(')));

    expect(activityGoals, contains("Navigator.pushNamed("));
    expect(activityGoals, contains("'/survey_daily_targets'"));
    expect(activityGoals, isNot(contains('MaterialPageRoute(')));
  });
}
