import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WeightGoalSettings {
  const WeightGoalSettings({
    required this.currentWeight,
    required this.goalWeight,
    required this.weeklyGoal,
  });

  final String currentWeight;
  final String goalWeight;
  final String weeklyGoal;

  factory WeightGoalSettings.defaults() => const WeightGoalSettings(
    currentWeight: '145',
    goalWeight: '135',
    weeklyGoal: '1 lb/week',
  );

  factory WeightGoalSettings.fromJson(Map<String, dynamic> json) {
    final defaults = WeightGoalSettings.defaults();
    return WeightGoalSettings(
      currentWeight: _stringOrDefault(
        json['currentWeight'],
        defaults.currentWeight,
      ),
      goalWeight: _stringOrDefault(json['goalWeight'], defaults.goalWeight),
      weeklyGoal: _stringOrDefault(json['weeklyGoal'], defaults.weeklyGoal),
    );
  }

  Map<String, dynamic> toJson() => {
    'currentWeight': currentWeight,
    'goalWeight': goalWeight,
    'weeklyGoal': weeklyGoal,
  };
}

class FitnessGoalSettings {
  const FitnessGoalSettings({
    required this.activityLevel,
    required this.workoutsPerWeek,
    required this.minutesPerWorkout,
    required this.goals,
  });

  final String activityLevel;
  final int workoutsPerWeek;
  final int minutesPerWorkout;
  final List<String> goals;

  factory FitnessGoalSettings.defaults() => const FitnessGoalSettings(
    activityLevel: 'Moderate',
    workoutsPerWeek: 4,
    minutesPerWorkout: 45,
    goals: ['Weight Loss', 'Build Muscle'],
  );

  factory FitnessGoalSettings.fromJson(Map<String, dynamic> json) {
    final defaults = FitnessGoalSettings.defaults();
    final goals = json['goals'];
    return FitnessGoalSettings(
      activityLevel: _stringOrDefault(
        json['activityLevel'],
        defaults.activityLevel,
      ),
      workoutsPerWeek: _intOrDefault(
        json['workoutsPerWeek'],
        defaults.workoutsPerWeek,
      ),
      minutesPerWorkout: _intOrDefault(
        json['minutesPerWorkout'],
        defaults.minutesPerWorkout,
      ),
      goals: goals is List
          ? goals.whereType<String>().toList()
          : List<String>.from(defaults.goals),
    );
  }

  Map<String, dynamic> toJson() => {
    'activityLevel': activityLevel,
    'workoutsPerWeek': workoutsPerWeek,
    'minutesPerWorkout': minutesPerWorkout,
    'goals': goals,
  };
}

class NutritionGoalSettings {
  const NutritionGoalSettings({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.useCustomMacros,
  });

  final String calories;
  final String protein;
  final String carbs;
  final String fats;
  final bool useCustomMacros;

  factory NutritionGoalSettings.defaults() => const NutritionGoalSettings(
    calories: '2000',
    protein: '150',
    carbs: '200',
    fats: '65',
    useCustomMacros: false,
  );

  factory NutritionGoalSettings.fromJson(Map<String, dynamic> json) {
    final defaults = NutritionGoalSettings.defaults();
    return NutritionGoalSettings(
      calories: _stringOrDefault(json['calories'], defaults.calories),
      protein: _stringOrDefault(json['protein'], defaults.protein),
      carbs: _stringOrDefault(json['carbs'], defaults.carbs),
      fats: _stringOrDefault(json['fats'], defaults.fats),
      useCustomMacros: json['useCustomMacros'] is bool
          ? json['useCustomMacros'] as bool
          : defaults.useCustomMacros,
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fats': fats,
    'useCustomMacros': useCustomMacros,
  };
}

class ProfileGoalPreferences {
  ProfileGoalPreferences(this._prefs);

  static const weightGoalsKey = 'profile_weight_goals_v1';
  static const fitnessGoalsKey = 'profile_fitness_goals_v1';
  static const nutritionGoalsKey = 'profile_nutrition_goals_v1';

  final SharedPreferences _prefs;

  Future<WeightGoalSettings> loadWeightGoals() async {
    return WeightGoalSettings.fromJson(_readJson(weightGoalsKey));
  }

  Future<void> saveWeightGoals(WeightGoalSettings settings) async {
    await _writeJson(weightGoalsKey, settings.toJson());
  }

  Future<FitnessGoalSettings> loadFitnessGoals() async {
    return FitnessGoalSettings.fromJson(_readJson(fitnessGoalsKey));
  }

  Future<void> saveFitnessGoals(FitnessGoalSettings settings) async {
    await _writeJson(fitnessGoalsKey, settings.toJson());
  }

  Future<NutritionGoalSettings> loadNutritionGoals() async {
    return NutritionGoalSettings.fromJson(_readJson(nutritionGoalsKey));
  }

  Future<void> saveNutritionGoals(NutritionGoalSettings settings) async {
    await _writeJson(nutritionGoalsKey, settings.toJson());
  }

  Map<String, dynamic> _readJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  Future<void> _writeJson(String key, Map<String, dynamic> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }
}

String _stringOrDefault(Object? value, String fallback) {
  if (value is! String || value.trim().isEmpty) {
    return fallback;
  }
  return value;
}

int _intOrDefault(Object? value, int fallback) {
  if (value is int) {
    return value;
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}
