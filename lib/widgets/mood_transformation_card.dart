import 'package:flutter/material.dart';
import '../models/mood_rating.dart';

/// Mood transformation card showing pre/post workout mood change
///
/// Displays mood improvement with gradient background and celebration text.
/// Requirements: 11.1, 11.2
class MoodTransformationCard extends StatelessWidget {
  final MoodRating? preMood;
  final MoodRating? postMood;
  final int? moodChange;

  const MoodTransformationCard({
    super.key,
    this.preMood,
    this.postMood,
    this.moodChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Don't show if no mood data
    if (preMood == null || postMood == null) {
      return const SizedBox.shrink();
    }

    // Determine gradient colors based on mood change
    final gradientColors = _getGradientColors(moodChange ?? 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mood Transformation',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Text('🚀', style: TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 20),

          // Mood change visualization
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pre-mood
              Text(preMood!.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 16),

              // Arrow
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 32,
              ),
              const SizedBox(width: 16),

              // Post-mood
              Text(postMood!.emoji, style: const TextStyle(fontSize: 48)),
            ],
          ),
          const SizedBox(height: 16),

          // Mood change text
          Text(
            _getMoodChangeText(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(int change) {
    if (change > 0) {
      // Positive change - green gradient
      return [const Color(0xFF10B981), const Color(0xFF059669)];
    } else if (change < 0) {
      // Negative change - orange gradient
      return [const Color(0xFFF59E0B), const Color(0xFFEF4444)];
    } else {
      // No change - blue gradient
      return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
    }
  }

  String _getMoodChangeText() {
    if (moodChange == null) return 'Mood tracked';

    if (moodChange! > 0) {
      return '+$moodChange points improvement!';
    } else if (moodChange! < 0) {
      return '$moodChange points change';
    } else {
      return 'Mood stayed consistent';
    }
  }
}
