import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/exercise_progress.dart';
import '../../../models/resistance_session.dart';
import '../../../providers/resistance_session_provider.dart';
import '../../../widgets/mood_transformation_card.dart';
import 'resistance_exercise_icons.dart';

class ResistanceSummaryScreen extends ConsumerWidget {
  const ResistanceSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(resistanceSessionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text('Workout Complete'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: session == null
            ? _EmptySummaryState(onDone: () => _returnHome(context))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _CompletionHeader(session: session),
                  const SizedBox(height: 20),
                  MoodTransformationCard(
                    preMood: session.preMood,
                    postMood: session.postMood,
                    moodChange: session.moodChange,
                  ),
                  const SizedBox(height: 20),
                  _MetricGrid(session: session),
                  const SizedBox(height: 20),
                  _ExerciseBreakdown(session: session),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _retrySync(context, ref),
                    icon: const Icon(Icons.sync),
                    label: const Text('Retry Sync'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _returnHome(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Back to Dashboard'),
                  ),
                ],
              ),
      ),
    );
  }

  static void _returnHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static Future<void> _retrySync(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(resistanceSessionProvider.notifier).retrySaveSession();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Workout sync failed. Check your connection and retry.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Workout synced.')));
  }

  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static String formatWeight(double? value) {
    if (value == null) return '--';
    if (value == value.roundToDouble()) {
      return '${value.round()} kg';
    }
    return '${value.toStringAsFixed(1)} kg';
  }
}

class _CompletionHeader extends StatelessWidget {
  const _CompletionHeader({required this.session});

  final ResistanceSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(
                  0xFF10B981,
                ).withValues(alpha: 0.12),
                child: const Icon(
                  Icons.verified_outlined,
                  color: Color(0xFF10B981),
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${session.split.displayName} complete',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      session.split.focus,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: session.progressPercentage,
              minHeight: 8,
              backgroundColor: const Color(0xFFEDE9FE),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF7C3AED),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${session.completedExercises}/${session.totalExercises} exercises completed',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.session});

  final ResistanceSession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryMetric(
                label: 'Duration',
                value: ResistanceSummaryScreen.formatDuration(
                  session.durationSeconds ?? 0,
                ),
                icon: Icons.timer_outlined,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryMetric(
                label: 'Volume',
                value: ResistanceSummaryScreen.formatWeight(
                  session.totalVolumeKg,
                ),
                icon: Icons.fitness_center,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryMetric(
                label: 'Calories',
                value: '${session.caloriesBurned ?? 0} kcal',
                icon: Icons.local_fire_department_outlined,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryMetric(
                label: 'Avg heart rate',
                value: session.avgHeartRate != null
                    ? '${session.avgHeartRate} bpm'
                    : '--',
                icon: Icons.favorite_border,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

class _ExerciseBreakdown extends StatelessWidget {
  const _ExerciseBreakdown({required this.session});

  final ResistanceSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exercise breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final exercise in session.exercises)
            _ExerciseSummaryRow(exercise: exercise),
        ],
      ),
    );
  }
}

class _ExerciseSummaryRow extends StatelessWidget {
  const _ExerciseSummaryRow({required this.exercise});

  final ExerciseProgress exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                resistanceExerciseIcon(exercise),
                color: const Color(0xFF7C3AED),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  exercise.exerciseName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${exercise.completedSets.length}/${exercise.totalSets}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (exercise.completedSets.isEmpty)
                const _SetChip(label: 'No recorded sets')
              else
                for (
                  var index = 0;
                  index < exercise.completedSets.length;
                  index++
                )
                  _SetChip(
                    label: _setLabel(index, exercise.completedSets[index]),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  static String _setLabel(int index, SetData set) {
    final weight = set.weight == null
        ? 'bodyweight'
        : ResistanceSummaryScreen.formatWeight(set.weight);
    return 'Set ${index + 1}: ${set.reps} reps, $weight';
  }
}

class _SetChip extends StatelessWidget {
  const _SetChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: const Color(0xFFF3E8FF),
      labelStyle: const TextStyle(color: Color(0xFF5B21B6)),
      side: BorderSide.none,
    );
  }
}

class _EmptySummaryState extends StatelessWidget {
  const _EmptySummaryState({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fitness_center, size: 56),
            const SizedBox(height: 16),
            Text(
              'No completed workout available',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Finish a resistance workout to review exercise and mood results.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onDone,
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
