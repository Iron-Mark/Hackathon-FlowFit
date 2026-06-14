import '../models/workout_session.dart';

/// Service for calculating calories burned during workouts
class CalorieCalculatorService {
  // Default user profile values (should be fetched from user settings)
  static const double defaultWeight = 70.0; // kg
  static const int defaultAge = 30;
  static const String defaultGender = 'male';

  /// Calculates calories burned for a workout session
  int calculateCalories({
    required WorkoutType workoutType,
    required int durationMinutes,
    double? distanceKm,
    int? avgHeartRate,
    double? weight,
    int? age,
    String? gender,
  }) {
    final userWeight = weight ?? defaultWeight;

    switch (workoutType) {
      case WorkoutType.running:
        return _calculateRunningCalories(
          durationMinutes: durationMinutes,
          distanceKm: distanceKm ?? 0,
          weight: userWeight,
          avgHeartRate: avgHeartRate,
        );

      case WorkoutType.walking:
        return _calculateWalkingCalories(
          durationMinutes: durationMinutes,
          distanceKm: distanceKm ?? 0,
          weight: userWeight,
        );

      case WorkoutType.resistance:
        return _calculateResistanceCalories(
          durationMinutes: durationMinutes,
          weight: userWeight,
          avgHeartRate: avgHeartRate,
        );

      case WorkoutType.cycling:
        return _calculateCyclingCalories(
          durationMinutes: durationMinutes,
          distanceKm: distanceKm ?? 0,
          weight: userWeight,
        );

      case WorkoutType.yoga:
        return _calculateYogaCalories(
          durationMinutes: durationMinutes,
          weight: userWeight,
        );
    }
  }

  /// Calculates calories for running
  int _calculateRunningCalories({
    required int durationMinutes,
    required double distanceKm,
    required double weight,
    int? avgHeartRate,
  }) {
    // MET (Metabolic Equivalent) for running varies by pace
    // Average running: 8-12 METs
    // Formula: Calories = MET × weight(kg) × duration(hours)

    double met = 10.0; // Default MET for moderate running

    if (distanceKm > 0 && durationMinutes > 0) {
      final paceMinPerKm = durationMinutes / distanceKm;

      // Adjust MET based on pace
      if (paceMinPerKm < 5) {
        met = 12.0; // Fast pace
      } else if (paceMinPerKm < 6) {
        met = 10.0; // Moderate pace
      } else {
        met = 8.0; // Slow pace
      }
    }

    final hours = durationMinutes / 60.0;
    return (met * weight * hours).round();
  }

  /// Calculates calories for walking
  int _calculateWalkingCalories({
    required int durationMinutes,
    required double distanceKm,
    required double weight,
  }) {
    // MET for walking: 3-5 depending on pace
    double met = 3.5; // Default MET for moderate walking

    if (distanceKm > 0 && durationMinutes > 0) {
      final paceMinPerKm = durationMinutes / distanceKm;

      if (paceMinPerKm < 12) {
        met = 5.0; // Brisk walking
      } else if (paceMinPerKm < 15) {
        met = 4.0; // Moderate walking
      } else {
        met = 3.0; // Slow walking
      }
    }

    final hours = durationMinutes / 60.0;
    return (met * weight * hours).round();
  }

  /// Calculates calories for resistance training
  int _calculateResistanceCalories({
    required int durationMinutes,
    required double weight,
    int? avgHeartRate,
  }) {
    // MET for resistance training: 5-8 depending on intensity
    double met = 6.0; // Default MET for moderate resistance training

    // Adjust based on heart rate if available
    if (avgHeartRate != null) {
      if (avgHeartRate > 140) {
        met = 8.0; // High intensity
      } else if (avgHeartRate > 120) {
        met = 6.5; // Moderate intensity
      } else {
        met = 5.0; // Low intensity
      }
    }

    final hours = durationMinutes / 60.0;
    return (met * weight * hours).round();
  }

  /// Calculates calories for cycling
  int _calculateCyclingCalories({
    required int durationMinutes,
    required double distanceKm,
    required double weight,
  }) {
    // MET for cycling: 6-12 depending on speed
    double met = 8.0; // Default MET for moderate cycling

    if (distanceKm > 0 && durationMinutes > 0) {
      final speedKmh = (distanceKm / durationMinutes) * 60;

      if (speedKmh > 25) {
        met = 12.0; // Fast cycling
      } else if (speedKmh > 20) {
        met = 10.0; // Moderate-fast cycling
      } else if (speedKmh > 15) {
        met = 8.0; // Moderate cycling
      } else {
        met = 6.0; // Leisurely cycling
      }
    }

    final hours = durationMinutes / 60.0;
    return (met * weight * hours).round();
  }

  /// Calculates calories for yoga
  int _calculateYogaCalories({
    required int durationMinutes,
    required double weight,
  }) {
    // MET for yoga: 2.5-4 depending on intensity
    const double met = 3.0; // Moderate yoga

    final hours = durationMinutes / 60.0;
    return (met * weight * hours).round();
  }

  /// Estimates pace for running based on distance and duration
  double calculatePace({
    required double distanceKm,
    required int durationMinutes,
  }) {
    if (distanceKm <= 0) return 0.0;
    return durationMinutes / distanceKm; // min/km
  }

  /// Estimates target heart rate for a workout
  int calculateTargetHeartRate({
    required int age,
    required double intensity, // 0.0 to 1.0
  }) {
    final maxHR = 220 - age;
    const restingHR = 60; // Average resting heart rate

    // Karvonen formula: Target HR = ((max HR − resting HR) × intensity) + resting HR
    return ((maxHR - restingHR) * intensity + restingHR).round();
  }
}
