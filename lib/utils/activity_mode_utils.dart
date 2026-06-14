import '../models/activity_mode_detection.dart';

/// Utility functions for processing AI activity mode detection data
class ActivityModeUtils {
  /// Calculates average probabilities from detection history
  ///
  /// Returns [avgStress, avgCardio, avgStrength]
  static List<double> calculateAvgProbabilities(
    List<ActivityModeDetection> history,
  ) {
    if (history.isEmpty) return [0.0, 0.0, 0.0];

    double sumStress = 0;
    double sumCardio = 0;
    double sumStrength = 0;

    for (final detection in history) {
      if (detection.probabilities.length >= 3) {
        sumStress += detection.probabilities[0];
        sumCardio += detection.probabilities[1];
        sumStrength += detection.probabilities[2];
      }
    }

    final count = history.length;
    return [sumStress / count, sumCardio / count, sumStrength / count];
  }

  /// Determines the dominant (most frequent) activity mode
  ///
  /// Returns the mode name that appeared most often in the history
  static String calculateDominantMode(List<ActivityModeDetection> history) {
    if (history.isEmpty) return 'Unknown';

    final modeCounts = <String, int>{};

    for (final detection in history) {
      modeCounts[detection.mode] = (modeCounts[detection.mode] ?? 0) + 1;
    }

    return modeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Calculates the percentage of time spent in each mode
  ///
  /// Returns a map: {'Stress': 0.15, 'Cardio': 0.72, 'Strength': 0.13}
  static Map<String, double> calculateModePercentages(
    List<ActivityModeDetection> history,
  ) {
    if (history.isEmpty) {
      return {'Stress': 0.0, 'Cardio': 0.0, 'Strength': 0.0};
    }

    final modeCounts = <String, int>{};

    for (final detection in history) {
      modeCounts[detection.mode] = (modeCounts[detection.mode] ?? 0) + 1;
    }

    final total = history.length;
    return modeCounts.map((mode, count) => MapEntry(mode, count / total));
  }

  /// Gets the color associated with an activity mode
  static String getModeColorHex(String mode) {
    switch (mode) {
      case 'Stress':
        return '#EF4444'; // Red
      case 'Cardio':
        return '#F97316'; // Orange
      case 'Strength':
        return '#10B981'; // Green
      default:
        return '#6B7280'; // Gray
    }
  }

  /// Gets the icon name associated with an activity mode
  static String getModeIcon(String mode) {
    switch (mode) {
      case 'Stress':
        return 'danger';
      case 'Cardio':
        return 'heart_pulse';
      case 'Strength':
        return 'leaf';
      default:
        return 'question';
    }
  }

  /// Gets a human-readable description of the mode
  static String getModeDescription(String mode) {
    switch (mode) {
      case 'Stress':
        return 'High intensity - Consider slowing down';
      case 'Cardio':
        return 'Optimal cardio zone - Great pace!';
      case 'Strength':
        return 'Low intensity - You can push harder';
      default:
        return 'Unknown activity mode';
    }
  }

  /// Filters detections within a time range
  static List<ActivityModeDetection> filterByTimeRange(
    List<ActivityModeDetection> history,
    DateTime start,
    DateTime end,
  ) {
    return history
        .where((d) => d.timestamp.isAfter(start) && d.timestamp.isBefore(end))
        .toList();
  }

  /// Groups detections by minute intervals
  ///
  /// Returns a map where keys are minute timestamps and values are lists of detections
  static Map<DateTime, List<ActivityModeDetection>> groupByMinute(
    List<ActivityModeDetection> history,
  ) {
    final grouped = <DateTime, List<ActivityModeDetection>>{};

    for (final detection in history) {
      final minuteKey = DateTime(
        detection.timestamp.year,
        detection.timestamp.month,
        detection.timestamp.day,
        detection.timestamp.hour,
        detection.timestamp.minute,
      );

      grouped.putIfAbsent(minuteKey, () => []).add(detection);
    }

    return grouped;
  }

  /// Calculates mode transitions (how many times mode changed)
  static int calculateModeTransitions(List<ActivityModeDetection> history) {
    if (history.length < 2) return 0;

    int transitions = 0;
    for (int i = 1; i < history.length; i++) {
      if (history[i].mode != history[i - 1].mode) {
        transitions++;
      }
    }

    return transitions;
  }

  /// Gets the most confident detection
  static ActivityModeDetection? getMostConfidentDetection(
    List<ActivityModeDetection> history,
  ) {
    if (history.isEmpty) return null;

    return history.reduce((a, b) => a.confidence > b.confidence ? a : b);
  }

  /// Gets the least confident detection
  static ActivityModeDetection? getLeastConfidentDetection(
    List<ActivityModeDetection> history,
  ) {
    if (history.isEmpty) return null;

    return history.reduce((a, b) => a.confidence < b.confidence ? a : b);
  }

  /// Calculates average confidence across all detections
  static double calculateAvgConfidence(List<ActivityModeDetection> history) {
    if (history.isEmpty) return 0.0;

    final sum = history.fold<double>(
      0.0,
      (sum, detection) => sum + detection.confidence,
    );

    return sum / history.length;
  }

  /// Exports detection history to CSV format
  static String exportToCSV(List<ActivityModeDetection> history) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(
      'Timestamp,Mode,Confidence,Stress%,Cardio%,Strength%,HeartRate',
    );

    // Data rows
    for (final detection in history) {
      buffer.writeln(
        '${detection.timestamp.toIso8601String()},'
        '${detection.mode},'
        '${detection.confidence},'
        '${detection.probabilities[0]},'
        '${detection.probabilities[1]},'
        '${detection.probabilities[2]},'
        '${detection.heartRate ?? ""}',
      );
    }

    return buffer.toString();
  }

  /// Creates a summary text for sharing
  static String createSummaryText(
    List<ActivityModeDetection> history,
    int workoutDurationMinutes,
  ) {
    if (history.isEmpty) return 'No AI activity data available';

    final dominant = calculateDominantMode(history);
    final percentages = calculateModePercentages(history);
    final avgConfidence = calculateAvgConfidence(history);
    final transitions = calculateModeTransitions(history);

    return '''
🤖 AI Activity Analysis

Dominant Mode: $dominant
Detection Count: ${history.length}
Workout Duration: $workoutDurationMinutes min

Mode Distribution:
• Stress: ${(percentages['Stress']! * 100).toStringAsFixed(1)}%
• Cardio: ${(percentages['Cardio']! * 100).toStringAsFixed(1)}%
• Strength: ${(percentages['Strength']! * 100).toStringAsFixed(1)}%

Average Confidence: ${(avgConfidence * 100).toStringAsFixed(1)}%
Mode Transitions: $transitions
''';
  }
}
