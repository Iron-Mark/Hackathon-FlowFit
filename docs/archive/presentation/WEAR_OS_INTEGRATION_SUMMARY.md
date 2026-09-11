# Wear OS Integration - Quick Technical Summary

## 🎯 What You Need to Know for Presentation

### The Big Picture
Your Galaxy Watch collects movement + heart rate data → Sends it to your phone via Bluetooth → Phone runs AI to detect if you're stressed, doing cardio, or calm → Shows result on screen in real-time

---

## 🔧 Technical Stack

### Watch Side (Wear OS - Kotlin)
- **Samsung Health SDK** - Access to sensors
- **Accelerometer** - 32 Hz sampling (32 readings/second)
- **Heart Rate Sensor** - Optical sensor on watch back
- **WatchSensorService** - Manages sensor data collection
- **WatchToPhoneSyncManager** - Sends data to phone

### Communication (Bluetooth)
- **Google Wearable Data Layer API** - High-level BLE abstraction
- **MessageClient** - Sends small messages from watch to phone
- **CapabilityClient** - Discovers phones with your app installed
- **Automatic reconnection** - Handles connection drops

### Phone Side (Android - Kotlin)
- **PhoneDataListenerService** - Background service that receives watch data
- **WearableListenerService** - System-managed, auto-starts when watch sends data
- **EventChannel** - Bridge from native Android to Flutter

### Flutter Side (Dart)
- **PhoneDataListener** - Subscribes to sensor data stream
- **Active Running Screen** - Collects data in buffer
- **TensorFlow Lite** - Runs AI model on-device

---

## 📊 Data Flow (Step by Step)

### 1. Watch Collects Data
```
Every 31ms (32 Hz):
- Read accelerometer: [X, Y, Z] in g-force
- Read heart rate: BPM from optical sensor
- Add to buffer
```

### 2. Watch Batches Data
```
Every 1 second (32 samples):
- Combine 32 accelerometer readings
- Add current heart rate
- Create JSON batch
```

### 3. Watch Sends to Phone
```
Via Bluetooth (Wearable Data Layer):
- Find connected phone
- Send JSON via MessageClient
- Path: "/sensor_data"
- Size: ~2-3 KB per batch
```

### 4. Phone Receives Data
```
PhoneDataListenerService (background):
- Receives MessageEvent
- Extracts bytes → Parse JSON
- Forward to Flutter via EventChannel
```

### 5. Flutter Processes Data
```
Active Running Screen:
- Receive batch (32 samples)
- Add to rolling buffer
- When buffer has 320 samples (10 seconds):
  → Run AI inference
```

### 6. AI Analyzes
```
TensorFlow Lite:
- Input: [1, 320, 4] tensor
  - 320 samples
  - 4 features: [accX, accY, accZ, heartRate]
- Output: [stress%, cardio%, strength%]
- Takes: 50-150ms
```

### 7. UI Updates
```
Show badge:
- Red = STRESS (high intensity)
- Orange = CARDIO (optimal)
- Green = CALM (low intensity)
- Plus confidence percentage
```

---

## 🎨 JSON Data Format

### Sensor Batch (Watch → Phone)
```json
{
  "type": "sensor_batch",
  "timestamp": 1732896000000,
  "bpm": 145,
  "sample_rate": 32,
  "count": 32,
  "accelerometer": [
    [0.523, 0.312, 0.847],
    [0.534, 0.298, 0.856],
    ... (32 samples total)
  ]
}
```

**What each field means:**
- `type` - Message type identifier
- `timestamp` - When batch was created (Unix milliseconds)
- `bpm` - Current heart rate
- `sample_rate` - Samples per second (32 Hz)
- `count` - Number of samples in this batch
- `accelerometer` - Array of [X, Y, Z] vectors

---

## ⚡ Performance Numbers

### Latency Breakdown
- **Sensor reading:** 31ms (per sample)
- **Buffer accumulation:** 1 second (32 samples)
- **Bluetooth transmission:** 50-100ms
- **JSON parsing:** 5-10ms
- **Buffer fill:** 10 seconds (320 samples)
- **AI inference:** 50-150ms
- **UI update:** 16ms (60 FPS)
- **Total (first detection):** ~10-11 seconds
- **Subsequent detections:** Every 15 seconds

