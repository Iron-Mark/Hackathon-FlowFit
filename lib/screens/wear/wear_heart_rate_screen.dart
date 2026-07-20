import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wear_plus/wear_plus.dart';

import 'package:flowfit/models/heart_rate_data.dart';
import 'package:flowfit/models/sensor_error.dart';
import 'package:flowfit/models/sensor_error_code.dart';
import 'package:flowfit/models/sensor_status.dart';
import 'package:flowfit/services/sensors/watch_bridge.dart';
import 'package:flowfit/screens/wear/sensor_permission_rationale_screen.dart';
import 'package:flowfit/screens/wear/widgets/wear_hr_controls.dart';
import 'package:flowfit/screens/wear/widgets/wear_hr_display.dart';
import 'package:flowfit/screens/wear/widgets/wear_test_mode_panel.dart';

export 'package:flowfit/screens/wear/wear_colors.dart';

/// Modern Wear OS heart rate monitoring screen
/// Features:
/// - Large BPM display
/// - Real-time monitoring with Samsung Health SDK
/// - One-tap send to phone button
/// - Ambient mode support
/// - Material Design 3 for Wear OS
class WearHeartRateScreen extends StatefulWidget {
  final WearShape shape;
  final WearMode mode;

  const WearHeartRateScreen({
    super.key,
    required this.shape,
    required this.mode,
  });

  @override
  State<WearHeartRateScreen> createState() => _WearHeartRateScreenState();
}

