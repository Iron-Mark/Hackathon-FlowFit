# FlowFit

Parent-supervised kids fitness for Wear OS, Android, and Flutter web. Built with
Flutter and integrated with Samsung Health Sensor SDK where supported.

> Documentation lives in [`docs/`](docs/). Start with [docs/INDEX.md](docs/INDEX.md)
> and [AGENTS.md](AGENTS.md) for current status.

## Overview

FlowFit runs on:
- **Galaxy Watch (Wear OS)** - heart-rate and workout sessions
- **Android Phone** - companion tracking, goals, and settings
- **Flutter web** - landing page, public privacy/deletion pages, and browser preview

### Key Features
- Real-time heart-rate monitoring with Samsung Health Sensor SDK (where supported)
- Inter-beat interval (IBI) data for HRV-oriented sessions
- Workout and wellness tracking (walking, running, resistance, missions)
- Watch ↔ phone sync
- Parent-supervise account path with self-attested age gate
- Supabase backend sync when configured with a live project

## Architecture

```
┌─────────────────────────────────────┐
│     Galaxy Watch (Wear OS)          │
│  - Heart rate monitoring            │
│  - Activity tracking                │
│  - Sleep tracking                   │
│  - Real-time sensor data            │
└──────────────┬──────────────────────┘
               │ Wearable Data Layer
               │ (MessageClient/DataClient)
┌──────────────▼──────────────────────┐
│     Android Phone (Companion)       │
│  - Data visualization               │
│  - Historical analysis              │
│  - Detailed reports                 │
│  - Settings management              │
└──────────────┬──────────────────────┘
               │ Supabase API
┌──────────────▼──────────────────────┐
│     Supabase Backend                │
│  - PostgreSQL database              │
│  - Real-time subscriptions          │
│  - Authentication                   │
│  - Cloud storage                    │
└─────────────────────────────────────┘
```

## Devices

Example hardware IDs below are from past local sessions. Always run
`flutter devices` and `adb devices` on your machine.

### Watch Device (example)
- **Model**: Galaxy Watch (SM_R930)
- **Platform**: Wear OS powered by Samsung
- **Purpose**: Primary health tracking device
- **Run Command**: `flutter run -d <watch-device-id> -t lib/main_wear.dart`

### Phone Device (example)
- **Purpose**: Companion app for data visualization
- **Run Command**: `pwsh -NoProfile -File scripts/run_phone.ps1` or
  `scripts\run_phone.bat` on Windows

## Quick Start

### Prerequisites

**Hardware:**
- Galaxy Watch4 or higher (Wear OS 3.0+)
- Android phone (API 23+)
- Both devices paired via Galaxy Wearable app

**Software:**
- Flutter SDK 3.41.9 stable (CI/release baseline; `pubspec.yaml` uses Dart
  SDK constraint `^3.10.0`)
- Android Studio with Kotlin support
- Samsung Health app installed on watch
- Supabase account (for backend)

### Installation

1. **Clone and setup**
   ```bash
   git clone <repository-url>
   cd flowfit
   flutter pub get
   pwsh scripts/fetch_fonts.ps1   # downloads General Sans (not committed; Fontshare license)
   ```

2. **Configure Supabase**
   - Preferred: pass `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` with
     `--dart-define`. For local phone runs, `scripts\run_phone.bat` reads those
     values from the environment or ignored `lib/secrets.dart` and passes them
     to Flutter.
   - Optional local fallback: copy `lib/secrets.dart.example` to
     `lib/secrets.dart` for scripts that read the ignored fallback file.
   - Do not put service-role or secret keys in the Flutter app

3. **Deploy to devices**
   ```bash
   # Watch app
   scripts\test-watch.bat
   
   # Phone app (in another terminal)
   scripts\test-phone.bat
   ```

### Web Landing Page

Flutter web builds render the FlowFit marketing landing page at `/`. The app
startup path is still available at `/#/app`, and direct app routes such as
`/#/welcome` continue to work for smoke tests and previews. The landing page
uses `FLOWFIT_APK_DOWNLOAD_URL` for its APK CTA and defaults to the maintained
fork's latest GitHub release page until a signed APK artifact URL is supplied.

Public Pages origin:
`https://iron-mark.github.io/Hackathon-FlowFit/`

### Testing Connection

1. Start phone app first
2. Start watch app
3. On watch: tap "Heart Rate" → "START"
4. Wait for heart rate reading
5. Tap "SEND" → check phone receives data

**Troubleshooting?** See [WATCH_CONNECTION_GUIDE.md](docs/WATCH_CONNECTION_GUIDE.md)

## 🔧 Samsung Health Sensor Integration

### Setup

The app uses Samsung Health Sensor SDK for real-time heart rate monitoring. See detailed setup guides:

