import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wellness_state.dart';
import '../../providers/wellness_state_provider.dart';
import '../../providers/step_counter_provider.dart';
import '../../providers/running_session_provider.dart';
import '../../widgets/wellness/wellness_state_card.dart';
import '../../widgets/wellness/wellness_map_widget.dart';
import '../../widgets/wellness/wellness_stats_card.dart';
import '../../widgets/wellness/stress_alert_banner.dart';
import '../../widgets/wellness/cardio_detection_banner.dart';
import '../../widgets/wellness/wellness_debug_panel.dart';
import '../../services/phone_step_counter_service.dart';
import '../../services/wellness_state_service.dart';
import 'wellness_onboarding_screen.dart';

typedef WellnessOnboardingCompletionChecker = Future<bool> Function();
typedef WellnessTrackerLifecycleAction = Future<void> Function();

/// Main wellness tracker page
class WellnessTrackerPage extends ConsumerStatefulWidget {
  const WellnessTrackerPage({
    super.key,
    this.hasCompletedOnboarding,
    this.startMonitoring,
    this.stopMonitoring,
    this.startStepCounting,
    this.stopStepCounting,
  });

  final WellnessOnboardingCompletionChecker? hasCompletedOnboarding;
  final WellnessTrackerLifecycleAction? startMonitoring;
  final WellnessTrackerLifecycleAction? stopMonitoring;
  final WellnessTrackerLifecycleAction? startStepCounting;
  final WellnessTrackerLifecycleAction? stopStepCounting;

  @override
  ConsumerState<WellnessTrackerPage> createState() =>
      _WellnessTrackerPageState();
}

class _WellnessTrackerPageState extends ConsumerState<WellnessTrackerPage> {
  bool _isInitializing = true;
  String? _errorMessage;
  bool _showStressBanner = false;
  bool _showCardioBanner = false;
  DateTime? _lastStressAlert;
  WellnessStateService? _wellnessStateService;
  PhoneStepCounterService? _phoneStepCounterService;

  @override
  void initState() {
    super.initState();
    _checkOnboardingAndInitialize();
  }

  Future<void> _checkOnboardingAndInitialize() async {
    // Check if onboarding has been completed
    final hasCompleted =
        await (widget.hasCompletedOnboarding ??
            WellnessOnboardingScreen.hasCompletedOnboarding)();

    if (!mounted) {
      return;
    }

    if (!hasCompleted) {
      // Navigate to onboarding
      Navigator.of(context).pushReplacementNamed('/wellness-onboarding');
      return;
    }

    _initializeMonitoring();
  }

