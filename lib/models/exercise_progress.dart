/// Data for a completed set
class SetData {
  /// Number of reps completed
  final int reps;

  /// Weight used in kilograms
  final double? weight;

  /// When the set was completed
  final DateTime completedAt;

  SetData({required this.reps, this.weight, required this.completedAt})
    : assert(reps > 0, 'Reps must be positive');

  /// Creates a SetData from JSON
  factory SetData.fromJson(Map<String, dynamic> json) {
    return SetData(
      reps: json['reps'] as int,
      weight: (json['weight'] as num?)?.toDouble(),
      completedAt: json['completed_at'] is DateTime
          ? json['completed_at'] as DateTime
          : DateTime.parse(json['completed_at'] as String),
    );
  }

  /// Converts this SetData to JSON
  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      if (weight != null) 'weight': weight,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SetData(reps: $reps, weight: $weight kg)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SetData &&
        other.reps == reps &&
        other.weight == weight &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode {
    return Object.hash(reps, weight, completedAt);
  }
}

/// Progress tracking for a single exercise
///
/// Tracks sets, reps, and completion status for an exercise
/// within a resistance training workout.
class ExerciseProgress {
  /// Exercise name (e.g., "Bench Press")
  final String exerciseName;

  /// Emoji icon for the exercise
  final String emoji;

  /// Total number of sets to complete
  final int totalSets;

  /// Target reps per set
  final int targetReps;

  /// List of completed sets
  final List<SetData> completedSets;

  ExerciseProgress({
    required this.exerciseName,
    required this.emoji,
    required this.totalSets,
    required this.targetReps,
    this.completedSets = const [],
  }) : assert(totalSets > 0, 'Total sets must be positive'),
       assert(targetReps > 0, 'Target reps must be positive');

  /// Current set number (1-indexed)
  int get currentSet => completedSets.length + 1;

  /// Whether all sets are complete
  bool get isComplete => completedSets.length >= totalSets;

  /// Completes a set with optional custom reps and weight
  ExerciseProgress completeSet({int? reps, double? weight}) {
    final newSet = SetData(
      reps: reps ?? targetReps,
      weight: weight,
      completedAt: DateTime.now(),
    );

    return ExerciseProgress(
      exerciseName: exerciseName,
      emoji: emoji,
      totalSets: totalSets,
      targetReps: targetReps,
      completedSets: [...completedSets, newSet],
    );
  }

  /// Creates an ExerciseProgress from JSON
  factory ExerciseProgress.fromJson(Map<String, dynamic> json) {
    return ExerciseProgress(
      exerciseName: json['exercise_name'] as String,
      emoji: json['emoji'] as String,
      totalSets: json['total_sets'] as int,
      targetReps: json['target_reps'] as int,
      completedSets:
          (json['completed_sets'] as List<dynamic>?)
              ?.map((e) => SetData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Converts this ExerciseProgress to JSON
  Map<String, dynamic> toJson() {
    return {
      'exercise_name': exerciseName,
      'emoji': emoji,
      'total_sets': totalSets,
      'target_reps': targetReps,
      'completed_sets': completedSets.map((s) => s.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'ExerciseProgress($exerciseName: ${completedSets.length}/$totalSets sets)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseProgress &&
        other.exerciseName == exerciseName &&
        other.emoji == emoji &&
        other.totalSets == totalSets &&
        other.targetReps == targetReps &&
        other.completedSets.length == completedSets.length;
  }

  @override
  int get hashCode {
    return Object.hash(
      exerciseName,
      emoji,
      totalSets,
      targetReps,
      completedSets.length,
    );
  }
}
