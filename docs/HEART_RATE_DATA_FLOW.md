# Heart Rate Data Flow: Galaxy Watch 6 to Phone

This document explains how live heart rate data flows from the Galaxy Watch 6 to the FlowFit phone app using the Samsung Health Sensor API.

## Overview

The heart rate data flow involves three main layers:
1. **Samsung Health Sensor API** (native Android/Wear OS)
2. **Native Android Bridge** (Kotlin - MainActivity & SamsungHealthManager)
3. **Flutter Application** (Dart - WatchBridgeService)

## Architecture Diagram

```
┌─────────────────────────────────────┐
│   Galaxy Watch 6 (Wear OS)          │
│   - Heart Rate Sensor               │
│   - Samsung Health Sensor API       │
└──────────────┬──────────────────────┘
               │ Bluetooth/WiFi
               ▼
┌─────────────────────────────────────┐
│   Android Phone - Native Layer      │
│                                     │
│   SamsungHealthManager.kt           │
│   - ConnectionListener              │
│   - HeartRateListener               │
│   - Lifecycle Management            │
│                                     │
│   MainActivity.kt                   │
│   - MethodChannel Handler           │
│   - EventChannel Stream             │
└──────────────┬──────────────────────┘
               │ Platform Channels
               ▼
┌─────────────────────────────────────┐
│   Flutter Application Layer         │
│                                     │
│   WatchBridgeService                │
│   - Permission Management           │
│   - Connection Control              │
│   - Heart Rate Stream               │
│                                     │
│   UI Components                     │
│   - Dashboard                       │
│   - Activity Tracker                │
│   - Wear Dashboard                  │
└─────────────────────────────────────┘
```

## Data Flow Steps

### 1. Permission Request

**Flutter → Native:**
```dart
// WatchBridgeService.requestBodySensorPermission()
final status = await Permission.sensors.request();
```

**Native → Android:**
```kotlin
// MainActivity.requestPermission()
ActivityCompat.requestPermissions(
    this,
    arrayOf(Manifest.permission.BODY_SENSORS),
    PERMISSION_REQUEST_CODE
)
```

**Result:** User grants or denies BODY_SENSORS permission

### 2. Connection Establishment

**Flutter → Native:**
```dart
// WatchBridgeService.connectToWatch()
final result = await _methodChannel.invokeMethod<bool>('connectWatch');
```

**Native → Samsung Health:**
```kotlin
// SamsungHealthManager.connect()
healthTrackingService.connectService(connectionListener, packageName)
```

**Samsung Health → Native:**
```kotlin
// ConnectionListener callback
override fun onConnectionSuccess() {
    callback(true, null)
}
```

**Native → Flutter:**
```kotlin
// MainActivity.connectWatch()
result.success(true)
```

### 3. Start Heart Rate Tracking

**Flutter → Native:**
```dart
// WatchBridgeService.startHeartRateTracking()
final result = await _methodChannel.invokeMethod<bool>('startHeartRate');
```

**Native → Samsung Health:**
```kotlin
// SamsungHealthManager.startHeartRateTracking()
tracker = healthTrackingService.getHealthTracker(
    HealthTrackerType.HEART_RATE_CONTINUOUS
)
tracker.setEventListener(heartRateListener)
```

**Samsung Health → Native (Continuous Stream):**
```kotlin
// HeartRateListener callback
override fun onDataReceived(dataList: List<DataPoint>) {
    val bpm = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE)
    val timestamp = dataPoint.timestamp
    callback(bpm, timestamp)
}
```

**Native → Flutter (EventChannel Stream):**
```kotlin
// MainActivity.startHeartRate()
heartRateEventSink?.success(
    mapOf(
        "bpm" to bpm,
        "timestamp" to timestamp,
        "status" to "active"
    )
)
```

**Flutter Stream:**
```dart
// WatchBridgeService.heartRateStream
Stream<HeartRateData> get heartRateStream {
  return _heartRateEventChannel
      .receiveBroadcastStream()
      .map((event) => HeartRateData.fromJson(event));
}
```

### 4. UI Updates

**Flutter UI:**
```dart
// Listen to heart rate stream
watchBridge.heartRateStream.listen((heartRateData) {
  setState(() {
    currentBpm = heartRateData.bpm;
    lastUpdate = heartRateData.timestamp;
  });
});
```

### 5. Stop Heart Rate Tracking

**Flutter → Native:**
```dart
// WatchBridgeService.stopHeartRateTracking()
await _methodChannel.invokeMethod<void>('stopHeartRate');
```