  Future<void> _initializeMonitoring() async {
    try {
      debugPrint('WellnessTrackerPage: Initializing monitoring...');

      // Initialize the notifier first (this subscribes to the service)
      ref.read(wellnessStateProvider.notifier);
      debugPrint('WellnessTrackerPage: Notifier initialized');

      // Start the wellness state service
      if (widget.startMonitoring != null) {
        await widget.startMonitoring!();
      } else {
        final service = ref.read(wellnessStateServiceProvider);
        _wellnessStateService = service;
        await service.startMonitoring();
      }
      debugPrint('WellnessTrackerPage: Wellness service started');

      // Start phone step counting
      if (widget.startStepCounting != null) {
        await widget.startStepCounting!();
      } else {
        final phoneStepCounter = ref.read(phoneStepCounterServiceProvider);
        _phoneStepCounterService = phoneStepCounter;
        await phoneStepCounter.startCounting();
      }
      debugPrint('WellnessTrackerPage: Phone step counter started');

      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('WellnessTrackerPage: Initialization failed: $e');
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to start monitoring: $e';
      });
    }
  }

  @override
  void dispose() {
    if (widget.stopMonitoring != null) {
      unawaited(
        widget.stopMonitoring!().catchError((Object error, StackTrace stack) {
          debugPrint('WellnessTrackerPage: stopMonitoring failed: $error');
        }),
      );
    } else if (_wellnessStateService != null) {
      unawaited(
        _wellnessStateService!.stopMonitoring().catchError((
          Object error,
          StackTrace stack,
        ) {
          debugPrint('WellnessTrackerPage: stopMonitoring failed: $error');
        }),
      );
    }

    if (widget.stopStepCounting != null) {
      unawaited(
        widget.stopStepCounting!().catchError((Object error, StackTrace stack) {
          debugPrint('WellnessTrackerPage: stopCounting failed: $error');
        }),
      );
    } else if (_phoneStepCounterService != null) {
      unawaited(
        _phoneStepCounterService!.stopCounting().catchError((
          Object error,
          StackTrace stack,
        ) {
          debugPrint('WellnessTrackerPage: stopCounting failed: $error');
        }),
      );
    }

    super.dispose();
  }

  void _handleStateChange(WellnessState state) {
    // Show stress banner (rate limited to once per 30 minutes)
    if (state == WellnessState.stress) {
      final now = DateTime.now();
      if (_lastStressAlert == null ||
          now.difference(_lastStressAlert!).inMinutes >= 30) {
        setState(() {
          _showStressBanner = true;
          _lastStressAlert = now;
        });

        // Auto-dismiss after 5 minutes
        Future.delayed(const Duration(minutes: 5), () {
          if (mounted) {
            setState(() => _showStressBanner = false);
          }
        });
      }
    }

    // Show cardio banner
    if (state == WellnessState.cardio) {
      setState(() => _showCardioBanner = true);
    } else {
      setState(() => _showCardioBanner = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wellnessState = ref.watch(wellnessStateProvider);

    // Listen for state changes
    ref.listen<WellnessStateData>(wellnessStateProvider, (previous, next) {
      if (previous?.state != next.state) {
        _handleStateChange(next.state);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD),
      appBar: AppBar(
        title: const Text(
          'Wellness Tracker',
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/wellness-settings');
            },
          ),
        ],
      ),
      body: _buildBody(wellnessState),
    );
  }

  Widget _buildBody(WellnessStateData wellnessState) {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Connecting to sensors...',
              style: TextStyle(fontFamily: 'GeneralSans', fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Connection Error',
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Troubleshooting tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                      'Troubleshooting Tips:',
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTroubleshootingItem(
                      'Check if your watch is connected',
                    ),
                    _buildTroubleshootingItem(
                      'Ensure body sensors permission is granted',
                    ),
                    _buildTroubleshootingItem(
                      'Try restarting the watch connection',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Go Back'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _isInitializing = true;
                      });
                      _initializeMonitoring();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Retry Connection'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              // State Card with live heart rate
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildLiveStateCard(wellnessState),
              ),

              // Step Counter Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStepCounterCard(),
              ),

              const SizedBox(height: 16),

              // Map View
              SizedBox(
                height: 300,
                child: WellnessMapWidget(state: wellnessState.state),
              ),

              // Stats Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: WellnessStatsCard(),
              ),

              // Debug: Raw sensor data display
              if (kDebugMode)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSensorDebugCard(),
                ),
            ],
          ),
        ),

        // Stress Alert Banner
        if (_showStressBanner)
          StressAlertBanner(
            onShowRoutes: () {
              setState(() => _showStressBanner = false);
              // Map will automatically show routes
            },
            onDismiss: () {
              setState(() => _showStressBanner = false);
            },
            onSnooze: () {
              setState(() => _showStressBanner = false);
              _lastStressAlert = DateTime.now();
            },
          ),

        // Cardio Detection Banner
        if (_showCardioBanner)
          CardioDetectionBanner(
            heartRate: wellnessState.heartRate ?? 0,
            onStartWorkout: (activityType) {
              Navigator.pushNamed(
                context,
                '/workout/select-type',
                arguments: {
                  'activityType': activityType,
                  'startTime': DateTime.now(),
                },
              );
            },
            onDismiss: () {
              setState(() => _showCardioBanner = false);
            },
          ),

        // Debug Panel (only in debug mode)
        if (kDebugMode) const WellnessDebugPanel(),
      ],
    );
  }

  /// Builds state card with live heart rate updates
  Widget _buildLiveStateCard(WellnessStateData wellnessState) {
    return StreamBuilder(
      stream: ref.read(phoneDataListenerServiceProvider).heartRateStream,
      builder: (context, hrSnapshot) {
        // Create updated state data with latest heart rate
        final liveState = WellnessStateData(
          state: wellnessState.state,
          timestamp: wellnessState.timestamp,
          heartRate: hrSnapshot.hasData
              ? hrSnapshot.data!.bpm
              : wellnessState.heartRate,
          motionMagnitude: wellnessState.motionMagnitude,
          confidence: wellnessState.confidence,
        );

        return WellnessStateCard(state: liveState);
      },
    );
  }

  /// Builds step counter card
  Widget _buildStepCounterCard() {
    final stepCount = ref.watch(totalStepsProvider);

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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_walk,
              size: 32,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Steps Today',
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stepCount.toString(),
                  style: const TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(stepCounterServiceProvider).resetSteps();
            },
            tooltip: 'Reset steps',
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorDebugCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔬 Sensor Data Debug',
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder(
            stream: ref.read(phoneDataListenerServiceProvider).heartRateStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final hr = snapshot.data!;
                return Text(
                  '💓 Heart Rate: ${hr.bpm} BPM (${hr.status.name})',
                  style: const TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 12,
                  ),
                );
              }
              return const Text('💓 Heart Rate: Waiting...');
            },
          ),
          const SizedBox(height: 8),
          StreamBuilder(
            stream: ref
                .read(phoneDataListenerServiceProvider)
                .sensorBatchStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final batch = snapshot.data!;
                return Text(
                  '📊 Sensor Batch: ${batch.sampleCount} samples',
                  style: const TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 12,
                  ),
                );
              }
              return const Text('📊 Sensor Batch: Waiting...');
            },
          ),
        ],
      ),
    );
  }
}