- **[docs/QUICK_START.md](docs/QUICK_START.md)** - 5-minute quick start
- **[SAMSUNG_HEALTH_SETUP_GUIDE.md](docs/SAMSUNG_HEALTH_SETUP_GUIDE.md)** - Complete setup guide

### Usage Example

```dart
import 'package:flowfit/services/watch_bridge.dart';

final watchBridge = WatchBridgeService();

// 1. Request permission
await watchBridge.requestBodySensorPermission();

// 2. Connect to Samsung Health
await watchBridge.connectToWatch();

// 3. Start tracking
await watchBridge.startHeartRateTracking();

// 4. Listen to heart rate data
watchBridge.heartRateStream.listen((data) {
  print('Heart Rate: ${data.bpm} BPM');
  print('IBI Values: ${data.ibiValues}');
});

// 5. Stop tracking
await watchBridge.stopHeartRateTracking();
```

### Heart Rate Data Structure

```dart
HeartRateData {
  bpm: 72,                    // Heart rate in beats per minute
  ibiValues: [850, 845, 855], // Inter-beat intervals (ms)
  timestamp: DateTime.now(),   // When reading was taken
  status: SensorStatus.active  // active, inactive, error
}
```

## 📊 Features

### Watch App Features

1. **Clean Dashboard** (`lib/screens/wear/wear_dashboard.dart`)
   - Compact shortcuts for Heart Rate, Workout, and Relax
   - Minimal, focused design with ambient mode kept non-interactive
   - Optimized for small screens

2. **Heart Rate Monitor** (`lib/screens/wear/wear_heart_rate_screen.dart`)
   - Large BPM display (56pt font)
   - Simple START/STOP button
   - One-tap SEND to phone
   - Real-time status indicator
   - Samsung Health SDK integration
   - IBI data collection

3. **Workout and Relax Tools** (`lib/screens/wear/workout_screen.dart`, `lib/screens/wear/relax_screen.dart`)
   - Local workout timer with BPM and calorie estimates
   - Guided breathing session timer
   - Directly reachable from the Wear dashboard

### Phone App Features

1. **Dashboard** (`lib/screens/dashboard_screen.dart`)
   - Overview of all health metrics
   - Historical data charts
   - Sync status

2. **Workout Tracking** (`lib/screens/workout/workout_type_selection_screen.dart`)
   - Running, walking, and resistance workout flows
   - Workout history
   - Performance analytics

## 🔌 Data Synchronization

### Watch → Phone Transfer

The app uses Wearable Data Layer API for real-time data transfer:

```dart
// On Watch: Send heart rate data
messageClient.sendMessage(
  nodeId,
  "/heart_rate",
  jsonEncode(heartRateData)
);

// On Phone: Receive data
class DataListenerService extends WearableListenerService {
  @override
  void onMessageReceived(MessageEvent messageEvent) {
    final data = jsonDecode(messageEvent.data);
    // Process and display data
  }
}
```

### Supabase Sync

When the app is launched with real `SUPABASE_URL` and
`SUPABASE_PUBLISHABLE_KEY` values, both devices can sync to Supabase for
persistent storage:

```dart
// Save heart rate to Supabase
await supabase.from('heart_rate').insert({
  'user_id': userId,
  'bpm': heartRateData.bpm,
  'timestamp': heartRateData.timestamp.toIso8601String(),
  'ibi_values': heartRateData.ibiValues,
});
```

## 🗂️ Project Structure

```
flowfit/
├── android/
│   ├── app/
│   │   ├── libs/
│   │   │   └── samsung-health-sensor-api-1.4.1.aar
│   │   └── src/main/kotlin/com/msiazondev/flowfit/
│   │       ├── MainActivity.kt
│   │       └── HealthTrackingManager.kt
│   └── build.gradle.kts
├── lib/
│   ├── main.dart                    # Phone app entry
│   ├── main_wear.dart               # Watch app entry
│   ├── models/
│   │   ├── heart_rate_data.dart
│   │   ├── sensor_status.dart
│   │   └── workout_session.dart
│   ├── services/
│   │   ├── watch_bridge.dart        # Samsung Health SDK bridge
│   │   ├── supabase_service.dart    # Backend service
│   │   └── phone_data_listener.dart
│   └── screens/
│       ├── wear/                    # Watch-specific screens
│       └── workout/
├── docs/                            # Documentation
│   ├── QUICK_START.md
│   ├── SAMSUNG_HEALTH_SETUP_GUIDE.md
│   ├── INSTALLATION_TROUBLESHOOTING.md
│   ├── HEART_RATE_DATA_FLOW.md
│   └── WEAR_OS_SETUP.md
├── scripts/                         # Build and run scripts
│   ├── build_and_install.bat
│   ├── run_watch.bat
│   └── run_phone.bat
├── pubspec.yaml
└── README.md
```

## 🐛 Troubleshooting

