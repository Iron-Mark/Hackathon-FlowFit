import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wellness_state.dart';
import '../../providers/wellness_state_provider.dart';

/// Card displaying wellness statistics
class WellnessStatsCard extends ConsumerWidget {
  const WellnessStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durations = ref.watch(todayDurationsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Wellness',
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Timeline visualization
          _buildTimeline(durations),

          const SizedBox(height: 20),

          // Duration stats
          _buildDurationStat(
            icon: Icons.spa,
            label: 'Calm',
            duration: durations[WellnessState.calm] ?? Duration.zero,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildDurationStat(
            icon: Icons.fitness_center,
            label: 'Active',
            duration: durations[WellnessState.cardio] ?? Duration.zero,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildDurationStat(
            icon: Icons.warning_amber_rounded,
            label: 'Stress',
            duration: durations[WellnessState.stress] ?? Duration.zero,
            color: Colors.red,
          ),

          const SizedBox(height: 20),

          // Insights
          _buildInsights(durations),
        ],
      ),
    );
  }

  Widget _buildTimeline(Map<WellnessState, Duration> durations) {
    final total = durations.values.fold<Duration>(
      Duration.zero,
      (sum, duration) => sum + duration,
    );

    if (total.inSeconds == 0) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'No data yet',
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            if (durations[WellnessState.calm]!.inSeconds > 0)
              Expanded(
                flex: durations[WellnessState.calm]!.inSeconds,
                child: Container(color: Colors.green),
              ),
            if (durations[WellnessState.cardio]!.inSeconds > 0)
              Expanded(
                flex: durations[WellnessState.cardio]!.inSeconds,
                child: Container(color: Colors.orange),
              ),
            if (durations[WellnessState.stress]!.inSeconds > 0)
              Expanded(
                flex: durations[WellnessState.stress]!.inSeconds,
                child: Container(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationStat({
    required IconData icon,
    required String label,
    required Duration duration,
    required Color color,
  }) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final durationText = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontFamily: 'GeneralSans', fontSize: 14),
          ),
        ),
        Text(
          durationText,
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInsights(Map<WellnessState, Duration> durations) {
    final calmDuration = durations[WellnessState.calm] ?? Duration.zero;
    final stressDuration = durations[WellnessState.stress] ?? Duration.zero;

    String insight;
    IconData icon;
    Color color;

    if (calmDuration.inHours >= 6) {
      insight =
          'Great job! You\'ve been calm for ${calmDuration.inHours} hours today';
      icon = Icons.celebration;
      color = Colors.green;
    } else if (stressDuration.inMinutes > 30) {
      insight = 'Consider taking breaks to manage stress levels';
      icon = Icons.lightbulb_outline;
      color = Colors.orange;
    } else {
      insight = 'Keep monitoring your wellness throughout the day';
      icon = Icons.info_outline;
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight,
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
