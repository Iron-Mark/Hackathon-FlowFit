import 'package:flutter/material.dart';
import '../models/permission_status.dart';
import '../services/watch_bridge.dart';

/// Widget that displays the current permission status and provides
/// UI for managing permissions
class PermissionStatusWidget extends StatefulWidget {
  final WatchBridgeService watchBridge;
  final bool showOpenSettingsButton;

  const PermissionStatusWidget({
    super.key,
    required this.watchBridge,
    this.showOpenSettingsButton = true,
  });

  @override
  State<PermissionStatusWidget> createState() => _PermissionStatusWidgetState();
}

class _PermissionStatusWidgetState extends State<PermissionStatusWidget> {
  PermissionStatus _currentStatus = PermissionStatus.notDetermined;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _initializePermissionState();
    widget.watchBridge.startPermissionMonitoring();
  }

  @override
  void dispose() {
    widget.watchBridge.stopPermissionMonitoring();
    super.dispose();
  }

  Future<void> _initializePermissionState() async {
    await _refreshPermissionState();
  }

  Future<void> _refreshPermissionState({
    PermissionStatus? fallbackStatus,
  }) async {
    try {
      final status = await widget.watchBridge.checkBodySensorPermission();
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });
      }
    } catch (e) {
      debugPrint('Error checking initial permission state: $e');
      if (fallbackStatus != null && mounted) {
        setState(() {
          _currentStatus = fallbackStatus;
        });
      }
    }
  }

  Future<void> _requestPermission() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      final granted = await widget.watchBridge.requestBodySensorPermission();
      await _refreshPermissionState(
        fallbackStatus: granted
            ? PermissionStatus.granted
            : PermissionStatus.denied,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request permission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    try {
      final opened = await widget.watchBridge.openAppSettings();
      if (opened) {
        await _refreshPermissionState();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open app settings'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PermissionStatus>(
      stream: widget.watchBridge.permissionStateStream,
      builder: (context, snapshot) {
        final streamedStatus = snapshot.data;

        // Update local state
        if (streamedStatus != null && streamedStatus != _currentStatus) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentStatus = streamedStatus;
              });
            }
          });
        }

        return _buildPermissionCard(_currentStatus);
      },
    );
  }

  Widget _buildPermissionCard(PermissionStatus status) {
    final isGranted = status == PermissionStatus.granted;
    final isDenied = status == PermissionStatus.denied;
    final isNotDetermined = status == PermissionStatus.notDetermined;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusMessage;

    if (isGranted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Permission Granted';
      statusMessage = 'Sensor data collection is enabled';
    } else if (isDenied) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Permission Denied';
      statusMessage =
          'Sensor features are disabled. Grant permission to enable.';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Permission Required';
      statusMessage = 'Body sensor permission is needed to track health data';
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusMessage,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isGranted) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isDenied && widget.showOpenSettingsButton) ...[
                    TextButton.icon(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('Open Settings'),
                      style: TextButton.styleFrom(foregroundColor: statusColor),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (isNotDetermined)
                    ElevatedButton(
                      onPressed: _isRequesting ? null : _requestPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isRequesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Grant Permission'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
