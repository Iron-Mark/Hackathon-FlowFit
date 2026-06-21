/// Data model representing daily fitness statistics
///
/// Contains current progress toward daily fitness goals including
/// steps, calories burned, and active minutes.
class DailyStats {
  /// Current step count for the day
  final int steps;

  /// Daily step goal
  final int stepsGoal;

  /// Calories burned today
  final int calories;

  /// Active minutes today
  final int activeMinutes;

  DailyStats({
    required this.steps,
    required this.stepsGoal,
    required this.calories,
    required this.activeMinutes,
  }) : assert(steps >= 0, 'Steps must be non-negative'),
       assert(stepsGoal > 0, 'Steps goal must be positive'),
       assert(calories >= 0, 'Calories must be non-negative'),
       assert(activeMinutes >= 0, 'Active minutes must be non-negative');

  /// Calculates progress toward step goal as a value between 0.0 and 1.0
  double get stepsProgress => steps / stepsGoal;

  /// Creates a DailyStats instance from JSON
  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      steps: json['steps'] as int? ?? 0,
      stepsGoal: json['stepsGoal'] as int? ?? 10000,
      calories: json['calories'] as int? ?? 0,
      activeMinutes: json['activeMinutes'] as int? ?? 0,
    );
  }

  /// Converts this DailyStats instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'steps': steps,
      'stepsGoal': stepsGoal,
      'calories': calories,
      'activeMinutes': activeMinutes,
    };
  }

  @override
  String toString() {
    return 'DailyStats(steps: $steps/$stepsGoal, calories: $calories, activeMinutes: $activeMinutes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyStats &&
        other.steps == steps &&
        other.stepsGoal == stepsGoal &&
        other.calories == calories &&
        other.activeMinutes == activeMinutes;
  }

  @override
  int get hashCode {
    return Object.hash(steps, stepsGoal, calories, activeMinutes);
  }
}