### Memory Usage
- **Sensor buffer:** ~10 KB (320 samples × 4 features × 8 bytes)
- **TFLite model:** ~2-5 MB
- **Total:** < 10 MB

### Battery Impact
- **Watch:** ~5-8% per hour (comparable to any fitness app)
- **Phone:** Minimal (inference every 15 seconds)
- **Optimization:** Wake lock only during active tracking

---

## 🔑 Key Technical Achievements

### 1. Cross-Platform Integration
✅ Seamless Wear OS ↔ Android ↔ Flutter communication
✅ Three different programming languages working together (Kotlin, Java, Dart)

### 2. Real-Time Processing
✅ Sub-second latency from sensor to phone
✅ Continuous streaming without blocking UI

### 3. Efficient Data Transfer
✅ Batching reduces Bluetooth overhead by 32x
✅ Only ~2-3 KB per transmission

### 4. Background Operation
✅ Works even when screen is off
✅ Wake lock keeps sensors running
✅ Background service auto-starts

### 5. On-Device AI
✅ No internet required
✅ Privacy-preserving (data never leaves device)
✅ Fast inference (50-150ms)

---

## 🎤 Presentation Sound Bites

### For Non-Technical Audience:
"Your watch measures how you move and your heart rate, sends it to your phone, and AI figures out if you're pushing too hard or can go harder."

### For Technical Audience:
"We use Samsung Health SDK for sensor access, Google Wearable Data Layer for BLE communication, and TensorFlow Lite for on-device inference. The entire pipeline from sensor to UI takes about 10 seconds with 320-sample buffering at 32 Hz."

### For Judges:
"This demonstrates full-stack mobile development: native Wear OS, Android background services, Flutter cross-platform UI, and on-device machine learning - all working together in real-time."

---

## 🐛 Common Issues & Solutions

### Issue: "No data from watch"
**Check:**
- Watch and phone are paired via Galaxy Wearable app
- Bluetooth is enabled
- Watch app is running
- Permissions granted (BODY_SENSORS, ACTIVITY_RECOGNITION)

### Issue: "AI not detecting"
**Check:**
- Buffer has 320 samples (takes 10 seconds)
- TFLite model is in assets folder
- No errors in console logs

### Issue: "Connection drops"
**Solution:**
- Wearable Data Layer API auto-reconnects
- Watch buffers data during disconnection
- Transmits when reconnected

---

## 📚 Code Locations

### Watch Side:
- `android/app/src/main/kotlin/com/example/flowfit/WatchSensorService.kt`
- `android/app/src/main/kotlin/com/example/flowfit/HealthTrackingManager.kt`
- `android/app/src/main/kotlin/com/example/flowfit/WatchToPhoneSyncManager.kt`

### Phone Side:
- `android/app/src/main/kotlin/com/example/flowfit/PhoneDataListenerService.kt`
- `android/app/src/main/kotlin/com/example/flowfit/MainActivity.kt`

### Flutter Side:
- `lib/services/phone_data_listener.dart`
- `lib/screens/workout/running/active_running_screen.dart`
- `lib/features/activity_classifier/platform/tflite_activity_classifier.dart`

---

## 🎯 Demo Checklist

Before presenting:
- [ ] Galaxy Watch is charged and paired
- [ ] Watch app is installed and running
- [ ] Phone app is installed
- [ ] Bluetooth is enabled on both devices
- [ ] Permissions are granted
- [ ] Test the connection (check logs)
- [ ] Have backup video ready

During demo:
- [ ] Show watch collecting data (check watch screen)
- [ ] Show phone receiving data (check logs)
- [ ] Show "Analyzing..." badge (first 10 seconds)
- [ ] Show detection result (after 10 seconds)
- [ ] Show mode changes (walk → jog → sprint)
- [ ] Show probability breakdown
- [ ] Show live heart rate indicator

---

## 💡 Key Talking Points

1. **Real-time AI** - Not just tracking, but intelligent analysis
2. **On-device processing** - Privacy-preserving, no cloud
3. **Cross-platform** - Wear OS + Android + Flutter working together
4. **Production-ready** - Proper error handling, battery optimization
5. **Scalable** - Can add more features easily

---

**Remember:** Focus on the user benefit first, then dive into technical details when judges ask questions!
