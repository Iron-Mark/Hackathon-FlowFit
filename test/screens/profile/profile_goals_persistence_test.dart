import 'package:flowfit/screens/profile/goals/fitness_goals_screen.dart';
import 'package:flowfit/screens/profile/goals/nutrition_goals_screen.dart';
import 'package:flowfit/screens/profile/goals/weight_goals_screen.dart';
import 'package:flowfit/services/profile_goal_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('weight goals save button persists edited values', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(const MaterialApp(home: WeightGoalsScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter current weight'),
      '155',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter goal weight'),
      '145',
    );
    await tester.ensureVisible(find.text('Save Goals'));
    await tester.tap(find.text('Save Goals'));
    await tester.pumpAndSettle();

    final loaded = await ProfileGoalPreferences(prefs).loadWeightGoals();
    expect(loaded.currentWeight, '155');
    expect(loaded.goalWeight, '145');
  });

  testWidgets('fitness goals save button persists selected plan', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(const MaterialApp(home: FitnessGoalsScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Improve Endurance'));
    await tester.tap(find.text('Improve Endurance'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Goals'));
    await tester.tap(find.text('Save Goals'));
    await tester.pumpAndSettle();

    final loaded = await ProfileGoalPreferences(prefs).loadFitnessGoals();
    expect(loaded.goals, contains('Improve Endurance'));
  });

  testWidgets('nutrition goals save button persists custom macros', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(const MaterialApp(home: NutritionGoalsScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter daily calories'),
      '2100',
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter protein goal'),
      '160',
    );
    await tester.ensureVisible(find.text('Save Goals'));
    await tester.tap(find.text('Save Goals'));
    await tester.pumpAndSettle();

    final loaded = await ProfileGoalPreferences(prefs).loadNutritionGoals();
    expect(loaded.calories, '2100');
    expect(loaded.protein, '160');
    expect(loaded.useCustomMacros, isTrue);
  });
}
