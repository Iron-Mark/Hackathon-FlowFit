import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/watch_bridge.dart';

typedef SensorPermissionWatchBridgeFactory = WatchBridgeService Function();
typedef SensorPermissionSettingsOpener = Future<bool> Function();

/// Permission rationale screen for Wear OS
/// Displays explanation when sensor permissions are denied
/// Provides options to retry or open settings
/// Requirements: 7.4
class SensorPermissionRationaleScreen extends StatefulWidget {
  const SensorPermissionRationaleScreen({
    super.key,
    this.watchBridgeFactory,
    this.openSettings,
  });

  final SensorPermissionWatchBridgeFactory? watchBridgeFactory;
  final SensorPermissionSettingsOpener? openSettings;

  @override
  State<SensorPermissionRationaleScreen> createState() =>
      _SensorPermissionRationaleScreenState();
}

class _SensorPermissionRationaleScreenState
    extends State<SensorPermissionRationaleScreen> {
  late final WatchBridgeService _watchBridge =
      (widget.watchBridgeFactory ?? WatchBridgeService.new)();
  bool _isRequesting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _watchBridge.dispose();
    super.dispose();
  }

  Future<void> _retryPermission() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
      _errorMessage = null;
    });

    try {
      final granted = await _watchBridge.requestPermission();

      if (!mounted) return;

      if (granted) {
        // Permission granted, navigate back to main screen
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isRequesting = false;
          _errorMessage = 'Permission denied. Please grant access to continue.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRequesting = false;
        _errorMessage = 'Error requesting permission: ${e.toString()}';
      });
    }
  }

  Future<void> _openSettings() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
      _errorMessage = null;
    });

    try {
      final opened = await (widget.openSettings ?? openAppSettings)();

      if (!mounted) return;

      if (!opened) {
        setState(() {
          _isRequesting = false;
          _errorMessage =
              'Could not open app settings. Open settings manually to grant sensor access.';
        });
        return;
      }

      // Wait a bit for user to return from settings
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if permissions are now granted
      final status = await _watchBridge.checkPermission();

      if (!mounted) return;

      if (status == 'granted') {
        // Permission granted, navigate back
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isRequesting = false;
          _errorMessage =
              'Sensor access is still disabled. Enable body sensors in settings to continue.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRequesting = false;
        _errorMessage = 'Error opening settings: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon
                const Icon(
                  Icons.sensors_off,
                  size: 48,
                  color: Color(0xFFF44336), // WearColors.errorRed
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  'Sensor Access Required',
                  style: TextStyle(
                    fontSize: 18, // Meets minimum 18sp for headings
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Explanation text
                const Text(
                  'FlowFit needs access to body sensors and activity recognition to track your heart rate and movement for accurate activity classification.',
                  style: TextStyle(
                    fontSize: 14, // Meets minimum 14sp for body text
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Additional explanation
                const Text(
                  'This data is used to:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Bullet points
                const Text(
                  '• Monitor your heart rate\n'
                  '• Detect your movements\n'
                  '• Classify your activities',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF44336).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF44336),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Retry button (48x48dp minimum touch target)
                SizedBox(
                  width: 140,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isRequesting ? null : _retryPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF2196F3,
                      ), // WearColors.primaryBlue
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(
                        0xFF90CAF9,
                      ).withValues(alpha: 0.6),
                      disabledForegroundColor: Colors.white.withValues(
                        alpha: 0.6,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: _isRequesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh, size: 20),
                    label: Text(
                      _isRequesting ? 'Requesting...' : 'Grant Access',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Settings button (48x48dp minimum touch target)
                SizedBox(
                  width: 140,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isRequesting ? null : _openSettings,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2196F3),
                      side: const BorderSide(
                        color: Color(0xFF2196F3),
                        width: 1,
                      ),
                      disabledForegroundColor: Colors.white.withValues(
                        alpha: 0.6,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(Icons.settings, size: 20),
                    label: const Text(
                      'Open Settings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
