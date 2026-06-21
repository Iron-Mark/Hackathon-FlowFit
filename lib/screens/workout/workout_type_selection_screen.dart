import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../models/workout_session.dart';
import '../../providers/workout_flow_provider.dart';

/// Workout type selection screen
///
/// Displays three workout type cards: Running, Walking, Resistance Training
/// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7
class WorkoutTypeSelectionScreen extends ConsumerWidget {
  const WorkoutTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Choose Your Workout',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Running Card
            WorkoutTypeCard(
              type: WorkoutType.running,
              icon: SolarIconsBold.running,
              gradient: const [
                Color(0xFF3B82F6),
                Color(0xFF06B6D4),
              ], // blue to cyan
              estimatedDuration: '45-60 min',
              estimatedCalories: '400 cal',
              benefits: 'Improve cardiovascular health and endurance',
              onTap: () {
                ref
                    .read(workoutFlowProvider.notifier)
                    .selectWorkoutType(WorkoutType.running);
                Navigator.of(context).pushNamed('/workout/running/setup');
              },
            ),
            const SizedBox(height: 24),

            // Walking Card
            WorkoutTypeCard(
              type: WorkoutType.walking,
              icon: SolarIconsBold.walking,
              gradient: const [
                Color(0xFF10B981),
                Color(0xFF059669),
              ], // green to emerald
              estimatedDuration: '30-45 min',
              estimatedCalories: '150 cal',
              benefits: 'Low-impact exercise for daily movement',
              onTap: () {
                ref
                    .read(workoutFlowProvider.notifier)
                    .selectWorkoutType(WorkoutType.walking);
                Navigator.of(context).pushNamed('/workout/walking/options');
              },
            ),
            const SizedBox(height: 24),

            // Resistance Training Card
            WorkoutTypeCard(
              type: WorkoutType.resistance,
              icon: SolarIconsBold.dumbbells,
              gradient: const [
                Color(0xFFEF4444),
                Color(0xFFF97316),
              ], // red to orange
              estimatedDuration: '45-60 min',
              estimatedCalories: '400 cal',
              benefits: 'Build strength and muscle definition',
              onTap: () {
                ref
                    .read(workoutFlowProvider.notifier)
                    .selectWorkoutType(WorkoutType.resistance);
                Navigator.of(
                  context,
                ).pushNamed('/workout/resistance/select-split');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Workout type card widget
class WorkoutTypeCard extends StatelessWidget {
  final WorkoutType type;
  final IconData icon;
  final List<Color> gradient;
  final String estimatedDuration;
  final String estimatedCalories;
  final String benefits;
  final VoidCallback onTap;

  const WorkoutTypeCard({
    super.key,
    required this.type,
    required this.icon,
    required this.gradient,
    required this.estimatedDuration,
    required this.estimatedCalories,
    required this.benefits,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Select ${type.displayName} workout',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Type name
              Text(
                type.displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Metrics row
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _WorkoutMetric(
                    icon: Icons.access_time,
                    label: estimatedDuration,
                  ),
                  _WorkoutMetric(
                    icon: Icons.local_fire_department,
                    label: estimatedCalories,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Benefits text
              Text(
                benefits,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutMetric extends StatelessWidget {
  const _WorkoutMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
