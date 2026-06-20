import 'mood_rating.dart';
import 'resistance_session.dart';
import 'running_session.dart';
import 'walking_session.dart';

/// Workout type enumeration
enum WorkoutType {
  running,
  walking,
  resistance,
  cycling,
  yoga;

  String get displayName {
    switch (this) {
      case WorkoutType.running:
        return 'Running';
      case WorkoutType.walking:
        return 'Walking';
      case WorkoutType.resistance:
        return 'Resistance Training';
      case WorkoutType.cycling:
        return 'Cycling';
      case WorkoutType.yoga:
        return 'Yoga';
    }
  }
}

/// Workout status enumeration
enum WorkoutStatus {
  active,
  paused,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case WorkoutStatus.active:
        return 'Active';
      case WorkoutStatus.paused:
        return 'Paused';
      case WorkoutStatus.completed:
        return 'Completed';
      case WorkoutStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Base class for all workout sessions
///
/// Contains common fields shared across all workout types including
/// timing, mood tracking, heart rate metrics, and calories.
abstract class WorkoutSession {
  /// Unique session identifier
  final String id;

  /// User ID who performed the workout
  final String userId;

  /// Type of workout
  final WorkoutType type;

  /// When the workout started
  final DateTime startTime;

  /// When the workout ended (null if still active)
  final DateTime? endTime;

  /// Total duration in seconds
  final int? durationSeconds;

  /// Pre-workout mood rating
  final MoodRating? preMood;

  /// Post-workout mood rating
  final MoodRating? postMood;

  /// Mood change (post - pre)
  final int? moodChange;

  /// Average heart rate during workout
  final int? avgHeartRate;

  /// Maximum heart rate during workout
  final int? maxHeartRate;

  /// Time spent in each heart rate zone (zone name -> seconds)
  final Map<String, int>? heartRateZones;

  /// Total calories burned
  final int? caloriesBurned;

  /// Current workout status
  final WorkoutStatus status;

  WorkoutSession({
    required this.id,
    required this.userId,
    required this.type,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    this.preMood,
    this.postMood,
    this.moodChange,
    this.avgHeartRate,
    this.maxHeartRate,
    this.heartRateZones,
    this.caloriesBurned,
    this.status = WorkoutStatus.active,
  });

  /// Converts this WorkoutSession to JSON
  Map<String, dynamic> toJson();

  /// Creates a WorkoutSession from JSON
  static WorkoutSession fromJson(Map<String, dynamic> json) {
    final rawType = json['workout_type'] ?? json['type'];
    final type = rawType is String ? rawType.toLowerCase() : null;

    switch (type) {
      case 'running':
      case 'run':
        return RunningSession.fromJson(json);
      case 'walking':
      case 'walk':
        return WalkingSession.fromJson(json);
      case 'resistance':
      case 'workout':
      case 'strength':
        return ResistanceSession.fromJson(json);
      default:
        throw FormatException(
          'Unsupported workout session type: ${rawType ?? 'missing'}',
        );
    }
  }
}
