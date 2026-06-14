import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/walking_session.dart';
import '../../../models/mission.dart';
import '../../../providers/walking_session_provider.dart';
import '../../../providers/workout_flow_provider.dart';
import 'mission_creation_screen.dart';
import 'active_walking_screen.dart';

/// Walking options screen with Free Walk and Map Mission cards
/// Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6
class WalkingOptionsScreen extends ConsumerStatefulWidget {
  const WalkingOptionsScreen({super.key});

  @override
  ConsumerState<WalkingOptionsScreen> createState() =>
      _WalkingOptionsScreenState();
}

class _WalkingOptionsScreenState extends ConsumerState<WalkingOptionsScreen> {
  int _targetDuration = 30; // Default 30 minutes
  MissionType _selectedMissionType = MissionType.target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Choose Walking Mode'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Free Walk Card
            _buildFreeWalkCard(theme),
            const SizedBox(height: 24),

            // Map Mission Card
            _buildMapMissionCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeWalkCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_walk,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Free Walk', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Casual walk with GPS tracking',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Duration Slider
            Text('Target Duration', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _targetDuration.toDouble(),
                    min: 10,
                    max: 120,
                    divisions: 22, // (120-10)/5 = 22 steps
                    label: '$_targetDuration min',
                    onChanged: (value) {
                      setState(() {
                        // Round to nearest 5 minutes
                        _targetDuration = (value / 5).round() * 5;
                      });
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_targetDuration min',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Start Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _startFreeWalk(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                ),
                child: const Text('Start Free Walk'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapMissionCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon, Title, and NEW Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Map Mission',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(width: 8),
                          // NEW Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'NEW',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Walk to a specific location',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Mission Type Selector
            Text('Mission Type', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...MissionType.values.map(
              (type) => _buildMissionTypeOption(theme, type),
            ),
            const SizedBox(height: 24),

            // Create Mission Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _createMission(context),
                child: const Text('Create Mission'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionTypeOption(ThemeData theme, MissionType type) {
    final isSelected = _selectedMissionType == type;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMissionType = type;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startFreeWalk(BuildContext context) async {
    // Get pre-mood from workout flow provider
    final preMood = ref.read(workoutFlowProvider).preMood;

    try {
      // Start free walk session
      await ref
          .read(walkingSessionProvider.notifier)
          .startSession(
            mode: WalkingMode.free,
            targetDuration: _targetDuration,
            preMood: preMood,
          );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not start walking. Sign in and check your connection, then try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ActiveWalkingScreen()),
      );
    }
  }

  void _createMission(BuildContext context) {
    // Get pre-mood from workout flow provider
    final preMood = ref.read(workoutFlowProvider).preMood;

    // Navigate to mission creation screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MissionCreationScreen(
          missionType: _selectedMissionType,
          preMood: preMood,
        ),
      ),
    );
  }
}
