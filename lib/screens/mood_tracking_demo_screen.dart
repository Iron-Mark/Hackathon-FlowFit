import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/quick_mood_check_bottom_sheet.dart';
import '../widgets/post_workout_mood_check.dart';
import '../widgets/mood_change_badge.dart';
import '../widgets/mood_transformation_card.dart';
import '../models/mood_rating.dart';

/// Demo screen to test mood tracking UI components
///
/// This screen is for development/testing purposes only.
class MoodTrackingDemoScreen extends ConsumerWidget {
  const MoodTrackingDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Sample mood data for testing
    final preMood = MoodRating.fromValue(3); // Neutral
    final postMood = MoodRating.fromValue(5); // Energized
    const moodChange = 2;

    return Scaffold(
      appBar: AppBar(title: const Text('Mood Tracking Components Demo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section: Bottom Sheet
            Text(
              'Quick Mood Check Bottom Sheet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to show pre-workout mood check',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const QuickMoodCheckBottomSheet(),
                );
              },
              child: const Text('Show Pre-Workout Mood Check'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      const QuickMoodCheckBottomSheet(isPostWorkout: true),
                );
              },
              child: const Text('Show Post-Workout Mood Check (Bottom Sheet)'),
            ),
            const SizedBox(height: 32),

            // Section: Mood Change Badge
            Text('Mood Change Badge', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Compact badge for activity cards',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Morning Run', style: theme.textTheme.titleMedium),
                  MoodChangeBadge(preMood: preMood, postMood: postMood),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section: Mood Transformation Card
            Text('Mood Transformation Card', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Full-width card for workout summaries',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            MoodTransformationCard(
              preMood: preMood,
              postMood: postMood,
              moodChange: moodChange,
            ),
            const SizedBox(height: 16),

            // Different mood changes
            Text('No Change Example', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            MoodTransformationCard(
              preMood: MoodRating.fromValue(4),
              postMood: MoodRating.fromValue(4),
              moodChange: 0,
            ),
            const SizedBox(height: 16),

            Text('Negative Change Example', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            MoodTransformationCard(
              preMood: MoodRating.fromValue(4),
              postMood: MoodRating.fromValue(2),
              moodChange: -2,
            ),
            const SizedBox(height: 32),

            // Section: Post-Workout Screen
            Text(
              'Post-Workout Mood Check Screen',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Full-screen post-workout mood check',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PostWorkoutMoodCheck(
                      sessionId: 'demo-session-123',
                    ),
                  ),
                );
              },
              child: const Text('Show Post-Workout Screen'),
            ),
            const SizedBox(height: 32),

            // Testing notes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Testing Notes',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Emoji buttons have 56x56 dp touch targets\n'
                    '• Scale animation plays on tap (1.0 → 1.2 → 1.0)\n'
                    '• Pre-workout timer: 10 seconds\n'
                    '• Post-workout timer: 15 seconds\n'
                    '• Auto-selects neutral (3) if no selection\n'
                    '• Gradient colors change based on mood change',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
