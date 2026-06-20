import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../../models/running_session.dart';
import '../../../providers/running_session_provider.dart';
import '../../../providers/workout_flow_provider.dart';

/// Running setup screen with goal selection and target controls.
class RunningSetupScreen extends ConsumerStatefulWidget {
  const RunningSetupScreen({super.key});

  @override
  ConsumerState<RunningSetupScreen> createState() => _RunningSetupScreenState();
}

class _RunningSetupScreenState extends ConsumerState<RunningSetupScreen> {
  GoalType _goalType = GoalType.distance;
  double _targetDistance = 5.0;
  int _targetDuration = 30;
  bool _isStarting = false;

  Future<void> _startRunning() async {
    setState(() => _isStarting = true);

    try {
      // Get pre-workout mood from workout flow
      final workoutFlow = ref.read(workoutFlowProvider);
      final preMood = workoutFlow.preMood;

      // Start the running session
      await ref
          .read(runningSessionProvider.notifier)
          .startSession(
            goalType: _goalType,
            targetDistance: _goalType == GoalType.distance
                ? _targetDistance
                : null,
            targetDuration: _goalType == GoalType.duration
                ? _targetDuration
                : null,
            preMood: preMood,
          );

      if (mounted) {
        // Navigate to active running screen
        Navigator.of(context).pushReplacementNamed('/workout/running/active');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isStarting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not start running. Sign in and check your connection, then try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(SolarIconsOutline.altArrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Running Setup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Set Your Goal',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your running target',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 32),

              // Goal type selection
              Container(
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
                    Text(
                      'Goal Type',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGoalTypeButton(
                            context,
                            'Distance',
                            SolarIconsBold.mapArrowSquare,
                            GoalType.distance,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGoalTypeButton(
                            context,
                            'Duration',
                            SolarIconsBold.clockCircle,
                            GoalType.duration,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Target value
              Container(
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
                    Text(
                      _goalType == GoalType.distance
                          ? 'Target Distance'
                          : 'Target Duration',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _goalType == GoalType.distance
                          ? '${_targetDistance.toStringAsFixed(1)} km'
                          : '$_targetDuration min',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: _goalType == GoalType.distance
                          ? _targetDistance
                          : _targetDuration.toDouble(),
                      min: _goalType == GoalType.distance ? 1.0 : 5.0,
                      max: _goalType == GoalType.distance ? 20.0 : 120.0,
                      divisions: _goalType == GoalType.distance ? 38 : 23,
                      activeColor: const Color(0xFF3B82F6),
                      onChanged: (value) {
                        setState(() {
                          if (_goalType == GoalType.distance) {
                            _targetDistance = value;
                          } else {
                            _targetDuration = value.round();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Start button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isStarting ? null : _startRunning,
                  icon: _isStarting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(SolarIconsBold.play),
                  label: Text(
                    _isStarting ? 'Starting...' : 'Start Running',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalTypeButton(
    BuildContext context,
    String label,
    IconData icon,
    GoalType type,
  ) {
    final isSelected = _goalType == type;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => setState(() => _goalType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
