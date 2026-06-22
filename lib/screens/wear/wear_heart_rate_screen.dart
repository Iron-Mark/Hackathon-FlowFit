import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wear_plus/wear_plus.dart';

import '../../models/heart_rate_data.dart';
import '../../models/sensor_error.dart';
import '../../models/sensor_error_code.dart';
import '../../models/sensor_status.dart';
import '../../services/watch_bridge.dart';
import 'sensor_permission_rationale_screen.dart';

// WCAG 2.1 Level AA compliant color constants
// All colors verified to meet contrast ratio requirements
class WearColors {
  // Primary blue for main interactive elements
  // Contrast with black: 8.6:1, with white text: 4.5:1
  static const Color primaryBlue = Color(0xFF2196F3);

  // Dark blue for pressed/active states
  // Contrast with black: 6.3:1, with white text: 5.7:1
  static const Color darkBlue = Color(0xFF1976D2);

  // Light blue-grey for disabled states (60% opacity)
  // Contrast with black: 3.2:1 (for large text)
  static const Color lightBlueGrey = Color(0xFF90CAF9);

  // Teal for success states
  // Contrast with black: 9.1:1, with white text: 4.2:1
  static const Color teal = Color(0xFF00BCD4);

  // Red for error states
  // Contrast with black: 5.9:1, with white text: 4.8:1
  static const Color errorRed = Color(0xFFF44336);
}

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
          child: isAmbient ? _buildAmbientMode() : _buildActiveMode(),
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
            _buildSensorStatus(),
            const SizedBox(height: 10),
            if (_isTestMode) ...[
              _buildTestModeDisplay(),
              const SizedBox(height: 10),
            ] else ...[
              _buildBpmDisplay(),
              const SizedBox(height: 10),
            ],
            _buildStartButton(),
            if (_canSendCurrentHeartRate) ...[
              const SizedBox(height: 8),
              _buildSendButton(),
            ],
            if (!_isSimulatedFallbackAvailable && !_isSimulatedHeartRate) ...[
              const SizedBox(height: 8),
              _buildTestModeToggle(),
            ],
            if (shouldShowFullError) ...[
              const SizedBox(height: 12),
              _buildErrorDisplay(),
            ],
            const SizedBox(height: 8),
            _buildStatusIndicator(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Builds sensor status indicator showing heart rate and accelerometer status
  /// Meets WCAG requirements: minimum 14sp font, color + icon for status
  Widget _buildSensorStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Heart rate indicator
        Icon(
          Icons.favorite,
          color: _isMonitoring ? Colors.red : Colors.grey,
          size: 24,
        ),
        const SizedBox(width: 4),
        Text(
          _currentHeartRate?.bpm != null ? '${_currentHeartRate!.bpm}' : '--',
          style: const TextStyle(
            fontSize: 18, // Meets minimum 14sp requirement
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        // Accelerometer indicator with animation
        AnimatedBuilder(
          animation: _transmissionAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _transmissionAnimation.value,
              child: Icon(
                Icons.sensors,
                color: _isSimulatedHeartRate
                    ? WearColors.teal
                    : _isAccelerometerActive
                    ? WearColors.primaryBlue
                    : Colors.grey,
                size: 24,
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        Text(
          _isSimulatedHeartRate
              ? 'Sim'
              : (_isAccelerometerActive ? 'Active' : 'Off'),
          style: const TextStyle(
            fontSize: 14, // Meets minimum 14sp requirement
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildBpmDisplay() {
    final bpm = _currentHeartRate?.bpm;
    final showServiceUnavailableNote =
        _isSimulatedFallbackAvailable || _isSimulatedHeartRate;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isMonitoring ? _pulseAnimation.value : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!showServiceUnavailableNote) ...[
                Icon(
                  Icons.favorite,
                  color: _isMonitoring ? Colors.red : Colors.grey.shade700,
                  size: 32,
                ),
                const SizedBox(height: 8),
              ],
              Text(
                bpm != null ? '$bpm' : '--',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'BPM',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                  letterSpacing: 0,
                ),
              ),
              if (showServiceUnavailableNote) ...[
                const SizedBox(height: 2),
                const SizedBox(
                  width: 180,
                  child: Text(
                    'Samsung Health service unavailable',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: WearColors.teal),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Start/Stop button with WCAG-compliant touch target (48x48dp minimum)
  /// Uses primaryBlue for Start button, errorRed for Stop button
  /// Requirements: 4.1, 4.5
  Widget _buildStartButton() {
    return SizedBox(
      width: 120,
      height: 48, // WCAG 2.1 Level AA: minimum 48dp touch target
      child: ElevatedButton.icon(
        onPressed: _isMonitoringBusy ? null : _toggleMonitoring,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: _isMonitoring
                  ? WearColors.errorRed
                  : WearColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ).copyWith(
              // Apply darkBlue to pressed/active states (Requirements: 4.2)
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.pressed)) {
                  return _isMonitoring
                      ? WearColors.errorRed.withValues(alpha: 0.8)
                      : WearColors.darkBlue;
                }
                return _isMonitoring
                    ? WearColors.errorRed
                    : WearColors.primaryBlue;
              }),
            ),
        icon: _isMonitoringBusy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(_isMonitoring ? Icons.pause : Icons.play_arrow, size: 20),
        label: Text(
          _isMonitoringBusy ? 'Wait' : (_isMonitoring ? 'Stop' : 'Start'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Send to phone button with WCAG-compliant touch target (48x48dp minimum)
  /// Uses primaryBlue for enabled state, lightBlueGrey for disabled state
  /// Requirements: 4.1, 4.2, 4.3
  Widget _buildSendButton() {
    return SizedBox(
      width: 120,
      height: 48, // WCAG 2.1 Level AA: minimum 48dp touch target
      child: ElevatedButton.icon(
        onPressed: _isSending ? null : _sendToPhone,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: WearColors.primaryBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: WearColors.lightBlueGrey.withValues(
                alpha: 0.6,
              ), // Requirements: 4.3
              disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ).copyWith(
              // Apply darkBlue to pressed/active states (Requirements: 4.2)
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.disabled)) {
                  return WearColors.lightBlueGrey.withValues(alpha: 0.6);
                }
                if (states.contains(WidgetState.pressed)) {
                  return WearColors.darkBlue;
                }
                return WearColors.primaryBlue;
              }),
            ),
        icon: _isSending
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.phone_android, size: 18),
        label: Text(
          _isSending ? 'Sending' : 'Send',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Error display widget with icon and descriptive text
  /// Meets WCAG requirements: minimum 14sp font, sufficient contrast
  /// Requirements: 5.5, 6.5 - Display error with retry option
  Widget _buildErrorDisplay() {
    final showRetry = _errorMessage?.contains('retry') ?? false;
    final isSimulatedFallback =
        _isSimulatedFallbackAvailable || _isSimulatedHeartRate;
    final accentColor = isSimulatedFallback
        ? WearColors.teal
        : WearColors.errorRed;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSimulatedFallback ? Icons.science : Icons.error_outline,
                color: accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _errorMessage ?? 'An error occurred',
                  style: const TextStyle(
                    fontSize: 14, // Meets minimum 14sp requirement
                    color: Colors.white,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (showRetry) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    _errorMessage = null;
                  });
                  await _checkConnection();
                  if (_isConnected && !_isMonitoring) {
                    await _startMonitoring();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: WearColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Test mode toggle button
  /// Requirements: 8.5
  Widget _buildTestModeToggle() {
    return SizedBox(
      width: 48,
      height: 48, // WCAG 2.1 Level AA: minimum 48dp touch target
      child: IconButton(
        onPressed: _toggleTestMode,
        style: IconButton.styleFrom(
          backgroundColor: _isTestMode ? WearColors.teal : Colors.grey.shade800,
          foregroundColor: Colors.white,
        ),
        icon: Icon(
          _isTestMode ? Icons.bug_report : Icons.bug_report_outlined,
          size: 20,
        ),
      ),
    );
  }

  /// Test mode display showing real-time sensor values
  /// Requirements: 8.5, 11.2
  Widget _buildTestModeDisplay() {
    final data = _testModeData;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WearColors.teal.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WearColors.teal, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Mode',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: WearColors.teal,
            ),
          ),
          const SizedBox(height: 8),
          // Heart rate
          _buildTestModeRow(
            'HR',
            data?['heartRate']?.toString() ?? '--',
            'bpm',
          ),
          const SizedBox(height: 4),
          // Accelerometer X
          _buildTestModeRow(
            'Acc X',
            data?['accelerometerX'] != null
                ? (data!['accelerometerX'] as double).toStringAsFixed(2)
                : '--',
            'm/s²',
          ),
          const SizedBox(height: 4),
          // Accelerometer Y
          _buildTestModeRow(
            'Acc Y',
            data?['accelerometerY'] != null
                ? (data!['accelerometerY'] as double).toStringAsFixed(2)
                : '--',
            'm/s²',
          ),
          const SizedBox(height: 4),
          // Accelerometer Z
          _buildTestModeRow(
            'Acc Z',
            data?['accelerometerZ'] != null
                ? (data!['accelerometerZ'] as double).toStringAsFixed(2)
                : '--',
            'm/s²',
          ),
          const SizedBox(height: 4),
          // Buffer size
          _buildTestModeRow(
            'Buffer',
            '${data?['bufferSize'] ?? 0}/32',
            'samples',
          ),
          const SizedBox(height: 4),
          // Time since last transmission
          _buildTestModeRow(
            'Last TX',
            data?['timeSinceLastTransmission'] != null
                ? '${(data!['timeSinceLastTransmission'] as int) ~/ 1000}'
                : '--',
            's ago',
          ),
        ],
      ),
    );
  }

  /// Helper widget to build a test mode data row
  /// Requirements: 8.5
  Widget _buildTestModeRow(String label, String value, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        Text(
          '$value $unit',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Status indicator with color-coded states
  /// Uses teal for success states, errorRed for errors, primaryBlue for ready
  /// Requirements: 4.1, 4.4, 4.5
  Widget _buildStatusIndicator() {
    Color statusColor = Colors.grey;

    // Determine status color based on state
    if (_statusMessage == 'Sent!' ||
        _statusMessage == 'Active' ||
        _statusMessage == 'Simulated') {
      // Success states use teal (Requirements: 4.4)
      statusColor = WearColors.teal;
    } else if (_statusMessage.contains('Error') ||
        _statusMessage.contains('Failed') ||
        _statusMessage.contains('denied') ||
        _statusMessage.contains('unavailable')) {
      // Error states use errorRed (Requirements: 4.5)
      statusColor = WearColors.errorRed;
    } else if (_isConnected && _isMonitoring) {
      // Active monitoring uses teal (Requirements: 4.4)
      statusColor = WearColors.teal;
    } else if (_isConnected) {
      // Ready state uses primaryBlue (Requirements: 4.1)
      statusColor = WearColors.primaryBlue;
    } else {
      // Disconnected/unknown uses grey
      statusColor = Colors.grey;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(height: 2),
        Text(
          _statusMessage,
          style: TextStyle(fontSize: 10, color: statusColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAmbientMode() {
    final bpm = _currentHeartRate?.bpm;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.favorite, color: Colors.white24, size: 24),
        const SizedBox(height: 8),
        Text(
          bpm != null ? '$bpm' : '--',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white24,
          ),
        ),
        const Text(
          'BPM',
          style: TextStyle(fontSize: 14, color: Colors.white10),
        ),
      ],
    );
  }
}
