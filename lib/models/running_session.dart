import 'package:latlong2/latlong.dart';
import 'workout_session.dart';
import 'mood_rating.dart';
import 'activity_mode_detection.dart';

/// Goal type for running workouts
enum GoalType {
  distance,
  duration;

  String get displayName {
    switch (this) {
      case GoalType.distance:
        return 'Distance';
      case GoalType.duration:
        return 'Duration';
    }
  }
}

/// Running workout session with GPS tracking
///
/// Extends WorkoutSession with running-specific fields including
/// distance, pace, route tracking, and elevation data.
class RunningSession extends WorkoutSession {
  /// Type of goal (distance or duration based)
  final GoalType goalType;

  /// Target distance in kilometers (if distance goal)
  final double? targetDistance;

  /// Target duration in minutes (if duration goal)
  final int? targetDuration;

  /// Current distance covered in kilometers
  final double currentDistance;

  /// Average pace in minutes per kilometer
  final double? avgPace;

  /// GPS route points
  final List<LatLng> routePoints;

  /// Encoded route polyline for storage
  final String? routePolyline;

  /// Total elevation gain in meters
  final int? elevationGain;

  /// Total steps counted during workout
  final int? steps;

  /// AI Activity mode detections throughout workout
  final List<ActivityModeDetection>? activityModeHistory;

  /// Average activity mode probabilities [stress, cardio, strength]
  final List<double>? avgActivityProbabilities;

  /// Dominant activity mode during workout
  final String? dominantActivityMode;

  RunningSession({
    required super.id,
    required super.userId,
    required super.startTime,
    required this.goalType,
    this.targetDistance,
    this.targetDuration,
    this.currentDistance = 0.0,
    this.avgPace,
    this.routePoints = const [],
    this.routePolyline,
    this.elevationGain,
    this.steps,
    this.activityModeHistory,
    this.avgActivityProbabilities,
    this.dominantActivityMode,
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
  }) : super(type: WorkoutType.running);

  /// Calculates progress percentage toward goal (0.0 to 1.0)
  double get progressPercentage {
    if (goalType == GoalType.distance && targetDistance != null) {
      return (currentDistance / targetDistance!).clamp(0.0, 1.0);
    } else if (goalType == GoalType.duration &&
        targetDuration != null &&
        durationSeconds != null) {
      return (durationSeconds! / (targetDuration! * 60)).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  /// Creates a copy with updated fields
  RunningSession copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    GoalType? goalType,
    double? targetDistance,
    int? targetDuration,
    double? currentDistance,
    double? avgPace,
    List<LatLng>? routePoints,
    String? routePolyline,
    int? elevationGain,
    int? steps,
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
    return RunningSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      goalType: goalType ?? this.goalType,
      targetDistance: targetDistance ?? this.targetDistance,
      targetDuration: targetDuration ?? this.targetDuration,
      currentDistance: currentDistance ?? this.currentDistance,
      avgPace: avgPace ?? this.avgPace,
      routePoints: routePoints ?? this.routePoints,
      routePolyline: routePolyline ?? this.routePolyline,
      elevationGain: elevationGain ?? this.elevationGain,
      steps: steps ?? this.steps,
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
      'workout_type': 'running',
      'start_time': startTime.toIso8601String(),
      'goal_type': goalType.name,
      if (targetDistance != null) 'target_distance': targetDistance,
      if (targetDuration != null) 'target_duration': targetDuration,
      'current_distance': currentDistance,
      if (avgPace != null) 'avg_pace': avgPace,
      if (routePolyline != null) 'route_polyline': routePolyline,
      if (elevationGain != null) 'elevation_gain_m': elevationGain,
      if (steps != null) 'steps': steps,
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

  /// Creates a RunningSession from JSON
  factory RunningSession.fromJson(Map<String, dynamic> json) {
    return RunningSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      goalType: GoalType.values.byName(json['goal_type'] as String),
      targetDistance: (json['target_distance'] as num?)?.toDouble(),
      targetDuration: json['target_duration'] as int?,
      currentDistance: (json['current_distance'] as num?)?.toDouble() ?? 0.0,
      avgPace: (json['avg_pace'] as num?)?.toDouble(),
      routePolyline: json['route_polyline'] as String?,
      elevationGain: json['elevation_gain_m'] as int?,
      steps: json['steps'] as int?,
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