### Build Issues

**"Unresolved reference: ConnectionListener"**
```bash
# Clean and rebuild
flutter clean
flutter pub get
pwsh -NoProfile -File scripts\run_phone.ps1 -Device <device-id>
```

**"JVM-target compatibility detected"**
- Check `android/app/build.gradle.kts`
- Ensure `jvmTarget = "17"` is set

### Runtime Issues

**"Connection Failed" on Watch**
- Ensure Samsung Health is installed
- Check watch supports Samsung Health Sensor SDK
- Restart watch and try again

**"Permission Denied"**
- Go to Settings → Apps → FlowFit → Permissions
- Enable "Body sensors" permission

**No Heart Rate Data**
- Wear watch on wrist (sensor needs skin contact)
- Tighten watch band
- Clean sensor on back of watch

### Data Sync Issues

**Watch not sending data to phone**
- Check both devices are paired
- Verify Galaxy Wearable app is running
- Check network connectivity

**Supabase sync failing**
- Verify `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` dart defines, or the
  ignored `lib/secrets.dart` fallback used by release scripts
- Check internet connection
- Review Supabase logs

## 📚 Documentation

**📖 [Complete Documentation Index](docs/INDEX.md)** - Full list of all documentation

### 🚀 Quick Links
- **[docs/QUICK_START.md](docs/QUICK_START.md)** - ⭐ **Start here!** Quick guide to run and test the app
- **[NAVIGATION_GUIDE.md](docs/NAVIGATION_GUIDE.md)** - 🗺️ **How to access heart rate monitoring UI**
- **[GETTING_STARTED.md](docs/GETTING_STARTED.md)** - Initial setup guide
- **[WATCH_TO_PHONE_COMPLETE_FLOW.md](docs/WATCH_TO_PHONE_COMPLETE_FLOW.md)** - Live data flow from watch to phone
- **[RELEASE_READINESS_RUNBOOK.md](docs/RELEASE_READINESS_RUNBOOK.md)** - Store/web release readiness and remaining external gates

### 🐛 Troubleshooting
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Connection and general issues
- **[SMARTWATCH_TO_PHONE_DATA_FLOW.md](docs/SMARTWATCH_TO_PHONE_DATA_FLOW.md)** - Complete data flow guide

## 🔐 Permissions

### Watch App Permissions
- `BODY_SENSORS` - Heart rate and health sensors
- `FOREGROUND_SERVICE` - Background tracking
- `FOREGROUND_SERVICE_HEALTH` - Health-specific services
- `WAKE_LOCK` - Keep device awake during tracking
- `ACTIVITY_RECOGNITION` - Activity detection

### Phone App Permissions
- `INTERNET` - Supabase sync
- `ACCESS_NETWORK_STATE` - Network status
- `WAKE_LOCK` - Background sync

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.41.9 stable
- **Language**: Dart
- **Backend**: Supabase (PostgreSQL)
- **Watch SDK**: Samsung Health Sensor SDK 1.4.1
- **Wearable**: Wear OS 3.0+
- **Communication**: Wearable Data Layer API
- **State Management**: Provider
- **Charts**: fl_chart
- **Location**: geolocator, google_maps_flutter
- **Sensors**: sensors_plus, wear_plus

## 📈 Roadmap

- [x] Watch-to-phone data transfer path (Wear OS companion builds)
- [ ] Add workout heart rate zones
- [ ] Implement HRV analysis and trends
- [ ] Add resting heart rate calculation
- [ ] Background heart rate monitoring
- [ ] Heart rate alerts (too high/low)
- [ ] Sleep quality scoring
- [ ] Nutrition recommendations
- [ ] Social features and challenges

## 🤝 Contributing

Contributions are welcome! Please read the contributing guidelines before submitting PRs.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Samsung Health Sensor SDK
- Flutter team
- Supabase team
- VGV (Very Good Ventures) for Wear OS best practices

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review the documentation files
3. Check logcat: `adb logcat | grep -i health`
4. Open an issue on GitHub

---

## 🚀 Quick Commands

### Build & Install
```bash
# Automated build and install on watch
scripts\build_and_install.bat

# Run on watch
scripts\run_watch.bat

# Run on phone
scripts\run_phone.bat
```

### Manual Commands
```bash
# Watch (SM_R930 - Galaxy Watch)
flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp -t lib/main_wear.dart

# Phone (22101320G)
scripts\run_phone.bat
```

> ⚠️ **Important**: Always use `-t lib/main_wear.dart` for watch to get Wear OS UI, not phone UI!

### Troubleshooting
```bash
# View logs
adb -s 6ece264d logcat | findstr "FlowFit"

# Check devices
adb devices

# Uninstall
adb -s 6ece264d uninstall com.msiazondev.flowfit
```

---

**For detailed documentation, see the [docs/](docs/) folder.**
