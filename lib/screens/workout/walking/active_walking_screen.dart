import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/walking_session.dart';
import '../../../models/workout_session.dart';
import '../../../providers/walking_session_provider.dart';

/// Active walking session screen with live metrics and session controls.
class ActiveWalkingScreen extends ConsumerWidget {
  const ActiveWalkingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(walkingSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Walking')),
        body: _EmptySessionState(
          title: 'No active walking session',
          message:
              'Start a walk from the workout screen to track distance, time, and steps.',
          onBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    final isPaused = session.status == WorkoutStatus.paused;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F6),
      appBar: AppBar(
        title: Text(
          session.mode == WalkingMode.mission ? 'Map Mission' : 'Walking',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _StatusHeader(session: session, isPaused: isPaused),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Distance',
                    value: session.currentDistance.toStringAsFixed(2),
                    unit: 'km',
                    icon: Icons.route,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: 'Time',
                    value: _formatDuration(session.durationSeconds ?? 0),
                    unit: '',
                    icon: Icons.timer_outlined,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Steps',
                    value: '${session.steps}',
                    unit: '',
                    icon: Icons.directions_walk,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: 'Calories',
                    value: '${session.caloriesBurned ?? 0}',
                    unit: 'kcal',
                    icon: Icons.local_fire_department_outlined,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ProgressPanel(session: session),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final notifier = ref.read(
                        walkingSessionProvider.notifier,
                      );
                      if (isPaused) {
                        await notifier.resumeSession();
                      } else {
                        notifier.pauseSession();
                      }
                    },
                    icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(isPaused ? 'Resume' : 'Pause'),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _confirmEndWorkout(context, ref),
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('End'),
                  style: FilledButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static String _formatPace(WalkingSession session) {
    if (session.currentDistance <= 0 || (session.durationSeconds ?? 0) <= 0) {
      return '--';
    }
    final paceMinutes =
        (session.durationSeconds! / 60) / session.currentDistance;
    final minutes = paceMinutes.floor();
    final seconds = ((paceMinutes - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}/km';
  }

  static Future<void> _confirmEndWorkout(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End walk?'),
        content: const Text(
          'Your walk will be saved before the summary opens.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('End Walk'),
          ),
        ],
      ),
    );

    if (shouldEnd != true || !context.mounted) return;

    final notifier = ref.read(walkingSessionProvider.notifier);
    try {
      await notifier.endSession();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Workout ended, but sync failed. You can retry from summary.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed('/workout/walking/summary');
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.session, required this.isPaused});

  final WalkingSession session;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distanceToTarget = session.distanceToTarget;

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
                  0xFF10B981,
                ).withValues(alpha: 0.12),
                child: const Icon(
                  Icons.directions_walk,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.mode.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isPaused ? 'Paused' : 'Tracking now',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isPaused
                            ? Colors.orange[700]
                            : Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (session.mission != null || session.targetDuration != null) ...[
            const SizedBox(height: 16),
            Text(
              session.mission != null
                  ? distanceToTarget != null
                        ? '${distanceToTarget.round()} m to target'
                        : 'Mission target is ready'
                  : 'Target duration: ${session.targetDuration} min',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.session});

  final WalkingSession session;

  @override
  Widget build(BuildContext context) {
    final routePoints = session.routePoints.length;
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
            'Session details',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Average pace',
            value: ActiveWalkingScreen._formatPace(session),
          ),
          _DetailRow(label: 'GPS points', value: '$routePoints recorded'),
          _DetailRow(
            label: 'Heart rate',
            value: session.avgHeartRate != null
                ? '${session.avgHeartRate} bpm'
                : '--',
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(unit),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptySessionState extends StatelessWidget {
  const _EmptySessionState({
    required this.title,
    required this.message,
    required this.onBack,
  });

  final String title;
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_walk, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
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