class _WearHeartRateScreenState extends State<WearHeartRateScreen>
    with TickerProviderStateMixin {
  static const String _simulatedFallbackMessage =
      'Samsung Health service unavailable. Showing simulated BPM for emulator/dev.';
  static const String _serviceUnavailableMessage =
      'Samsung Health service unavailable. Use a supported Galaxy Watch for live heart rate.';

  final WatchBridgeService _watchBridge = WatchBridgeService();

  HeartRateData? _currentHeartRate;
  bool _isMonitoring = false;
  bool _isMonitoringBusy = false;
  bool _isConnected = false;
  bool _isSimulatedFallbackAvailable = false;
  bool _isSimulatedHeartRate = false;
  bool _isSending = false;
  String _statusMessage = 'Ready';
  bool _isAccelerometerActive = false;
  String? _errorMessage;

  // Test mode state (Requirements: 8.5)
  bool _isTestMode = false;
  Map<String, dynamic>? _testModeData;
  Timer? _testModeTimer;
  Timer? _statusResetTimer;
  Timer? _simulatedHeartRateTimer;
  int _simulatedTick = 0;

  StreamSubscription? _heartRateSubscription;
  StreamSubscription? _transmissionSubscription;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _transmissionController;
  late Animation<double> _transmissionAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupTransmissionListener();
    _checkConnection();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    // Transmission animation (under 300ms for accessibility - Requirements 5.4, 3.5)
    _transmissionController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _transmissionAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _transmissionController, curve: Curves.easeOut),
    );
  }

  /// Set up listener for sensor batch transmission events
  /// Triggers animation when sensor data is transmitted to phone
  /// Requirements: 5.4, 3.5
  void _setupTransmissionListener() {
    const transmissionChannel = EventChannel('com.flowfit.watch/transmission');

    _transmissionSubscription = transmissionChannel
        .receiveBroadcastStream()
        .listen(
          (event) {
            if (mounted && _isAccelerometerActive) {
              // Trigger transmission animation (scale animation under 300ms)
              _transmissionController.forward(from: 0.0).then((_) {
                if (mounted) {
                  _transmissionController.reverse();
                }
              });
            }
          },
          onError: (error) {
            debugPrint('Transmission event error: $error');
          },
        );
  }

  Future<void> _checkConnection() async {
    if (!mounted) return;

    setState(() {
      _statusMessage = 'Checking permissions...';
      if (!_isMonitoring) {
        _isSimulatedFallbackAvailable = false;
      }
    });

    try {
      // CRITICAL: Check permissions first (Requirements: 7.3)
      final permissionStatus = await _watchBridge.checkPermission();

      if (permissionStatus != 'granted') {
        if (!mounted) return;
        setState(() {
          _statusMessage = 'Requesting permission...';
        });

        // Request permission
        final granted = await _watchBridge.requestPermission();

        if (!granted) {
          if (!mounted) return;

          // Show permission rationale screen (Requirements: 7.4)
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => const SensorPermissionRationaleScreen(),
            ),
          );

          // If user granted permission from rationale screen, continue
          if (result == true) {
            // Re-check connection after permission grant
            await _checkConnection();
            return;
          }

          setState(() {
            _isConnected = false;
            _statusMessage = 'Permission denied';
            _errorMessage =
                'Sensor permission required for heart rate monitoring';
          });
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        _statusMessage = 'Connecting...';
      });

      // Connect to Samsung Health SDK
      final connected = await _watchBridge.connectToWatch();

      if (!connected) {
        if (!mounted) return;
        setState(() {
          _isConnected = false;
          _statusMessage = 'SDK unavailable';
          _isSimulatedFallbackAvailable = kDebugMode;
          _errorMessage = kDebugMode
              ? _simulatedFallbackMessage
              : _serviceUnavailableMessage;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _isSimulatedFallbackAvailable = false;
        _isSimulatedHeartRate = false;
        _statusMessage = 'Ready';
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      final shouldUseSimulatedFallback = _canUseSimulatedFallback(e);
      setState(() {
        _isConnected = false;
        _isSimulatedFallbackAvailable = shouldUseSimulatedFallback;
        _statusMessage = shouldUseSimulatedFallback
            ? 'SDK unavailable'
            : 'Error';
        _errorMessage = shouldUseSimulatedFallback
            ? _simulatedFallbackMessage
            : _connectionErrorMessage(e);
      });
      debugPrint('Connection error: $e');
    }
  }

  bool _canUseSimulatedFallback(Object error) {
    return kDebugMode && _isSamsungHealthServiceUnavailable(error);
  }

  bool _isSamsungHealthServiceUnavailable(Object error) {
    if (error is SensorError) {
      return error.code == SensorErrorCode.serviceUnavailable &&
          ((error.details?.contains('com.samsung.android.service.health') ??
                  false) ||
              error.message.contains('Samsung Health service unavailable'));
    }

    final errorText = error.toString();
    return errorText.contains('SERVICE_UNAVAILABLE') ||
        errorText.contains('com.samsung.android.service.health') ||
        errorText.contains('Samsung Health service unavailable');
  }

  String _connectionErrorMessage(Object error) {
    if (_isSamsungHealthServiceUnavailable(error)) {
      return _serviceUnavailableMessage;
    }

    return 'Failed to connect to sensor service';
  }

  Future<void> _toggleMonitoring() async {
    if (_isMonitoringBusy) return;

    if (_isMonitoring) {
      await _stopMonitoring();
    } else {
      await _startMonitoring();
    }
  }

  Future<void> _startMonitoring() async {
    if (_isMonitoringBusy) return;

    setState(() {
      _isMonitoringBusy = true;
    });

    if (!_isConnected && _isSimulatedFallbackAvailable) {
      _startSimulatedMonitoring();
      return;
    }

    if (!_isConnected) {
      setState(() {
        _statusMessage = 'Connecting...';
      });
      await _checkConnection();
      if (!mounted) return;
      if (!_isConnected) {
        if (_isSimulatedFallbackAvailable) {
          _startSimulatedMonitoring();
          return;
        }

        setState(() {
          _isMonitoringBusy = false;
          _statusMessage = 'Connection failed';
          _errorMessage ??= 'Unable to connect to sensor service';
        });
        return;
      }
    }

    try {
      setState(() {
        _statusMessage = 'Starting...';
      });

      final started = await _watchBridge.startHeartRateTracking();
      if (!mounted) return;

      if (!started) {
        setState(() {
          _isMonitoringBusy = false;
          _statusMessage = 'Start failed';
          _errorMessage = 'Failed to start heart rate tracking';
        });
        return;
      }

      await _heartRateSubscription?.cancel();
      setState(() {
        _isMonitoringBusy = false;
        _isMonitoring = true;
        _isSimulatedFallbackAvailable = false;
        _isSimulatedHeartRate = false;
        _isAccelerometerActive = true; // Accelerometer starts with heart rate
        _statusMessage = 'Monitoring';
        _errorMessage = null;
      });

      _heartRateSubscription = _watchBridge.heartRateStream.listen(
        (heartRateData) {
          if (!mounted || !_isMonitoring) return;

          setState(() {
            _currentHeartRate = heartRateData;
            _statusMessage = 'Active';
          });
        },
        onError: (error) {
          if (mounted) {
            // Requirements: 6.5 - Handle sensor initialization failures
            final errorString = error.toString();
            String errorMessage = 'Heart rate sensor error occurred';

            if (errorString.contains('ACCELEROMETER_UNAVAILABLE')) {
              errorMessage =
                  'Accelerometer not available. Continuing with heart rate only.';
            } else if (errorString.contains('SENSOR_INITIALIZATION_FAILED')) {
              errorMessage =
                  'Sensor initialization failed. Tap retry to try again.';
            } else if (errorString.contains('ACCELEROMETER_ERROR')) {
              errorMessage =
                  'Accelerometer error. Continuing with heart rate only.';
            }

            setState(() {
              _isMonitoringBusy = false;
              _isMonitoring = false;
              _statusMessage = 'Error';
              _errorMessage = errorMessage;
            });
          }
          debugPrint('Heart rate error: $error');
        },
      );
    } catch (e) {
      if (!mounted) return;
      // Requirements: 6.5 - Handle sensor initialization failures
      setState(() {
        _isMonitoringBusy = false;
        _isMonitoring = false;
        _statusMessage = 'Failed';
        _errorMessage = 'Sensor initialization failed. Tap retry to try again.';
      });
      debugPrint('Start monitoring error: $e');
    }
  }

  void _startSimulatedMonitoring() {
    debugPrint('FLOWFIT_WEAR_SIMULATED_FALLBACK_STARTED');
    unawaited(_heartRateSubscription?.cancel());
    _heartRateSubscription = null;
    _simulatedHeartRateTimer?.cancel();
    _simulatedTick = 0;

    setState(() {
      _isMonitoringBusy = false;
      _isMonitoring = true;
      _isSimulatedHeartRate = true;
      _isAccelerometerActive = false;
      _statusMessage = 'Simulated';
      _errorMessage = _simulatedFallbackMessage;
    });

    _emitSimulatedHeartRate();
    _simulatedHeartRateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _emitSimulatedHeartRate();
    });
  }

  void _emitSimulatedHeartRate() {
    if (!mounted || !_isSimulatedHeartRate) return;

    _simulatedTick += 1;
    final wave = math.sin(_simulatedTick / 3) * 6;
    final variation = _simulatedTick.isEven ? 2 : -1;
    final bpm = 74 + wave.round() + variation;

    setState(() {
      _currentHeartRate = HeartRateData(
        bpm: bpm,
        timestamp: DateTime.now(),
        status: SensorStatus.active,
      );
      _statusMessage = 'Simulated';
    });
  }

  void _stopSimulatedMonitoring() {
    debugPrint('FLOWFIT_WEAR_SIMULATED_FALLBACK_STOPPED');
    _simulatedHeartRateTimer?.cancel();
    _simulatedHeartRateTimer = null;

    setState(() {
      _isMonitoringBusy = false;
      _isMonitoring = false;
      _isSimulatedHeartRate = false;
      _isAccelerometerActive = false;
      _statusMessage = 'Stopped';
      _errorMessage = _simulatedFallbackMessage;
    });
  }

  Future<void> _stopMonitoring() async {
    if (_isMonitoringBusy) return;

    if (_isSimulatedHeartRate) {
      _stopSimulatedMonitoring();
      return;
    }

    try {
      setState(() {
        _isMonitoringBusy = true;
        _isMonitoring = false;
        _isAccelerometerActive = false;
        _statusMessage = 'Stopping...';
      });

      await _watchBridge.stopHeartRateTracking();
      if (!mounted) return;

      final heartRateSubscription = _heartRateSubscription;
      _heartRateSubscription = null;
      if (heartRateSubscription != null) {
        unawaited(
          heartRateSubscription.cancel().catchError((Object error) {
            debugPrint('Heart rate stream cancel error: $error');
          }),
        );
      }
      if (!mounted) return;

      setState(() {
        _isMonitoringBusy = false;
        _statusMessage = 'Stopped';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isMonitoringBusy = false;
        _isMonitoring = true;
        _isAccelerometerActive = true;
        _statusMessage = 'Error stopping';
        _errorMessage = 'Failed to stop monitoring';
      });
    }
  }

  Future<void> _sendToPhone() async {
    if (_isSending || !_canSendCurrentHeartRate) {
      return;
    }

    _statusResetTimer?.cancel();
    setState(() {
      _isSending = true;
      _statusMessage = 'Sending...';
    });

    try {
      final success = await _watchBridge.sendHeartRateToPhone(
        _currentHeartRate!,
      );

      if (mounted) {
        setState(() {
          _isSending = false;
          _statusMessage = success ? 'Sent!' : 'Failed';
          if (!success) {
            _errorMessage = 'Failed to send data to phone';
          }
        });

        // Reset status and clear error after delay
        _statusResetTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _statusMessage = _isMonitoring ? 'Active' : 'Ready';
              if (success) {
                _errorMessage = null;
              }
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _statusMessage = 'Error';
          _errorMessage = 'Error sending data to phone';
        });
      }
      debugPrint('Send error: $e');
    }
  }

  bool get _canSendCurrentHeartRate {
    return _currentHeartRate != null &&
        !_isTestMode &&
        !_isSimulatedHeartRate &&
        !_isSimulatedFallbackAvailable;
  }

  /// Retry the connection after an error, resuming monitoring when possible
  /// Requirements: 5.5, 6.5
  Future<void> _retryConnection() async {
    setState(() {
      _errorMessage = null;
    });
    await _checkConnection();
    if (_isConnected && !_isMonitoring) {
      await _startMonitoring();
    }
  }

  /// Toggle test mode on/off
  /// Requirements: 8.5
  void _toggleTestMode() {
    setState(() {
      _isTestMode = !_isTestMode;
    });

    if (_isTestMode) {
      _startTestModeUpdates();
    } else {
      _stopTestModeUpdates();
    }
  }

  /// Start periodic updates for test mode data
  /// Requirements: 8.5
  void _startTestModeUpdates() {
    _testModeTimer?.cancel();
    _testModeTimer = Timer.periodic(
      const Duration(milliseconds: 500), // Update twice per second
      (timer) async {
        if (!_isTestMode || !mounted) {
          timer.cancel();
          return;
        }

        try {
          final data = await _watchBridge.getTestModeData();
          if (mounted) {
            setState(() {
              _testModeData = data;
            });
          }
        } catch (e) {
          debugPrint('Error getting test mode data: $e');
        }
      },
    );
  }

  /// Stop test mode updates
  /// Requirements: 8.5
  void _stopTestModeUpdates() {
    _testModeTimer?.cancel();
    _testModeTimer = null;
    setState(() {
      _testModeData = null;
    });
  }

  @override
  void dispose() {
    _heartRateSubscription?.cancel();
    _transmissionSubscription?.cancel();
    _testModeTimer?.cancel();
    _statusResetTimer?.cancel();
    _simulatedHeartRateTimer?.cancel();
    _pulseController.dispose();
    _transmissionController.dispose();
    _watchBridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAmbient = widget.mode == WearMode.ambient;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: isAmbient
              ? WearAmbientDisplay(bpm: _currentHeartRate?.bpm)
              : _buildActiveMode(),
        ),
      ),
    );
  }

  Widget _buildActiveMode() {
    final shouldShowFullError =
        _errorMessage != null &&
        !(_isSimulatedFallbackAvailable || _isSimulatedHeartRate);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WearSensorStatusRow(
              transmissionAnimation: _transmissionAnimation,
              bpm: _currentHeartRate?.bpm,
              isMonitoring: _isMonitoring,
              isSimulatedHeartRate: _isSimulatedHeartRate,
              isAccelerometerActive: _isAccelerometerActive,
            ),
            const SizedBox(height: 10),
            if (_isTestMode) ...[
              WearTestModeDisplay(data: _testModeData),
              const SizedBox(height: 10),
            ] else ...[
              WearBpmDisplay(
                pulseAnimation: _pulseAnimation,
                bpm: _currentHeartRate?.bpm,
                isMonitoring: _isMonitoring,
                showServiceUnavailableNote:
                    _isSimulatedFallbackAvailable || _isSimulatedHeartRate,
              ),
              const SizedBox(height: 10),
            ],
            WearStartButton(
              isMonitoring: _isMonitoring,
              isBusy: _isMonitoringBusy,
              onPressed: _toggleMonitoring,
            ),
            if (_canSendCurrentHeartRate) ...[
              const SizedBox(height: 8),
              WearSendButton(isSending: _isSending, onPressed: _sendToPhone),
            ],
            if (!_isSimulatedFallbackAvailable && !_isSimulatedHeartRate) ...[
              const SizedBox(height: 8),
              WearTestModeToggle(
                isTestMode: _isTestMode,
                onPressed: _toggleTestMode,
              ),
            ],
            if (shouldShowFullError) ...[
              const SizedBox(height: 12),
              WearErrorDisplay(
                errorMessage: _errorMessage,
                isSimulatedFallback:
                    _isSimulatedFallbackAvailable || _isSimulatedHeartRate,
                onRetry: _retryConnection,
              ),
            ],
            const SizedBox(height: 8),
            WearStatusIndicator(
              statusMessage: _statusMessage,
              isConnected: _isConnected,
              isMonitoring: _isMonitoring,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
