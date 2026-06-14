# Samsung Health Sensor - Quick Start Guide

## 🚀 Ready to Test in 5 Minutes

### Prerequisites
- Galaxy Watch4 or higher
- Watch paired and connected
- Samsung Health app installed

### Step 1: Build & Deploy
```bash
flutter run -d <watch-device-id>
```

### Step 2: Test the Implementation

Use the example widget or add this to your code:

```dart
import 'package:flowfit/services/watch_bridge.dart';
import 'package:flowfit/models/heart_rate_data.dart';

final watchBridge = WatchBridgeService();

// 1. Request permission
final granted = await watchBridge.requestBodySensorPermission();

// 2. Connect
final connected = await watchBridge.connectToWatch();

// 3. Start tracking
final started = await watchBridge.startHeartRateTracking();

// 4. Listen to data
watchBridge.heartRateStream.listen((HeartRateData data) {
  print('❤️ ${data.bpm} BPM');
  print('📊 ${data.ibiValues.length} IBI values');
  print('✅ Status: ${data.status}');
});

// 5. Stop when done
await watchBridge.stopHeartRateTracking();
await watchBridge.disconnectFromWatch();
```

### Step 3: See It Work

1. **Wear the watch** on your wrist (sensor needs skin contact)
2. **Grant permission** when prompted
3. **Wait 5-10 seconds** for readings to stabilize
4. **See heart rate** updating every 1-2 seconds

## 📱 Example Widget

Copy `lib/examples/heart_rate_example.dart` to see a complete working example with UI.

## 🐛 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| "Connection Failed" | Restart watch, check Samsung Health installed |
| "Permission Denied" | Settings → Apps → FlowFit → Enable Body Sensors |
| No heart rate data | Wear watch properly, tighten band |
| "Sensor Not Supported" | Need Galaxy Watch4 or higher |

## 📊 What You Get

```dart
HeartRateData {
  bpm: 72,                    // Heart rate in BPM
  ibiValues: [850, 845, 855], // Inter-beat intervals (ms)
  timestamp: DateTime.now(),   // When reading was taken
  status: SensorStatus.active  // active, inactive, error
}
```

## 🎯 Integration Examples

### Dashboard Display
```dart
StreamBuilder<HeartRateData>(
  stream: watchBridge.heartRateStream,
  builder: (context, snapshot) {
    if (snapshot.hasData && snapshot.data!.bpm != null) {
      return Text('${snapshot.data!.bpm} BPM');
    }
    return Text('--');
  },
)
```

### Workout Tracking
```dart
// Start
await watchBridge.connectToWatch();
await watchBridge.startHeartRateTracking();

// During workout
final heartRates = <HeartRateData>[];
watchBridge.heartRateStream.listen((data) {
  heartRates.add(data);
});

// End
await watchBridge.stopHeartRateTracking();
final avgHR = heartRates.map((d) => d.bpm ?? 0).reduce((a, b) => a + b) / heartRates.length;
```

### Save to Supabase
```dart
watchBridge.heartRateStream.listen((data) async {
  if (data.bpm != null) {
    await supabase.from('heart_rate').insert({
      'bpm': data.bpm,
      'timestamp': data.timestamp.toIso8601String(),
      'ibi_values': data.ibiValues,
    });
  }
});
```

## 📚 Full Documentation

- **SAMSUNG_HEALTH_SETUP_GUIDE.md** - Complete setup guide
- **IMPLEMENTATION_CHECKLIST.md** - Detailed testing steps
- **SAMSUNG_HEALTH_IMPLEMENTATION_SUMMARY.md** - What was implemented

## ✨ Key Features

✅ Real-time heart rate monitoring
✅ Inter-beat interval (IBI) data for HRV
✅ Automatic error handling
✅ Connection state management
✅ Permission handling
✅ Stream-based data delivery

## 🎉 You're Ready!

Everything is implemented and tested. Just build, deploy, and start tracking heart rate on your Galaxy Watch!
