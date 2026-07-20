import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:solar_icons/solar_icons.dart';
// Hide running_session_provider's own phoneDataListenerProvider so this
// screen reads the activity-classifier chain's listener (the instance the
// retired ActivityClassifierScope used to supply).
import 'package:flowfit/providers/running_session_provider.dart'
    hide phoneDataListenerProvider;
import 'package:flowfit/models/workout_session.dart';
import 'package:flowfit/features/activity_classifier/presentation/providers.dart';
import 'package:flowfit/screens/workout/running/running_activity_detection.dart';
import 'package:flowfit/screens/workout/running/widgets/activity_ai_overlay.dart';
import 'package:flowfit/screens/workout/running/widgets/running_map_view.dart';
import 'package:flowfit/screens/workout/running/widgets/running_metric_tiles.dart';

/// Active running screen with real-time GPS tracking and metrics
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8
class ActiveRunningScreen extends ConsumerStatefulWidget {
  final String? sessionId;

  const ActiveRunningScreen({super.key, this.sessionId});

  @override
  ConsumerState<ActiveRunningScreen> createState() =>
      _ActiveRunningScreenState();
}

class _ActiveRunningScreenState extends ConsumerState<ActiveRunningScreen> {
  MapController? _mapController;
  bool _hasStartedDetection = false;
  bool _isConfirmingEndWorkout = false;
  bool _isEndingWorkout = false;

  // AI continuous-detection pipeline (sensor buffer, timers, subscriptions)
  RunningActivityDetection? _activityDetection;

  // Real-time heart rate from watch
  int? _currentHeartRate;

