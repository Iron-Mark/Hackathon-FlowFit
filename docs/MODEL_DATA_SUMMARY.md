# TensorFlow Lite Model - Data Summary

## 📊 Quick Reference

| Data Type | Source | Rate | Units | Range | Status |
|-----------|--------|------|-------|-------|--------|
| **AccX** | Watch sensor batch or phone fallback | 32 Hz | m/s² | -20 to +20 | Parser wired; hardware proof pending |
| **AccY** | Watch sensor batch or phone fallback | 32 Hz | m/s² | -20 to +20 | Parser wired; hardware proof pending |
| **AccZ** | Watch sensor batch or phone fallback | 32 Hz | m/s² | -20 to +20 | Parser wired; hardware proof pending |
| **BPM** | Watch Heart Rate | 1 Hz | BPM | 40-200 | Working in app flow |

## 🎯 Model Requirements

```
Input Shape: [320, 4]
- 320 samples = 10 seconds @ 32Hz
- 4 features = [AccX, AccY, AccZ, BPM]

Output: [3 probabilities]
- Stress probability (0-1)
- Cardio probability (0-1)
- Strength probability (0-1)
```

## 📦 Data Packet Format

### JSON Format:
```json
{
  "type": "sensor_batch",
  "timestamp": 1732545971348,
  "bpm": 78,
  "sample_rate": 32,
  "count": 2,
  "accelerometer": [
    [0.15, -0.23, 9.81],
    [0.12, -0.19, 9.79]
  ]
}
```

### Send Rate:
- Batches are parsed as combined accelerometer + BPM packets.
- Each accelerometer sample becomes `[accX, accY, accZ, bpm]` for the model.

## Watch-Side Hardware Contract

### 1. Accelerometer Setup (Kotlin)
```kotlin
// Get sensor
val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

// Register at 32Hz
sensorManager.registerListener(
    listener,
    accelerometer,
    SensorManager.SENSOR_DELAY_GAME // ~20ms
)
```

### 2. Combine with Heart Rate
```kotlin
// For each accelerometer reading
val data = mapOf(
    "timestamp" to System.currentTimeMillis(),
    "accX" to event.values[0],
    "accY" to event.values[1],
    "accZ" to event.values[2],
    "bpm" to currentBpm
)
```

### 3. Send to Phone
```kotlin
// Via Wearable Data Layer
val json = JSONObject(data).toString()
sendMessageToPhone("/sensor_data", json.toByteArray())
```

## Phone Side

### Current Status:
- Receives heart rate from watch.
- Uses phone accelerometer as fallback.
- Parses combined watch sensor batches in `PhoneDataListener`.
- Converts sensor batches into `[accX, accY, accZ, bpm]` feature vectors.
- Buffers 320 samples, runs TFLite inference, and displays classification.

## 🎯 Implementation Priority

### High Priority:
1. Heart rate from watch - implemented.
2. Combined sensor batch parser - implemented in Flutter.
3. Watch accelerometer hardware validation - pending paired-device QA.

### Medium Priority:
4. Battery optimization
5. Data quality validation
6. Error handling

### Low Priority:
7. Data compression
8. Offline buffering
9. Historical data export

## 📝 Files to Modify

### Watch Side:
- Keep native Wear data-layer messages aligned with the sensor-batch JSON shape
  above.

### Phone Side:
- `lib/services/phone_data_listener.dart` receives and validates watch batches.
- `lib/features/activity_classifier/presentation/tracker_page.dart` consumes
  watch batches when Watch mode is selected, with phone accelerometer fallback.

## 🚀 Quick Start

### To test with current setup:
```bash
# Run app
flutter run -d 6ece264d

# Navigate to Activity AI
# Select "Watch" mode
# Uses watch batches when available, otherwise phone accelerometer fallback
```

### Paired-device validation:
```bash
# Requires a real Wear device or a working phone + Wear emulator pair
# Verify Watch mode receives sensor_batch payloads and classifies activity
```

## 📊 Data Flow

```
Watch Sensors → Watch App → Wearable Data Layer → Phone App → TFLite Model → UI
```

**Current app path:**
```
Watch HR ✅ → Phone ✅ → Model ✅
Phone Accel ✅ → Model ✅
```

**Hardware validation target:**
```
Watch HR -> Phone -> Model
Watch Accel -> Phone -> Model
```

---

See **TFLITE_MODEL_DATA_REQUIREMENTS.md** for complete implementation details.
