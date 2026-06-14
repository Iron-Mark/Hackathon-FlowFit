import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/resistance_session.dart';
import '../../../models/exercise_progress.dart';
import '../../../providers/resistance_session_provider.dart';
import '../../../providers/workout_flow_provider.dart';

/// Split selection screen for resistance training
/// Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6
class SplitSelectionScreen extends ConsumerStatefulWidget {
  const SplitSelectionScreen({super.key});

  @override
  ConsumerState<SplitSelectionScreen> createState() =>
      _SplitSelectionScreenState();
}

class _SplitSelectionScreenState extends ConsumerState<SplitSelectionScreen> {
  BodySplit? _selectedSplit;
  int _restTimerSeconds = 90;
  bool _audioCuesEnabled = true;
  bool _hrMonitorEnabled = false;
  bool _isStarting = false;

  final List<ExerciseProgress> _upperBodyExercises = [
    ExerciseProgress(
      exerciseName: 'Bench Press',
      emoji: '💪',
      totalSets: 3,
      targetReps: 12,
    ),
    ExerciseProgress(
      exerciseName: 'Incline Press',
      emoji: '🏋️',
      totalSets: 3,
      targetReps: 10,
    ),
    ExerciseProgress(
      exerciseName: 'Shoulder Press',
      emoji: '💪',
      totalSets: 3,
      targetReps: 12,
    ),
    ExerciseProgress(
      exerciseName: 'Lateral Raises',
      emoji: '🔥',
      totalSets: 3,
      targetReps: 15,
    ),
    ExerciseProgress(
      exerciseName: 'Bent Over Rows',
      emoji: '🏋️',
      totalSets: 3,
      targetReps: 12,
    ),
    ExerciseProgress(
      exerciseName: 'Bicep Curls',
      emoji: '💪',
      totalSets: 3,
      targetReps: 12,
    ),
  ];

  final List<ExerciseProgress> _lowerBodyExercises = [
    ExerciseProgress(
      exerciseName: 'Squats',
      emoji: '🦵',
      totalSets: 4,
      targetReps: 12,
    ),
    ExerciseProgress(
      exerciseName: 'Leg Press',
      emoji: '🏋️',
      totalSets: 3,
      targetReps: 15,
    ),
    ExerciseProgress(
      exerciseName: 'Lunges',
      emoji: '🦵',
      totalSets: 3,
      targetReps: 12,
    ),
    ExerciseProgress(
      exerciseName: 'Leg Curls',
      emoji: '🔥',
      totalSets: 3,
      targetReps: 12,
    ),
    ExerciseProgress(
      exerciseName: 'Calf Raises',
      emoji: '🦵',
      totalSets: 4,
      targetReps: 15,
    ),
    ExerciseProgress(
      exerciseName: 'Deadlifts',
      emoji: '🏋️',
      totalSets: 3,
      targetReps: 10,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Choose Your Split'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upper Body Card
            _buildSplitCard(
              context,
              BodySplit.upper,
              '💪',
              const Color(0xFF3B82F6),
              const Color(0xFF2563EB),
              'Chest, Back, Shoulders, Arms',
              '45-60 min',
              '400 cal',
              _upperBodyExercises,
            ),
            const SizedBox(height: 24),

            // Lower Body Card
            _buildSplitCard(
              context,
              BodySplit.lower,
              '🦵',
              const Color(0xFF8B5CF6),
              const Color(0xFF7C3AED),
              'Quads, Hamstrings, Glutes, Calves',
              '50-70 min',
              '500 cal',
              _lowerBodyExercises,
            ),
            const SizedBox(height: 32),

            // Workout Settings
            if (_selectedSplit != null) ...[
              Text(
                'Workout Settings',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Rest Timer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rest Timer',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildRestTimerButton(60),
                        const SizedBox(width: 12),
                        _buildRestTimerButton(90),
                        const SizedBox(width: 12),
                        _buildRestTimerButton(120),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Audio Cues Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Audio Cues',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch(
                      value: _audioCuesEnabled,
                      onChanged: (value) {
                        setState(() => _audioCuesEnabled = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // HR Monitor Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Heart Rate Monitor',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch(
                      value: _hrMonitorEnabled,
                      onChanged: (value) {
                        setState(() => _hrMonitorEnabled = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pro Tip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pro Tip: Start with lighter weight to perfect form',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Start Workout Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isStarting ? null : () => _startWorkout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isStarting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text(
                          'Start Workout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSplitCard(
    BuildContext context,
    BodySplit split,
    String emoji,
    Color color1,
    Color color2,
    String focus,
    String duration,
    String calories,
    List<ExerciseProgress> exercises,
  ) {
    final theme = Theme.of(context);
    final isSelected = _selectedSplit == split;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedSplit = split);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: color1.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    split.displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.white, size: 28),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              focus,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.local_fire_department,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 4),
                Text(
                  calories,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                'Exercises',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...exercises.map(
                (exercise) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        exercise.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exercise.exerciseName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      Text(
                        '${exercise.totalSets} × ${exercise.targetReps}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRestTimerButton(int seconds) {
    final theme = Theme.of(context);
    final isSelected = _restTimerSeconds == seconds;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _restTimerSeconds = seconds);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${seconds}s',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startWorkout(BuildContext context) async {
    final selectedSplit = _selectedSplit;
    if (selectedSplit == null || _isStarting) return;

    final exercises = List<ExerciseProgress>.from(
      selectedSplit == BodySplit.upper
          ? _upperBodyExercises
          : _lowerBodyExercises,
    );
    final preMood = ref.read(workoutFlowProvider).preMood;

    setState(() => _isStarting = true);
    try {
      await ref
          .read(resistanceSessionProvider.notifier)
          .startSession(
            split: selectedSplit,
            exercises: exercises,
            restTimerSeconds: _restTimerSeconds,
            audioCuesEnabled: _audioCuesEnabled,
            hrMonitorEnabled: _hrMonitorEnabled,
            preMood: preMood,
          );
    } catch (_) {
      if (!context.mounted) return;
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not start resistance workout. Sign in and check your connection, then try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).pushNamed('/workout/resistance/active');
  }
}
