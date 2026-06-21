import 'package:flutter/material.dart';
import '../models/mood_rating.dart';

/// Compact mood change badge showing pre → post mood emojis
///
/// Used in activity cards to show mood transformation.
/// Requirements: 12.3
class MoodChangeBadge extends StatelessWidget {
  final MoodRating? preMood;
  final MoodRating? postMood;

  const MoodChangeBadge({super.key, this.preMood, this.postMood});

  @override
  Widget build(BuildContext context) {
    // Don't show if no mood data
    if (preMood == null || postMood == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(preMood!.emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Icon(
          Icons.arrow_forward_rounded,
          size: 12,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(postMood!.emoji, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
