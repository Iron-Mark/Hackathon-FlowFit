import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

typedef WearPermissionStatusReader = Future<ph.PermissionStatus> Function();
typedef WearPermissionRequester = Future<ph.PermissionStatus> Function();
typedef WearSettingsOpener = Future<bool> Function();

/// Permission wrapper for Wear OS screens
/// Ensures BODY_SENSORS or health.READ_HEART_RATE permission is granted
/// before showing the main content
class WearPermissionWrapper extends StatefulWidget {
  final Widget child;

  const WearPermissionWrapper({
    super.key,
    required this.child,
    this.checkPermission,
    this.requestPermission,
    this.openSettings,
    this.settingsReturnDelay = const Duration(milliseconds: 500),
  });

  final WearPermissionStatusReader? checkPermission;
  final WearPermissionRequester? requestPermission;
  final WearSettingsOpener? openSettings;
  final Duration settingsReturnDelay;

  @override
  State<WearPermissionWrapper> createState() => _WearPermissionWrapperState();
}

class _WearPermissionWrapperState extends State<WearPermissionWrapper>
    with WidgetsBindingObserver {
  ph.PermissionStatus _permissionStatus = ph.PermissionStatus.denied;
  bool _isChecking = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndRequestPermission(force: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permissions when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkAndRequestPermission();
    }
  }

  Future<void> _openAppSettings() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final opened = await (widget.openSettings ?? _defaultOpenSettings)();
      if (!mounted) return;

      if (!opened) {
        setState(() {
          _isChecking = false;
          _errorMessage =
              'Could not open app settings. Enable body sensors manually.';
        });
        return;
      }

      // Re-check after returning from settings
      await Future.delayed(widget.settingsReturnDelay);
      if (!mounted) return;
      await _checkAndRequestPermission(force: true);
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      if (!mounted) return;

      setState(() {
        _isChecking = false;
        _errorMessage = 'Failed to open app settings: $e';
      });
    }
  }

  Future<void> _checkAndRequestPermission({bool force = false}) async {
    if (_isChecking && !force && mounted) return;

    void markChecking() {
      _isChecking = true;
      _errorMessage = null;
    }

    if (mounted && (!_isChecking || _errorMessage != null)) {
      setState(markChecking);
    } else {
      markChecking();
    }

    try {
      var status = await (widget.checkPermission ?? _defaultCheckPermission)();

      if (!status.isGranted) {
        status =
            await (widget.requestPermission ?? _defaultRequestPermission)();
      }

      if (!mounted) return;

      setState(() {
        _permissionStatus = status;
        _isChecking = false;
      });
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      if (!mounted) return;

      setState(() {
        _permissionStatus = ph.PermissionStatus.denied;
        _isChecking = false;
        _errorMessage = 'Failed to check sensor permission: $e';
      });
    }
  }

  Future<ph.PermissionStatus> _defaultCheckPermission() {
    return ph.Permission.sensors.status;
  }

  Future<ph.PermissionStatus> _defaultRequestPermission() {
    return ph.Permission.sensors.request();
  }

  Future<bool> _defaultOpenSettings() {
    return ph.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Checking permissions...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_permissionStatus.isGranted) {
      // Permission granted - show main content
      return widget.child;
    }

    // Permission denied - show rationale
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sensors_off, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _permissionStatus.isPermanentlyDenied
                    ? 'Permission Permanently Denied'
                    : 'Body Sensors Permission Required',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _permissionStatus.isPermanentlyDenied
                    ? 'Please enable body sensors permission in Settings to use heart rate monitoring.'
                    : 'This app needs access to body sensors to monitor your heart rate.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              if (_permissionStatus.isPermanentlyDenied)
                ElevatedButton.icon(
                  onPressed: _openAppSettings,
                  icon: const Icon(Icons.settings, size: 20),
                  label: const Text('Open Settings'),
                )
              else
                ElevatedButton.icon(
                  onPressed: _checkAndRequestPermission,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Grant Permission'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
