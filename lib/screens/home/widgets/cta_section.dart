import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/workout_flow_provider.dart';
import '../../../widgets/quick_mood_check_bottom_sheet.dart';

/// CTASection widget displays unified workout entry point
///
/// Shows:
/// - Section header "Ready to move?"
/// - Single primary button "START WORKOUT"
///
/// Navigation:
/// - START WORKOUT -> Opens mood check bottom sheet
///
/// Requirements: 1.1, 1.2, 1.5
class CTASection extends ConsumerWidget {
  const CTASection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Ready to move?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Single unified START WORKOUT button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                ref.read(workoutFlowProvider.notifier).startWorkoutFlow();

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (bottomSheetContext) => QuickMoodCheckBottomSheet(
                    onMoodSelected: () {
                      // Navigate to workout type selection after mood is selected
                      // Use the original context which has Navigator
                      Navigator.of(context).pushNamed('/workout/select-type');
                    },
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6), // Primary blue
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'START WORKOUT',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Wellness Tracker button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/wellness-tracker');
              },
              icon: const Icon(Icons.favorite, size: 20),
              label: Text(
                'Wellness Tracker',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444), // Red for heart
                side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Map missions entry point.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/mission');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10B981), // Green
                side: const BorderSide(color: Color(0xFF10B981), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Map Missions',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
