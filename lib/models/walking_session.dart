import 'package:latlong2/latlong.dart';
import 'workout_session.dart';
import 'mood_rating.dart';
import 'mission.dart';

/// Walking mode enumeration
enum WalkingMode {
  free,
  mission;

  String get displayName {
    switch (this) {
      case WalkingMode.free:
        return 'Free Walk';
      case WalkingMode.mission:
        return 'Map Mission';
    }
  }
}

/// Walking workout session with optional mission tracking
///
/// Extends WorkoutSession with walking-specific fields including
/// steps, distance, route tracking, and optional mission data.
class WalkingSession extends WorkoutSession {
  /// Walking mode (free or mission-based)
  final WalkingMode mode;

  /// Target duration in minutes (for free walk)
  final int? targetDuration;

  /// Current distance covered in kilometers
  final double currentDistance;

  /// Step count
  final int steps;

  /// GPS route points
  final List<LatLng> routePoints;

  /// Encoded route polyline for storage
  final String? routePolyline;

  /// Active mission (if mission mode)
  final Mission? mission;

  /// Whether mission was completed
  final bool missionCompleted;

  WalkingSession({
    required super.id,
    required super.userId,
    required super.startTime,
    required this.mode,
    this.targetDuration,
    this.currentDistance = 0.0,
    this.steps = 0,
    this.routePoints = const [],
    this.routePolyline,
    this.mission,
    this.missionCompleted = false,
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
  }) : super(type: WorkoutType.walking);

  /// Calculates distance to mission target in meters
  double? get distanceToTarget {
    if (mission != null && routePoints.isNotEmpty) {
      return _calculateDistance(routePoints.last, mission!.targetLocation);
    }
    return null;
  }

  /// Calculates distance between two GPS coordinates in meters
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  /// Creates a copy with updated fields
  WalkingSession copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    WalkingMode? mode,
    int? targetDuration,
    double? currentDistance,
    int? steps,
    List<LatLng>? routePoints,
    String? routePolyline,
    Mission? mission,
    bool? missionCompleted,
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
    return WalkingSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      mode: mode ?? this.mode,
      targetDuration: targetDuration ?? this.targetDuration,
      currentDistance: currentDistance ?? this.currentDistance,
      steps: steps ?? this.steps,
      routePoints: routePoints ?? this.routePoints,
      routePolyline: routePolyline ?? this.routePolyline,
      mission: mission ?? this.mission,
      missionCompleted: missionCompleted ?? this.missionCompleted,
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
      'workout_type': 'walking',
      'start_time': startTime.toIso8601String(),
      'mode': mode.name,
      if (targetDuration != null) 'target_duration': targetDuration,
      'current_distance': currentDistance,
      'steps': steps,
      if (routePolyline != null) 'route_polyline': routePolyline,
      if (mission != null) 'mission_id': mission!.id,
      'mission_completed': missionCompleted,
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

  /// Creates a WalkingSession from JSON
  factory WalkingSession.fromJson(Map<String, dynamic> json) {
    return WalkingSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      mode: json['mode'] != null
          ? WalkingMode.values.byName(json['mode'] as String)
          : WalkingMode.free,
      targetDuration: json['target_duration'] as int?,
      currentDistance: (json['current_distance'] as num?)?.toDouble() ?? 0.0,
      steps: json['steps'] as int? ?? 0,
      routePolyline: json['route_polyline'] as String?,
      mission: json['mission'] != null
          ? Mission.fromJson(json['mission'] as Map<String, dynamic>)
          : null,
      missionCompleted: json['mission_completed'] as bool? ?? false,
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
