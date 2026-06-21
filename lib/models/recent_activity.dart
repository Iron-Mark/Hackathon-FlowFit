import 'package:intl/intl.dart';
import 'mood_rating.dart';

/// Data model representing a recent workout activity
///
/// Contains information about a completed workout including
/// name, type, details, completion date, and mood tracking data.
class RecentActivity {
  /// Unique activity identifier
  final String id;

  /// Activity name (e.g., "Morning Run")
  final String name;

  /// Activity type: 'run', 'walk', 'workout', 'cycle'
  final String type;

  /// Activity details (e.g., "3.2 miles • 30 min")
  final String details;

  /// Activity completion date
  final DateTime date;

  /// Pre-workout mood rating
  final MoodRating? preMood;

  /// Post-workout mood rating
  final MoodRating? postMood;

  /// Mood change (post - pre)
  final int? moodChange;

  RecentActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.details,
    required this.date,
    this.preMood,
    this.postMood,
    this.moodChange,
  }) : assert(
         type == 'run' ||
             type == 'walk' ||
             type == 'workout' ||
             type == 'cycle',
         'Activity type must be one of: run, walk, workout, cycle',
       ),
       assert(
         !date.isAfter(DateTime.now()),
         'Activity date must not be in the future',
       );

  /// Whether this activity has mood tracking data
  bool get hasMoodData => preMood != null && postMood != null;

  /// Whether mood improved during this activity
  bool get hadMoodImprovement => moodChange != null && moodChange! > 0;

  /// Formatted mood boost text
  String get moodBoostText {
    if (moodChange == null || moodChange! <= 0) return '';
    return 'Mood boost: +$moodChange points 🚀';
  }

  /// Formats the date as "Today", "Yesterday", or "MMM d" based on recency
  String get dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(activityDay).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }

  /// Creates a RecentActivity instance from JSON
  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      details: json['details'] as String,
      date: json['date'] is DateTime
          ? json['date'] as DateTime
          : DateTime.parse(json['date'] as String),
      preMood: json['pre_mood'] != null
          ? MoodRating.fromJson(json['pre_mood'] as Map<String, dynamic>)
          : null,
      postMood: json['post_mood'] != null
          ? MoodRating.fromJson(json['post_mood'] as Map<String, dynamic>)
          : null,
      moodChange: json['mood_change'] as int?,
    );
  }

  /// Converts this RecentActivity instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'details': details,
      'date': date.toIso8601String(),
      if (preMood != null) 'pre_mood': preMood!.toJson(),
      if (postMood != null) 'post_mood': postMood!.toJson(),
      if (moodChange != null) 'mood_change': moodChange,
    };
  }

  @override
  String toString() {
    return 'RecentActivity(id: $id, name: $name, type: $type, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecentActivity &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.details == details &&
        other.date == date &&
        other.preMood == preMood &&
        other.postMood == postMood &&
        other.moodChange == moodChange;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      type,
      details,
      date,
      preMood,
      postMood,
      moodChange,
    );
  }
}
