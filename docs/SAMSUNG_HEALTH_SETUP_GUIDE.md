# Samsung Health Sensor Integration Setup Guide

This guide explains how to set up and use the Samsung Health Sensor SDK integration in your FlowFit app.

## Prerequisites

### Hardware Requirements
- **Galaxy Watch4 or higher** (running Wear OS powered by Samsung)
- The watch must support Samsung Health Sensor SDK
- Watch should be on your wrist for accurate heart rate readings

### Software Requirements
- ✅ Samsung Health Sensor SDK (already included: `samsung-health-sensor-api-1.4.1.aar`)
- ✅ Android Studio with Kotlin support
- ✅ Flutter SDK
- ✅ Permissions configured in AndroidManifest.xml

## What's Already Set Up

Your project already has:

1. **Samsung Health Sensor SDK** - The AAR file is in `android/app/libs/`
2. **Permissions** - All required permissions in AndroidManifest.xml:
   - `BODY_SENSORS` - Access heart rate sensor
   - `FOREGROUND_SERVICE` - Run tracking in background
   - `FOREGROUND_SERVICE_HEALTH` - Health-specific foreground service
   - `WAKE_LOCK` - Keep device awake during tracking
   - `ACTIVITY_RECOGNITION` - Activity tracking

3. **Method Channel Bridge** - Flutter ↔ Kotlin communication set up
4. **Event Channel** - Real-time heart rate data streaming
5. **Kotlin Implementation** - Complete heart rate tracking logic

## Key Differences from Samsung Tutorial

The Samsung tutorial shows a **phone + watch companion app** setup using:
- Wearable Data Layer API (MessageClient, CapabilityClient)
- Two separate modules (wear + mobile)
- Data transfer between devices

**Your setup is simpler** because you're building a **standalone Wear OS app**:
- ✅ No need for Wearable Data Layer API
- ✅ No need for companion phone app
- ✅ Direct access to Samsung Health Sensor SDK
- ✅ Data stays on the watch (or syncs to Supabase)

## Architecture Overview

```
┌─────────────────────────────────────────┐
│         Flutter UI (Dart)               │
│  - wear_dashboard.dart                  │
│  - wear_heart_rate_screen.dart          │
└──────────────┬──────────────────────────┘
               │ Method Channel
               │ Event Channel
┌──────────────▼──────────────────────────┐
│      WatchBridgeService (Dart)          │
│  - Manages connection state             │
│  - Handles permissions                  │
│  - Streams heart rate data              │
└──────────────┬──────────────────────────┘
               │ Platform Channel
┌──────────────▼──────────────────────────┐
│       MainActivity (Kotlin)             │
│  - Method call handler                  │
│  - Event stream handler                 │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│   HealthTrackingManager (Kotlin)        │
│  - Connects to Samsung Health Service   │
│  - Manages heart rate tracker           │
│  - Processes data points                │
│  - Extracts HR + IBI values             │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  Samsung Health Tracking Service        │
│  (System Service on Galaxy Watch)       │
└─────────────────────────────────────────┘
```

## How to Use

### 1. Request Permission

```dart
final watchBridge = WatchBridgeService();

// Request body sensor permission
final granted = await watchBridge.requestBodySensorPermission();
if (!granted) {
  // Handle permission denied
  print('Permission denied');
  return;
}
```

### 2. Connect to Samsung Health Service

```dart
// Connect to the health tracking service
final connected = await watchBridge.connectToWatch();
if (!connected) {
  // Handle connection failure
  print('Failed to connect to Samsung Health');
  return;
}
```

### 3. Start Heart Rate Tracking

```dart
// Start continuous heart rate tracking
final started = await watchBridge.startHeartRateTracking();
if (!started) {
  print('Failed to start tracking');
  return;
}

// Listen to heart rate stream
watchBridge.heartRateStream.listen((heartRateData) {
  print('Heart Rate: ${heartRateData.bpm} bpm');
  print('IBI Values: ${heartRateData.ibiValues}');
  print('Status: ${heartRateData.status}');
});
```

