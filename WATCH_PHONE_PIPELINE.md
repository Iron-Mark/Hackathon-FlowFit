# FlowFit — Watch → Phone Data Pipeline

## Overview

FlowFit is a Flutter app with **two separate entry points**:

| Entry Point | Target | File |
|---|---|---|
| Phone app | Android phone | `lib/main.dart` |
| Watch app | Galaxy Watch (Wear OS) | `lib/main_wear.dart` |

The watch reads heart rate and accelerometer data using the Samsung Health SDK, then streams it to the phone in real time via the Google Wearable Data Layer.

---

## Architecture at a Glance

```
[Galaxy Watch 5]                          [Android Phone]
     |                                          |
Samsung Health SDK                      PhoneDataListener
     | (HR + IBI)                         (EventChannel)
     v                                          ^
HealthTrackingManager                          |
     |                                  PhoneDataListenerService
     v                                    (Kotlin, receives)
WatchSensorService                             ^
     | (Accel batches)                         |
     v                                  Wearable Data Layer
WatchToPhoneSyncManager  ------------>  (MessageClient)
     | /heart_rate                       /heart_rate
     | /sensor_data                      /sensor_data
```

---

## Layer-by-Layer Breakdown

### 1. Watch Side — Data Collection

**File:** `android/app/src/main/kotlin/com/example/flowfit/HealthTrackingManager.kt`

- Connects to Samsung Health SDK via `HealthTrackingService`
- Tracks `HealthTrackerType.HEART_RATE_CONTINUOUS`
- A reading is **valid** only when:
  - `hrStatus == 1` (sensor locked on skin)
  - `ibiStatus == 0 && ibiValue != 0`
- After HR starts, also starts `WatchSensorService` for accelerometer

**File:** `android/app/src/main/kotlin/com/example/flowfit/WatchSensorService.kt`

- Reads accelerometer at `32 Hz`
- Buffers `32 samples` per batch (`BUFFER_SIZE = 32`)
- Transmits every `~1 second` (`MIN_TRANSMISSION_INTERVAL_MS = 1000`)
- Sends JSON batch to phone via path `/sensor_data`:
  ```json
  {
    "type": "sensor_batch",
    "timestamp": 1234567890,
    "bpm": 85,
    "sampleRate": 32,
    "count": 32,
    "accelerometer": [[x, y, z], [x, y, z], ...]
  }
  ```

---

### 2. Watch Side — Transmission

**File:** `android/app/src/main/kotlin/com/example/flowfit/WatchToPhoneSyncManager.kt`

- Uses Google's `MessageClient` (Wearable Data Layer)
- Paths used:
  - `/heart_rate` — HR + IBI JSON
  - `/sensor_data` — accelerometer batch JSON
- Node discovery strategy:
  1. Looks for node advertising capability `flowfit_phone_app`
  2. Falls back to all connected nodes if none found
- Capability declared in `android/app/src/main/res/values/wear.xml`

**HR JSON payload sent on `/heart_rate`:**
```json
{
  "timestamp": 1234567890,
  "bpm": 84,
  "status": "active",
  "ibiValues": [780, 790, 775]
}
```

---

### 3. Watch Side — Flutter Bridge

**File:** `lib/services/watch_bridge.dart` (`WatchBridgeService`)

Flutter talks to Kotlin via Platform Channels:

| Channel | Type | Purpose |
|---|---|---|
| `com.flowfit.watch/data` | MethodChannel | Start/stop tracking commands |
| `com.flowfit.watch/sync` | MethodChannel | Send HR data to phone |
| `com.flowfit.watch/heartrate` | EventChannel | Stream live HR readings to Dart |

- `heartRateStream` emits every new HR reading
- `_autoSyncToPhone()` is called automatically on every reading — no manual trigger needed
- `sendHeartRateToPhone()` routes through `com.flowfit.watch/sync`

---

### 4. Phone Side — Reception

**File:** `android/app/src/main/kotlin/com/example/flowfit/MainActivity.kt`

- Registers a `wearableMessageListener` in the foreground
- Handles incoming Wearable messages:
  - `/heart_rate` → pushes to `PhoneDataListenerService.eventSink`
  - `/sensor_data` → pushes to `PhoneDataListenerService.sensorBatchEventSink`
- Holds a `PARTIAL_WAKE_LOCK` (10 min) to keep the CPU alive during tracking

---

### 5. Phone Side — Flutter Bridge

**File:** `lib/services/phone_data_listener.dart` (`PhoneDataListener`)

Singleton that exposes two streams to Flutter:

| Channel | Type | Stream |
|---|---|---|
| `com.flowfit.phone/heartrate` | EventChannel | `heartRateStream` → `HeartRateData` |
| `com.flowfit.phone/sensor_data` | EventChannel | `sensorBatchStream` → `SensorBatch` |

- Validates JSON: `timestamp` + `status` required; `bpm` + `ibiValues` optional
- `bpm: null` + `status: inactive` during Samsung Health SDK warm-up is **normal**

---

### 6. Phone Side — UI Display

