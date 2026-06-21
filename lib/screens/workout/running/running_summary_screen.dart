import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/config/flowfit_runtime_config.dart';
import '../../../widgets/mood_transformation_card.dart';
import '../../../providers/running_session_provider.dart';

/// Running summary screen with mood transformation, metrics, and map
/// Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.7, 14.5
class RunningSummaryScreen extends ConsumerStatefulWidget {
  final String? sessionId;

  const RunningSummaryScreen({super.key, this.sessionId});

  @override
  ConsumerState<RunningSummaryScreen> createState() =>
      _RunningSummaryScreenState();
}

class _RunningSummaryScreenState extends ConsumerState<RunningSummaryScreen> {
  final MapController _mapController = MapController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Fit map to route bounds after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToRoute();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _fitMapToRoute() {
    final session = ref.read(runningSessionProvider);
    if (session == null || session.routePoints.isEmpty) return;

    // Calculate bounds
    double minLat = session.routePoints.first.latitude;
    double maxLat = session.routePoints.first.latitude;
    double minLng = session.routePoints.first.longitude;
    double maxLng = session.routePoints.first.longitude;

    for (final point in session.routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  String _formatTime(int? seconds) {
    if (seconds == null) return '00:00';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDistance(double distance) {
    return distance.toStringAsFixed(2);
  }

  String _formatPace(double? pace) {
    if (pace == null) return '--:--';
    final minutes = pace.floor();
    final seconds = ((pace - minutes) * 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _saveToHistory() async {
    setState(() => _isSaving = true);

    try {
      final session = ref.read(runningSessionProvider);
      if (session != null) {
        await ref.read(workoutSessionServiceProvider).saveSession(session);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout saved successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate back to dashboard (Track Tab)
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareAchievement() async {
    // Navigate to share achievement screen with Strava-style image overlay
    Navigator.of(context).pushNamed(
      '/workout/running/share',
      arguments: {'session': ref.read(runningSessionProvider)},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(runningSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout Complete')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.route_outlined, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'No session data available',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Back to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD),
      appBar: AppBar(
        title: const Text('Workout Complete'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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

            // Primary Metrics
            Row(
              children: [
                Expanded(
                  child: _buildPrimaryMetricCard(
                    theme,
                    'Distance',
                    '${_formatDistance(session.currentDistance)} km',
                    Icons.straighten,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPrimaryMetricCard(
                    theme,
                    'Duration',
                    _formatTime(session.durationSeconds),
                    Icons.timer,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Secondary Metrics Grid
            _buildSecondaryMetrics(theme, session),

            const SizedBox(height: 24),

            // Route Map
            if (session.routePoints.isNotEmpty) ...[
              _buildRouteMap(theme, session),
              const SizedBox(height: 24),
            ],

            // Heart Rate Zones
            if (session.heartRateZones != null &&
                session.heartRateZones!.isNotEmpty) ...[
              _buildHeartRateZones(theme, session),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryMetricCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryMetrics(ThemeData theme, dynamic session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  theme,
                  'Avg Pace',
                  '${_formatPace(session.avgPace)} /km',
                  Icons.speed,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  theme,
                  'Avg HR',
                  session.avgHeartRate != null
                      ? '${session.avgHeartRate} bpm'
                      : '--',
                  Icons.favorite,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  theme,
                  'Calories',
                  session.caloriesBurned != null
                      ? '${session.caloriesBurned} cal'
                      : '--',
                  Icons.local_fire_department,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRouteMap(ThemeData theme, dynamic session) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Your Route',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: Colors.grey[300]!),
            ),
            clipBehavior: Clip.antiAlias,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: session.routePoints.isNotEmpty
                    ? session.routePoints.first
                    : const LatLng(0, 0),
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
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
                      strokeWidth: 4,
                      color: const Color(0xFF3B82F6),
                    ),
                  ],
                ),
                // Start marker
                if (session.routePoints.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: session.routePoints.first,
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      // End marker
                      Marker(
                        point: session.routePoints.last,
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.stop,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateZones(ThemeData theme, dynamic session) {
    final zones = session.heartRateZones!;
    final totalSeconds = zones.values.fold<int>(
      0,
      (int sum, int val) => sum + val,
    );

    if (totalSeconds == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Heart Rate Zones',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...zones.entries.map((entry) {
            final percentage = (entry.value / totalSeconds * 100).round();
            final minutes = entry.value ~/ 60;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getZoneName(entry.key),
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '$minutes min ($percentage%)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getZoneColor(entry.key),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getZoneName(String zone) {
    switch (zone) {
      case 'zone1':
        return 'Zone 1 (50-60%)';
      case 'zone2':
        return 'Zone 2 (60-70%)';
      case 'zone3':
        return 'Zone 3 (70-80%)';
      case 'zone4':
        return 'Zone 4 (80-90%)';
      case 'zone5':
        return 'Zone 5 (90-100%)';
      default:
        return zone;
    }
  }

  Color _getZoneColor(String zone) {
    switch (zone) {
      case 'zone1':
        return Colors.blue;
      case 'zone2':
        return Colors.green;
      case 'zone3':
        return Colors.yellow[700]!;
      case 'zone4':
        return Colors.orange;
      case 'zone5':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: _isSaving ? null : _saveToHistory,
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save to History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _shareAchievement,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.share, color: theme.colorScheme.primary),
            label: Text(
              'Share Achievement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
