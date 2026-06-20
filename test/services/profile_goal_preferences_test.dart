import 'package:flowfit/services/profile_goal_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ProfileGoalPreferences', () {
    test('saves and loads weight goals', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = ProfileGoalPreferences(prefs);

      await store.saveWeightGoals(
        const WeightGoalSettings(
          currentWeight: '150',
          goalWeight: '140',
          weeklyGoal: '0.5 lb/week',
        ),
      );

      final loaded = await store.loadWeightGoals();

      expect(loaded.currentWeight, '150');
      expect(loaded.goalWeight, '140');
      expect(loaded.weeklyGoal, '0.5 lb/week');
    });

    test('saves and loads fitness goals', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = ProfileGoalPreferences(prefs);

      await store.saveFitnessGoals(
        const FitnessGoalSettings(
          activityLevel: 'Active',
          workoutsPerWeek: 5,
          minutesPerWorkout: 60,
          goals: ['Improve Endurance', 'General Fitness'],
        ),
      );

      final loaded = await store.loadFitnessGoals();

      expect(loaded.activityLevel, 'Active');
      expect(loaded.workoutsPerWeek, 5);
      expect(loaded.minutesPerWorkout, 60);
      expect(loaded.goals, ['Improve Endurance', 'General Fitness']);
    });

    test('saves and loads nutrition goals', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = ProfileGoalPreferences(prefs);

      await store.saveNutritionGoals(
        const NutritionGoalSettings(
          calories: '2100',
          protein: '160',
          carbs: '220',
          fats: '70',
          useCustomMacros: true,
        ),
      );

      final loaded = await store.loadNutritionGoals();

      expect(loaded.calories, '2100');
      expect(loaded.protein, '160');
      expect(loaded.carbs, '220');
      expect(loaded.fats, '70');
      expect(loaded.useCustomMacros, isTrue);
    });

    test('falls back to defaults for corrupt persisted data', () async {
      SharedPreferences.setMockInitialValues({
        ProfileGoalPreferences.weightGoalsKey: '{bad json',
        ProfileGoalPreferences.fitnessGoalsKey: '[]',
        ProfileGoalPreferences.nutritionGoalsKey: '',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = ProfileGoalPreferences(prefs);

      expect(
        (await store.loadWeightGoals()).currentWeight,
        WeightGoalSettings.defaults().currentWeight,
      );
      expect(
        (await store.loadFitnessGoals()).activityLevel,
        FitnessGoalSettings.defaults().activityLevel,
      );
      expect(
        (await store.loadNutritionGoals()).calories,
        NutritionGoalSettings.defaults().calories,
      );
    });
  });
}