  @override
  void initState() {
    super.initState();
    // Start continuous detection after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_hasStartedDetection) {
        _hasStartedDetection = true;
        _startContinuousDetection();
      }
    });
  }

  void _startContinuousDetection() {
    final detection = RunningActivityDetection(
      classifier: ref.read(tfliteActivityClassifierProvider),
      phoneDataListener: ref.read(phoneDataListenerProvider),
      // The detection pipeline runs from Timer and stream callbacks across
      // async gaps; using ref after this ConsumerState is disposed throws, so
      // return null once unmounted and the pipeline skips that pass.
      readViewModel: () =>
          mounted ? ref.read(activityClassifierViewModelProvider) : null,
      onHeartRate: (heartRateData) {
        if (mounted) {
          setState(() {
            _currentHeartRate = heartRateData.bpm;
          });
          debugPrint('💓 Live HR from watch: ${heartRateData.bpm} bpm');
        }
      },
    );
    _activityDetection = detection;
    detection.start();
  }

  @override
  void dispose() {
    // Stop continuous detection when leaving screen
    _activityDetection?.dispose();
    _mapController?.dispose();
    super.dispose();
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

  Future<void> _showEndWorkoutDialog() async {
    if (_isConfirmingEndWorkout || _isEndingWorkout) return;

    setState(() {
      _isConfirmingEndWorkout = true;
    });

    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Workout?'),
        content: const Text('Are you sure you want to end this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
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

    final notifier = ref.read(runningSessionProvider.notifier);
    try {
      await notifier.endSession();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Workout ended, but sync failed. You can retry from summary.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/workout/running/summary');
  }

  void _showWorkoutMenu(dynamic session) {
    final isPaused = session.status == WorkoutStatus.paused;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isPaused
                      ? SolarIconsBold.playCircle
                      : SolarIconsBold.pauseCircle,
                ),
                title: Text(isPaused ? 'Resume workout' : 'Pause workout'),
                onTap: () async {
                  Navigator.of(context).pop();

                  final notifier = ref.read(runningSessionProvider.notifier);
                  if (isPaused) {
                    await notifier.resumeSession();
                  } else {
                    notifier.pauseSession();
                  }
                },
              ),
              ListTile(
                leading: const Icon(SolarIconsBold.cpu),
                title: const Text('Open AI tracker'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(this.context).pushNamed('/activity-classifier');
                },
              ),
              ListTile(
                leading: const Icon(SolarIconsOutline.flag, color: Colors.red),
                title: const Text('End workout'),
                textColor: Colors.red,
                onTap: () {
                  Navigator.of(context).pop();
                  _showEndWorkoutDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(runningSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Running')),
        body: const Center(child: Text('No active session')),
      );
    }

    final isPaused = session.status == WorkoutStatus.paused;
    final currentLocation = session.routePoints.isNotEmpty
        ? session.routePoints.last
        : null;

    final viewModel = ref.watch(activityClassifierViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Full-screen map as background
            RunningMapView(
              routePoints: session.routePoints,
              currentLocation: currentLocation,
              resolveMapController: () => _mapController ??= MapController(),
            ),

            // Gradient overlay for better readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.2, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Content overlay
            Column(
              children: [
                // Header with controls
                _buildHeader(theme, session, isPaused),

                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Activity mode badge (always show)
                          ActivityModeBadge(viewModel: viewModel),

                          // AI Metrics breakdown (show when detected)
                          if (viewModel.currentActivity != null)
                            AiMetricsBreakdown(viewModel: viewModel),

                          const SizedBox(height: 16),

                          // Bottom metrics panel
                          _buildBottomMetricsPanel(theme, session),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, dynamic session, bool isPaused) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              SolarIconsOutline.altArrowLeft,
              color: Colors.white,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              minimumSize: const Size(44, 44),
            ),
          ),

          const Spacer(),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isPaused
                  ? Colors.orange.withValues(alpha: 0.9)
                  : Colors.green.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPaused
                      ? SolarIconsBold.pauseCircle
                      : SolarIconsBold.playCircle,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isPaused ? 'PAUSED' : 'RUNNING',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Debug button - Navigate to AI Tracker
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/activity-classifier');
            },
            icon: const Icon(SolarIconsBold.cpu, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.8),
              minimumSize: const Size(44, 44),
            ),
          ),

          const SizedBox(width: 8),

          // Menu button
          IconButton(
            onPressed: () => _showWorkoutMenu(session),
            icon: const Icon(SolarIconsOutline.menuDots, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              minimumSize: const Size(44, 44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomMetricsPanel(ThemeData theme, dynamic session) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary metrics row
          Row(
            children: [
              Expanded(
                child: RunningLargeMetric(
                  label: 'Distance',
                  value: _formatDistance(session.currentDistance),
                  unit: 'km',
                  icon: SolarIconsBold.routing2, // Road/path icon
                  color: const Color(0xFF3B82F6),
                ),
              ),
              Container(width: 1, height: 60, color: Colors.grey[300]),
              Expanded(
                child: RunningLargeMetric(
                  label: 'Time',
                  value: _formatTime(session.durationSeconds),
                  unit: '',
                  icon: SolarIconsBold.clockCircle, // Clock = time (universal)
                  color: const Color(0xFFFF9800),
                ),
              ),
              Container(width: 1, height: 60, color: Colors.grey[300]),
              Expanded(
                child: RunningLargeMetric(
                  label: 'Speed',
                  value: _formatPace(session.avgPace),
                  unit: '/km',
                  icon: SolarIconsBold.speedometerMiddle, // Speedometer
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Secondary metrics row
          Row(
            children: [
              RunningSmallMetric(
                label: 'Heart',
                value: _currentHeartRate != null
                    ? '$_currentHeartRate'
                    : (session.avgHeartRate != null
                          ? '${session.avgHeartRate}'
                          : '--'),
                unit: 'bpm',
                icon: SolarIconsBold.heart, // Simple heart
                color: const Color(0xFFE91E63),
                isLive: _currentHeartRate != null,
              ),
              const SizedBox(width: 12),
              RunningSmallMetric(
                label: 'Calories',
                value: session.caloriesBurned != null
                    ? '${session.caloriesBurned}'
                    : '--',
                unit: 'kcal',
                icon: SolarIconsBold.fire, // Fire = burning calories
                color: const Color(0xFFFF5722),
              ),
              const SizedBox(width: 12),
              RunningSmallMetric(
                label: 'Steps',
                value: session.steps != null ? '${session.steps}' : '--',
                unit: '',
                icon: SolarIconsBold.runningRound, // Running person
                color: const Color(0xFF2196F3),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Control buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final isPaused = session.status == WorkoutStatus.paused;
                    if (isPaused) {
                      ref.read(runningSessionProvider.notifier).resumeSession();
                    } else {
                      ref.read(runningSessionProvider.notifier).pauseSession();
                    }
                  },
                  icon: Icon(
                    session.status == WorkoutStatus.paused
                        ? SolarIconsBold.play
                        : SolarIconsBold.pause,
                  ),
                  label: Text(
                    session.status == WorkoutStatus.paused ? 'Resume' : 'Pause',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isConfirmingEndWorkout || _isEndingWorkout
                    ? null
                    : _showEndWorkoutDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Icon(SolarIconsBold.stopCircle, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