**File:** `lib/screens/phone/phone_heart_rate_screen.dart` (`PhoneHeartRateScreen`)

- Route: `/phone_heart_rate`
- Subscribes to both `heartRateStream` and `sensorBatchStream`
- Displays:
  - Current BPM (large, real-time)
  - IBI values (inter-beat intervals in ms)
  - Connection status (watch icon, green/grey)
  - Test mode (toggle with bug icon): shows raw batch data, accelerometer XYZ per sample, batch count
- Keeps last **100 readings** in memory (circular buffer)

---

## Flutter UI — Watch Side

**File:** `lib/main_wear.dart`

- Entry: `main()` — async, calls `WidgetsFlutterBinding.ensureInitialized()`
- Root widget: `WatchShape` → `AmbientMode` → `MaterialApp`
- Theme switches automatically between **active** (colorful) and **ambient** (monochrome, battery-saving)

**File:** `lib/screens/wear/wear_dashboard.dart`

- Shows FlowFit logo + "Heart Rate" button
- On button tap: pushes `WearHeartRateScreen` wrapped in a live `AmbientMode` builder so mode updates propagate mid-session

**File:** `lib/screens/wear/wear_heart_rate_screen.dart`

- Calls `WatchBridgeService` to start Samsung Health SDK tracking
- Displays live BPM on screen
- Sends data to phone via `_watchBridge.sendHeartRateToPhone()`
- Handles ambient mode (dim display, minimal UI)

---

## Data Flow — Step by Step

1. User opens watch app → taps "Heart Rate"
2. `WearHeartRateScreen` calls `_watchBridge.startTracking()`
3. Kotlin `HealthTrackingManager` connects to Samsung Health SDK
4. Samsung Health SDK begins `HEART_RATE_CONTINUOUS` tracking
5. Each valid reading → `HealthTrackingManager` fires event
6. `WatchSensorService` buffers accelerometer at 32Hz
7. Every ~1s: `WatchToPhoneSyncManager` sends `/heart_rate` + `/sensor_data` over Wearable Data Layer
8. Phone `MainActivity.wearableMessageListener` receives messages
9. Data pushed to `PhoneDataListenerService` event sinks
10. `PhoneDataListener` streams emit `HeartRateData` / `SensorBatch` to Dart
11. `PhoneHeartRateScreen` updates UI with live BPM, IBI, accelerometer data

---

## Key Platform Channel Map

```
WATCH APP
  Dart → Kotlin:  com.flowfit.watch/data        (start/stop)
  Kotlin → Dart:  com.flowfit.watch/heartrate   (live HR stream)
  Dart → Kotlin:  com.flowfit.watch/sync        (send to phone)

PHONE APP
  Kotlin → Dart:  com.flowfit.phone/heartrate   (HR from watch)
  Kotlin → Dart:  com.flowfit.phone/sensor_data (accel batches)
```

---

## Wearable Data Layer Paths

| Path | Direction | Content |
|---|---|---|
| `/heart_rate` | Watch → Phone | HR + IBI JSON |
| `/sensor_data` | Watch → Phone | 32-sample accelerometer batch JSON |

---

## Files That Matter

| File | Role |
|---|---|
| `lib/main.dart` | Phone app entry point |
| `lib/main_wear.dart` | Watch app entry point |
| `lib/screens/wear/wear_dashboard.dart` | Watch home screen |
| `lib/screens/wear/wear_heart_rate_screen.dart` | Watch HR tracking screen |
| `lib/screens/phone/phone_heart_rate_screen.dart` | Phone display screen |
| `lib/services/watch_bridge.dart` | Watch Flutter↔Kotlin bridge |
| `lib/services/phone_data_listener.dart` | Phone Flutter↔Kotlin bridge |
| `android/.../HealthTrackingManager.kt` | Samsung Health SDK wrapper |
| `android/.../WatchSensorService.kt` | Accelerometer batching |
| `android/.../WatchToPhoneSyncManager.kt` | Wearable Data Layer sender |
| `android/.../MainActivity.kt` | Phone-side Wearable receiver |
| `android/.../wear.xml` | Capability declaration (`flowfit_phone_app`) |

---

## Verified Working on Real Hardware

- **Watch:** Samsung Galaxy Watch 5 (SM-R930), ADB over WiFi
- **Phone:** Xiaomi 22101320G (MIUI), USB ADB
- Live HR streaming confirmed: 84–85 bpm
- Accelerometer batches confirmed: 32 samples @ 32Hz, ~1s interval, ~1986 bytes/batch
- Phone node "Marcus" discovered via `flowfit_phone_app` capability
- Transmission time: ~200ms per batch

---

## Run Commands

```bash
# Watch app
flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp -t lib/main_wear.dart

# Phone app
flutter run -d 6ece264d -t lib/main.dart
```

---

## Known Non-Blocking Issues

- `relation "public.user_profiles" does not exist` — Supabase table not created yet; profile features unavailable but doesn't affect the watch pipeline
- First ~10–15s after tapping Start: Samsung SDK reports `status: inactive`, `bpm: null` — this is normal sensor warm-up
