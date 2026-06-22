import 'package:flutter/material.dart';

import '../../../models/exercise_progress.dart';

IconData resistanceExerciseIcon(ExerciseProgress exercise) {
  final name = exercise.exerciseName.toLowerCase();

  if (name.contains('bench') || name.contains('incline')) {
    return Icons.fitness_center;
  }
  if (name.contains('shoulder') || name.contains('lateral')) {
    return Icons.accessibility_new;
  }
  if (name.contains('row')) {
    return Icons.rowing;
  }
  if (name.contains('curl')) {
    return Icons.sports_gymnastics;
  }
  if (name.contains('squat') || name.contains('lunge')) {
    return Icons.directions_walk;
  }
  if (name.contains('press') || name.contains('deadlift')) {
    return Icons.fitness_center;
  }
  if (name.contains('calf') || name.contains('leg')) {
    return Icons.directions_run;
  }

  return Icons.fitness_center;
}
