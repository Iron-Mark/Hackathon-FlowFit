import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/exercise_progress.dart';
import '../../../models/resistance_session.dart';
import '../../../providers/resistance_session_provider.dart';
import 'resistance_exercise_icons.dart';

/// Active resistance workout screen with exercise progress and session controls.
class ActiveResistanceScreen extends ConsumerStatefulWidget {
  const ActiveResistanceScreen({super.key});

  @override
  ConsumerState<ActiveResistanceScreen> createState() =>
      _ActiveResistanceScreenState();

  static String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _ActiveResistanceScreenState
    extends ConsumerState<ActiveResistanceScreen> {
  bool _isConfirmingEndWorkout = false;
  bool _isEndingWorkout = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(resistanceSessionProvider);
    final notifier = ref.read(resistanceSessionProvider.notifier);
    final currentExercise = notifier.currentExercise;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resistance Training')),
        body: _EmptyResistanceState(onBack: () => Navigator.of(context).pop()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text('Resistance Training'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _WorkoutHeader(session: session),
            const SizedBox(height: 20),
            if (currentExercise == null)
              _CompletionPanel(session: session)
            else
              _ExercisePanel(
                exercise: currentExercise,
                isResting: notifier.isResting,
                onCompleteSet: () => notifier.completeSet(),
                onSkipRest: () => notifier.skipRest(),
              ),
            const SizedBox(height: 20),
            _ExerciseList(session: session),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: _isConfirmingEndWorkout || _isEndingWorkout
                  ? null
                  : _confirmEndWorkout,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('End Workout'),
              style: FilledButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmEndWorkout() async {
    if (_isConfirmingEndWorkout || _isEndingWorkout) return;

    setState(() {
      _isConfirmingEndWorkout = true;
    });

    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End workout?'),
        content: const Text(
          'Your completed sets will be saved before the summary opens.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('End Workout'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    setState(() {
      _isConfirmingEndWorkout = false;
    });

    if (shouldEnd == true) {
      await _endWorkout();
    }
  }

  Future<void> _endWorkout() async {
    if (_isEndingWorkout) return;

    setState(() {
      _isEndingWorkout = true;
    });

    final notifier = ref.read(resistanceSessionProvider.notifier);
    try {
      await notifier.endWorkout();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Workout ended, but sync failed. You can retry from summary.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/workout/resistance/summary');
  }
}

class _WorkoutHeader extends StatelessWidget {
  const _WorkoutHeader({required this.session});

  final ResistanceSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
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
                radius: 24,
                backgroundColor: const Color(
                  0xFF7C3AED,
                ).withValues(alpha: 0.12),
                child: const Icon(
                  Icons.fitness_center,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.split.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
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
            '${session.completedExercises}/${session.totalExercises} exercises complete',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercisePanel extends StatelessWidget {
  const _ExercisePanel({
    required this.exercise,
    required this.isResting,
    required this.onCompleteSet,
    required this.onSkipRest,
  });

  final ExerciseProgress exercise;
  final bool isResting;
  final VoidCallback onCompleteSet;
  final VoidCallback onSkipRest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current exercise',
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF7C3AED),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                resistanceExerciseIcon(exercise),
                color: const Color(0xFF7C3AED),
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exercise.exerciseName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Set ${exercise.currentSet.clamp(1, exercise.totalSets)} of ${exercise.totalSets} • ${exercise.targetReps} reps',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 18),
          if (isResting)
            FilledButton.tonalIcon(
              onPressed: onSkipRest,
              icon: const Icon(Icons.timer_off_outlined),
              label: const Text('Skip Rest'),
            )
          else
            FilledButton.icon(
              onPressed: onCompleteSet,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Complete Set'),
            ),
        ],
      ),
    );
  }
}

class _CompletionPanel extends StatelessWidget {
  const _CompletionPanel({required this.session});

  final ResistanceSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_outlined,
            color: Color(0xFF10B981),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            'All programmed exercises are complete.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Duration: ${ActiveResistanceScreen._formatDuration(session.durationSeconds ?? 0)}',
          ),
        ],
      ),
    );
  }
}

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.session});

  final ResistanceSession session;

  @override
  Widget build(BuildContext context) {
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
            'Exercise plan',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final exercise in session.exercises)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    resistanceExerciseIcon(exercise),
                    color: const Color(0xFF7C3AED),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(exercise.exerciseName)),
                  Text(
                    '${exercise.completedSets.length}/${exercise.totalSets}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyResistanceState extends StatelessWidget {
  const _EmptyResistanceState({required this.onBack});

  final VoidCallback onBack;

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
              'No active resistance workout',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a split and start a workout before tracking sets.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onBack,
              child: const Text('Back to workouts'),
            ),
          ],
        ),
      ),
    );
  }
}
