import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/config/flowfit_runtime_config.dart';
import '../../../widgets/mood_transformation_card.dart';
import '../../../models/walking_session.dart';
import '../../../models/mission.dart';
import '../../../providers/walking_session_provider.dart';
import '../../../providers/running_session_provider.dart'; // For workoutSessionServiceProvider
import 'mission_creation_screen.dart';

/// Walking summary screen with mood transformation, metrics, and map
/// Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.7
class WalkingSummaryScreen extends ConsumerWidget {
  const WalkingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(walkingSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout Complete')),
        body: const Center(child: Text('No session data available')),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Workout Complete'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mood Transformation Card
            MoodTransformationCard(
              preMood: session.preMood,
              postMood: session.postMood,
              moodChange: session.moodChange,
            ),
            const SizedBox(height: 24),

            // Mission Completion Badge
            if (session.missionCompleted) ...[
              _buildMissionCompletionBadge(theme),
              const SizedBox(height: 24),
            ],

            // Primary Metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    'Distance',
                    '${session.currentDistance.toStringAsFixed(2)} km',
                    Icons.straighten,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    'Duration',
                    _formatDuration(session.durationSeconds ?? 0),
                    Icons.timer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricCard(
              theme,
              'Steps',
              '${session.steps}',
              Icons.directions_walk,
            ),
            const SizedBox(height: 24),

            // Map with Route
            if (session.routePoints.isNotEmpty) ...[
              _buildRouteMap(theme, session),
              const SizedBox(height: 24),
            ],

            // Secondary Metrics
            Text('Additional Metrics', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryMetricCard(
                    theme,
                    'Calories',
                    '${session.caloriesBurned ?? 0}',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSecondaryMetricCard(
                    theme,
                    'Avg Pace',
                    _calculateAvgPace(session),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Create Next Mission Button (if mission was completed)
            if (session.missionCompleted) ...[
              OutlinedButton(
                onPressed: () => _createNextMission(context, ref),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Create Next Mission'),
              ),
              const SizedBox(height: 12),
            ],

            // Save to History Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => _saveToHistory(context, ref, session),
                child: const Text('Save to History'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCompletionBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Text(
            'Mission Complete!',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryMetricCard(
    ThemeData theme,
    String label,
    String value,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteMap(ThemeData theme, WalkingSession session) {
    // Calculate bounds to fit entire route
    final bounds = LatLngBounds.fromPoints(session.routePoints);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 300,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(50),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: FlowFitRuntimeConfig.mapTileUrlTemplate,
              subdomains: FlowFitRuntimeConfig.mapTileSubdomains,
              userAgentPackageName: FlowFitRuntimeConfig.authScheme,
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: session.routePoints,
                  color: const Color(0xFF10B981),
                  strokeWidth: 4,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                // Start marker
                if (session.routePoints.isNotEmpty)
                  Marker(
                    point: session.routePoints.first,
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          'S',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                // End marker
                if (session.routePoints.length > 1)
                  Marker(
                    point: session.routePoints.last,
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          'E',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Mission marker
                if (session.mission != null)
                  Marker(
                    point: session.mission!.targetLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _calculateAvgPace(WalkingSession session) {
    if (session.currentDistance == 0 || session.durationSeconds == null) {
      return '--';
    }

    final minutes = session.durationSeconds! / 60.0;
    final paceMinPerKm = minutes / session.currentDistance;
    final paceMin = paceMinPerKm.floor();
    final paceSec = ((paceMinPerKm - paceMin) * 60).round();

    return '$paceMin:${paceSec.toString().padLeft(2, '0')}/km';
  }

  void _createNextMission(BuildContext context, WidgetRef ref) {
    final session = ref.read(walkingSessionProvider);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MissionCreationScreen(
          missionType: session?.mission?.type ?? MissionType.target,
          preMood: null, // New mission, will need new mood check
        ),
      ),
    );
  }

  Future<void> _saveToHistory(
    BuildContext context,
    WidgetRef ref,
    WalkingSession session,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Save session to database
      final sessionService = ref.read(workoutSessionServiceProvider);
      await sessionService.saveSession(session);

      if (context.mounted) {
        // Close loading dialog
        navigator.pop();

        // Return to Track Tab (home)
        navigator.popUntil((route) => route.isFirst);

        // Show success message
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Workout saved successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Close loading dialog
        navigator.pop();

        // Show error message
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error saving workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
