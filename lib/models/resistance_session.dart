import 'workout_session.dart';
import 'mood_rating.dart';
import 'exercise_progress.dart';

/// Body split enumeration
enum BodySplit {
  upper,
  lower;

  String get displayName {
    switch (this) {
      case BodySplit.upper:
        return 'Upper Body';
      case BodySplit.lower:
        return 'Lower Body';
    }
  }

  String get focus {
    switch (this) {
      case BodySplit.upper:
        return 'Chest, Back, Shoulders, Arms';
      case BodySplit.lower:
        return 'Quads, Hamstrings, Glutes, Calves';
    }
  }
}

/// Resistance training workout session
///
/// Extends WorkoutSession with resistance-specific fields including
/// exercise tracking, rest timers, and volume calculations.
class ResistanceSession extends WorkoutSession {
  /// Body split (upper or lower)
  final BodySplit split;

  /// List of exercises with progress tracking
  final List<ExerciseProgress> exercises;

  /// Rest timer duration in seconds (60, 90, or 120)
  final int restTimerSeconds;

  /// Whether audio cues are enabled
  final bool audioCuesEnabled;

  /// Whether heart rate monitor is enabled
  final bool hrMonitorEnabled;

  /// Total volume in kilograms (sum of sets × reps × weight)
  final double? totalVolumeKg;

  /// Time under tension in seconds
  final int? timeUnderTension;

  ResistanceSession({
    required super.id,
    required super.userId,
    required super.startTime,
    required this.split,
    required this.exercises,
    this.restTimerSeconds = 90,
    this.audioCuesEnabled = true,
    this.hrMonitorEnabled = false,
    this.totalVolumeKg,
    this.timeUnderTension,
    super.endTime,
    super.durationSeconds,
    super.preMood,
    super.postMood,
    super.moodChange,
    super.avgHeartRate,
    super.maxHeartRate,
    super.heartRateZones,
    super.caloriesBurned,
    super.status,
  }) : assert(
         restTimerSeconds == 60 ||
             restTimerSeconds == 90 ||
             restTimerSeconds == 120,
         'Rest timer must be 60, 90, or 120 seconds',
       ),
       super(type: WorkoutType.resistance);

  /// Number of completed exercises
  int get completedExercises => exercises.where((e) => e.isComplete).length;

  /// Total number of exercises
  int get totalExercises => exercises.length;

  /// Progress percentage (0.0 to 1.0)
  double get progressPercentage =>
      totalExercises > 0 ? completedExercises / totalExercises : 0.0;

  /// Creates a copy with updated fields
  ResistanceSession copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    BodySplit? split,
    List<ExerciseProgress>? exercises,
    int? restTimerSeconds,
    bool? audioCuesEnabled,
    bool? hrMonitorEnabled,
    double? totalVolumeKg,
    int? timeUnderTension,
    DateTime? endTime,
    int? durationSeconds,
    MoodRating? preMood,
    MoodRating? postMood,
    int? moodChange,
    int? avgHeartRate,
    int? maxHeartRate,
    Map<String, int>? heartRateZones,
    int? caloriesBurned,
    WorkoutStatus? status,
  }) {
    return ResistanceSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      split: split ?? this.split,
      exercises: exercises ?? this.exercises,
      restTimerSeconds: restTimerSeconds ?? this.restTimerSeconds,
      audioCuesEnabled: audioCuesEnabled ?? this.audioCuesEnabled,
      hrMonitorEnabled: hrMonitorEnabled ?? this.hrMonitorEnabled,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
      timeUnderTension: timeUnderTension ?? this.timeUnderTension,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      preMood: preMood ?? this.preMood,
      postMood: postMood ?? this.postMood,
      moodChange: moodChange ?? this.moodChange,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      heartRateZones: heartRateZones ?? this.heartRateZones,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'workout_type': 'resistance',
      'workout_subtype': split.name,
      'start_time': startTime.toIso8601String(),
      'exercises_completed': exercises.map((e) => e.toJson()).toList(),
      'rest_timer_seconds': restTimerSeconds,
      'audio_cues_enabled': audioCuesEnabled,
      'hr_monitor_enabled': hrMonitorEnabled,
      if (totalVolumeKg != null) 'total_volume_kg': totalVolumeKg,
      if (timeUnderTension != null) 'time_under_tension': timeUnderTension,
      if (endTime != null) 'end_time': endTime!.toIso8601String(),
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (preMood != null) 'pre_workout_mood': preMood!.value,
      if (preMood != null) 'pre_workout_mood_emoji': preMood!.emoji,
      if (postMood != null) 'post_workout_mood': postMood!.value,
      if (postMood != null) 'post_workout_mood_emoji': postMood!.emoji,
      if (moodChange != null) 'mood_change': moodChange,
      if (avgHeartRate != null) 'avg_heart_rate': avgHeartRate,
      if (maxHeartRate != null) 'max_heart_rate': maxHeartRate,
      if (heartRateZones != null) 'heart_rate_zones': heartRateZones,
      if (caloriesBurned != null) 'calories_burned': caloriesBurned,
      'status': status.name,
    };
  }

  /// Creates a ResistanceSession from JSON
  factory ResistanceSession.fromJson(Map<String, dynamic> json) {
    return ResistanceSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      split: _bodySplitFromJson(json['workout_subtype']),
      exercises: (json['exercises_completed'] as List<dynamic>)
          .map((e) => ExerciseProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
      restTimerSeconds: json['rest_timer_seconds'] as int? ?? 90,
      audioCuesEnabled: json['audio_cues_enabled'] as bool? ?? true,
      hrMonitorEnabled: json['hr_monitor_enabled'] as bool? ?? false,
      totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble(),
      timeUnderTension: json['time_under_tension'] as int?,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int?,
      preMood: json['pre_workout_mood'] != null
          ? MoodRating.fromValue(json['pre_workout_mood'] as int)
          : null,
      postMood: json['post_workout_mood'] != null
          ? MoodRating.fromValue(json['post_workout_mood'] as int)
          : null,
      moodChange: json['mood_change'] as int?,
      avgHeartRate: json['avg_heart_rate'] as int?,
      maxHeartRate: json['max_heart_rate'] as int?,
      heartRateZones: json['heart_rate_zones'] != null
          ? Map<String, int>.from(json['heart_rate_zones'] as Map)
          : null,
      caloriesBurned: json['calories_burned'] as int?,
      status: WorkoutStatus.values.byName(json['status'] as String),
    );
  }
}

BodySplit _bodySplitFromJson(Object? value) {
  if (value is String) {
    for (final split in BodySplit.values) {
      if (split.name == value) {
        return split;
      }
    }
  }
  return BodySplit.upper;
}
