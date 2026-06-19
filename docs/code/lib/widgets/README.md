# Permission Status Widget

## Overview

The `PermissionStatusWidget` provides a reusable UI component for displaying and managing body sensor permissions in the FlowFit application.

## Features

- **Real-time Permission State Updates**: Automatically monitors and displays the current permission status
- **Visual Feedback**: Color-coded status indicators (green for granted, red for denied, orange for not determined)
- **User Actions**: 
  - Request permission button for undetermined state
  - Open Settings button for denied state
- **Stream-based Updates**: Uses the WatchBridgeService permission state stream for reactive UI updates

## Usage

### Basic Usage

```dart
import 'package:flowfit/widgets/permission_status_widget.dart';
import 'package:flowfit/services/watch_bridge.dart';

class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late final WatchBridgeService _watchBridge;

  @override
  void initState() {
    super.initState();
    _watchBridge = WatchBridgeService();
  }

  @override
  void dispose() {
    _watchBridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PermissionStatusWidget(
        watchBridge: _watchBridge,
        showOpenSettingsButton: true,
      ),
    );
  }
}
```

### Without Open Settings Button

```dart
PermissionStatusWidget(
  watchBridge: _watchBridge,
  showOpenSettingsButton: false,
)
```

## Example Screen

See `lib/screens/sensor_permission_screen.dart` for a complete example of how to integrate the permission status widget into a full screen with additional context and information.

## WatchBridgeService Permission Methods

### Start Monitoring

```dart
watchBridge.startPermissionMonitoring(
  interval: Duration(seconds: 2), // Optional, defaults to 2 seconds
);
```

### Stop Monitoring

```dart
watchBridge.stopPermissionMonitoring();
```

### Permission State Stream

```dart
watchBridge.permissionStateStream.listen((status) {
  print('Permission status changed: $status');
});
```

### Request Permission

```dart
final granted = await watchBridge.requestBodySensorPermission();
```

### Check Permission

```dart
final status = await watchBridge.checkBodySensorPermission();
```

### Open App Settings

```dart
final opened = await watchBridge.openAppSettings();
```

## Requirements Validated

This implementation validates the following requirements:

- **3.2**: When the user grants permission, sensor data collection is enabled
- **3.3**: When the user denies permission, sensor features are disabled with appropriate message
- **3.4**: When permission status changes, the UI updates to reflect the current state
