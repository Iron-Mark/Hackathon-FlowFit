/// Data model representing a mood rating on a 5-point scale
///
/// Used for pre and post-workout mood tracking to measure
/// the emotional impact of exercise.
class MoodRating {
  /// Mood value on 1-5 scale
  /// 1 = Very Bad, 2 = Bad, 3 = Neutral, 4 = Good, 5 = Energized
  final int value;

  /// Emoji representation of mood
  /// 😢 😕 😐 🙂 💪
  final String emoji;

  /// Timestamp when mood was recorded
  final DateTime timestamp;

  /// Optional notes about the mood
  final String? notes;

  MoodRating({
    required this.value,
    required this.emoji,
    required this.timestamp,
    this.notes,
  }) : assert(value >= 1 && value <= 5, 'Mood value must be between 1 and 5');

  /// Creates a MoodRating from a numeric value (1-5)
  factory MoodRating.fromValue(int value, {String? notes}) {
    const emojiMap = {1: '😢', 2: '😕', 3: '😐', 4: '🙂', 5: '💪'};

    return MoodRating(
      value: value,
      emoji: emojiMap[value]!,
      timestamp: DateTime.now(),
      notes: notes,
    );
  }

  /// Creates a MoodRating instance from JSON
  factory MoodRating.fromJson(Map<String, dynamic> json) {
    return MoodRating(
      value: json['value'] as int,
      emoji: json['emoji'] as String,
      timestamp: json['timestamp'] is DateTime
          ? json['timestamp'] as DateTime
          : DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
    );
  }

  /// Converts this MoodRating instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'emoji': emoji,
      'timestamp': timestamp.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }

  @override
  String toString() {
    return 'MoodRating(value: $value, emoji: $emoji, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoodRating &&
        other.value == value &&
        other.emoji == emoji &&
        other.timestamp == timestamp &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(value, emoji, timestamp, notes);
  }
}