### 4. Stop Tracking

```dart
// Stop heart rate tracking
await watchBridge.stopHeartRateTracking();

// Disconnect from service
await watchBridge.disconnectFromWatch();
```

## Data Structure

### HeartRateData Model

```dart
class HeartRateData {
  final int? bpm;              // Heart rate in beats per minute (null during measurement)
  final DateTime timestamp;     // When the reading was taken
  final SensorStatus status;    // valid, measuring, error
  final List<int> ibiValues;   // Inter-beat intervals in milliseconds
}
```

### Heart Rate Status

- **valid** - Heart rate reading is accurate
- **measuring** - Sensor is still measuring (bpm may be null)
- **error** - Sensor error occurred

### IBI (Inter-Beat Interval)

- List of time intervals between heartbeats in milliseconds
- Can have 0-4 values per data point
- Useful for heart rate variability (HRV) analysis
- Only valid IBI values (status = 0, value ≠ 0) are included

## Testing

### On Physical Device

1. **Build and deploy to Galaxy Watch:**
   ```bash
   flutter run -d <watch-device-id>
   ```

2. **Wear the watch on your wrist** - Heart rate sensor needs skin contact

3. **Grant permissions** when prompted

4. **Start tracking** and wait a few seconds for readings

### Expected Behavior

- First few readings may show "measuring" status
- Heart rate should stabilize after 5-10 seconds
- IBI values appear with each reading
- Data streams continuously until stopped

### Troubleshooting

**"Connection Failed"**
- Check if Samsung Health is installed on the watch
- Ensure watch supports Samsung Health Sensor SDK
- Try restarting the watch

**"Permission Denied"**
- Go to Settings → Apps → FlowFit → Permissions
- Enable "Body sensors" permission

**"Sensor Not Supported"**
- Device doesn't support continuous heart rate tracking
- Requires Galaxy Watch4 or higher

**No Heart Rate Readings**
- Ensure watch is worn on wrist (not on table)
- Tighten watch band for better sensor contact
- Clean the sensor on the back of the watch

## Implementation Details

### Kotlin Side

**HealthTrackingManager.kt** handles:
- Connection to `HealthTrackingService`
- Capability checking (is heart rate supported?)
- Tracker lifecycle (start/stop)
- Data point processing
- IBI validation and extraction

**MainActivity.kt** handles:
- Method channel calls from Flutter
- Event channel streaming to Flutter
- Coroutine-based async operations
- Error handling and logging

### Flutter Side

**WatchBridgeService** provides:
- High-level API for Flutter code
- Permission management
- Connection state management
- Heart rate data streaming
- Error handling with retry logic

## Next Steps

1. **Test on physical Galaxy Watch** - Emulator doesn't support Samsung Health sensors

2. **Integrate with your UI** - Update `wear_dashboard.dart` and the tracker page in `lib/features/activity_classifier/`

3. **Store data in Supabase** - Save heart rate readings to your backend

4. **Add workout tracking** - Combine with activity detection

5. **Implement HRV analysis** - Use IBI values for heart rate variability

## Resources

- [Samsung Health Sensor SDK Documentation](https://developer.samsung.com/health/android/data/guide/health-sensor.html)
- [Heart Rate Data Transfer Tutorial](https://developer.samsung.com/blog/en-us/2025/07/31/measure-and-transfer-heart-rate-data-from-galaxy-watch-to-a-paired-android-phone)
- [Samsung Health Sensor API Reference](https://developer.samsung.com/health/android/data/api-reference/com/samsung/android/service/health/tracking/package-summary.html)

## Support

If you encounter issues:
1. Check logcat for detailed error messages: `adb logcat | grep -i health`
2. Verify Samsung Health is up to date on the watch
3. Ensure watch firmware is current
4. Check Samsung Developer forums for known issues