**Native → Samsung Health:**
```kotlin
// SamsungHealthManager.stopHeartRateTracking()
tracker?.unsetEventListener()
tracker?.flush()
tracker = null
```

## Communication Channels

### MethodChannel: `com.flowfit.watch/data`

Handles request-response operations:
- `requestPermission` → Returns permission granted status
- `checkPermission` → Returns current permission state
- `connectWatch` → Establishes connection to Samsung Health
- `disconnectWatch` → Closes connection
- `isWatchConnected` → Checks connection status
- `startHeartRate` → Begins heart rate tracking
- `stopHeartRate` → Stops heart rate tracking
- `getCurrentHeartRate` → Gets last known heart rate value

### EventChannel: `com.flowfit.watch/heartrate`

Streams continuous heart rate data:
- Emits `HeartRateData` objects as they arrive from the sensor
- Handles errors and sensor unavailability
- Automatically manages stream lifecycle

## Data Models

### HeartRateData (Flutter)
```dart
class HeartRateData {
  final int bpm;              // Beats per minute
  final DateTime timestamp;   // When measurement was taken
  final String status;        // "active", "inactive", "error"
}
```

### Heart Rate Event (Native)
```kotlin
mapOf(
    "bpm" to Int,           // Heart rate value
    "timestamp" to Long,    // Unix timestamp in milliseconds
    "status" to String      // Sensor status
)
```

## Error Handling

### Flutter Layer
```dart
try {
  await watchBridge.startHeartRateTracking();
} on SensorError catch (e) {
  switch (e.code) {
    case SensorErrorCode.permissionDenied:
      // Show permission request dialog
    case SensorErrorCode.connectionFailed:
      // Retry connection
    case SensorErrorCode.sensorUnavailable:
      // Show sensor unavailable message
  }
}
```

### Native Layer
```kotlin
try {
    healthManager.startHeartRateTracking(...)
} catch (e: Exception) {
    result.error(
        "SENSOR_UNAVAILABLE",
        "Failed to start heart rate tracking",
        e.message
    )
}
```

## Lifecycle Management

### App Goes to Background
1. `MainActivity.onPause()` called
2. `SamsungHealthManager.onPause()` pauses non-critical tracking
3. Tracking state saved for resume

### App Returns to Foreground
1. `MainActivity.onResume()` called
2. `SamsungHealthManager.onResume()` resumes tracking if previously active
3. Stream reconnects automatically

### App Closes
1. `MainActivity.onDestroy()` called
2. `SamsungHealthManager.onDestroy()` stops all tracking
3. Disconnects from Samsung Health services
4. Cleans up event sinks and listeners

## Tracking Lifecycle

The current native implementation does not declare a dedicated foreground service for heart-rate tracking. When tracking is active:
1. `MainActivity` owns the `HealthTrackingManager` lifecycle
2. `HealthTrackingManager` connects to Samsung Health Tracking Service
3. `WatchSensorService` collects accelerometer batches as an in-process helper
4. `PhoneDataListenerService` receives wearable data-layer messages on the phone side

If FlowFit later needs long-running background health tracking, add a real Android `Service` implementation before reintroducing a foreground-service manifest entry.

## Performance Considerations

- **Retry Logic:** Connection attempts use exponential backoff (500ms, 1s, 2s)
- **Timeouts:** All operations have 10-second timeout
- **Stream Buffering:** EventChannel handles backpressure automatically
- **Battery:** Heart rate sensor uses ~2-5% battery per hour
- **Data Rate:** Heart rate updates arrive every 1-2 seconds

## Debugging

Enable logging in WatchBridgeService:
```dart
final Logger _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    printTime: true,
  ),
);
```

Check logs for:
- Permission request results
- Connection status changes
- Heart rate data arrival
- Error conditions

## Common Issues

### Permission Denied
- Check AndroidManifest.xml has BODY_SENSORS permission
- Verify user granted permission in app settings
- Use `openAppSettings()` to guide user

### Connection Failed
- Ensure Samsung Health app is installed
- Check Bluetooth/WiFi connectivity to watch
- Verify watch is paired with phone
- Try reconnecting with retry logic

### No Heart Rate Data
- Ensure watch is worn properly on wrist
- Check sensor is not blocked or dirty
- Verify heart rate tracking started successfully
- Check EventChannel stream is subscribed

### Tracking Stops in Background
- Verify foreground service is running
- Check notification is visible
- Ensure FOREGROUND_SERVICE permission granted
- Review battery optimization settings
