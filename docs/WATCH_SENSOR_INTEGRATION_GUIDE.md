# 🎯 Watch Sensor Integration for TensorFlow Model Testing

## Overview

The Activity AI Classifier now supports **real-time sensor data from Galaxy Watch**, allowing you to test the TensorFlow Lite model with actual watch accelerometer and heart rate data instead of simulated data.

## 🔄 Integration Architecture

```
Galaxy Watch → Wearable Data Layer → Phone Data Listener → TensorFlow Model
     ↓                                        ↓
[Accelerometer]                      [Sensor Batch Stream]
[Heart Rate]                         [Feature Vectors: accX, accY, accZ, bpm]
```

## 📱 Available Data Sources

### Accelerometer Sources
1. **Phone** - Uses phone's built-in accelerometer via `sensors_plus`
2. **Simulation** - Generates synthetic sinusoidal accelerometer data
3. **Watch** - Uses Galaxy Watch accelerometer via Wearable Data Layer

### Heart Rate Sources
1. **Simulation** - Manual slider control (60-180 BPM)
2. **Plugin** - Uses `heart_bpm` plugin (camera-based)
3. **Watch HR** - Uses Galaxy Watch heart rate sensor

## 🎮 How to Use Watch Integration

### Option 1: Watch Accelerometer + Watch Heart Rate (Recommended)
This uses the **complete sensor batch** from the watch, which includes both accelerometer and heart rate data synchronized together.

**Steps:**
1. Open the Activity AI Classifier test page (`/trackertest`)
2. Select **"Watch"** under "Accelerometer Source"
3. The heart rate will automatically come from the watch sensor batch
4. Wait for the buffer to fill (320 samples)
5. The model will start classifying your activity

**Benefits:**
- ✅ Perfectly synchronized data (same timestamp)
- ✅ Real-world sensor data
- ✅ Tests actual watch integration
- ✅ No simulation needed

### Option 2: Phone Accelerometer + Watch Heart Rate
Uses phone's accelerometer but watch's heart rate sensor.

**Steps:**
1. Select **"Phone"** under "Accelerometer Source"
2. Select **"Watch HR"** under "Heart Rate Source"
3. Move your phone to generate accelerometer data
4. Heart rate comes from watch

### Option 3: Simulation Mode
For testing without hardware.

**Steps:**
1. Select **"Simulation"** under "Accelerometer Source"
2. Select **"Simulation"** under "Heart Rate Source"
3. Adjust amplitude and frequency sliders
4. Adjust heart rate slider

## 📊 Data Format

### Sensor Batch from Watch
The watch sends batches of 32 samples at ~32Hz sampling rate:

```json
{
  "type": "sensor_batch",
  "timestamp": 1234567890,
  "bpm": 75,
  "sample_rate": 32,
  "count": 32,
  "accelerometer": [
    [0.12, -0.45, 9.81],
    [0.15, -0.42, 9.79],
    ...
  ]
}
```

### Feature Vectors
Each sample is converted to a 4-feature vector:
```dart
[accX, accY, accZ, bpm]
```

Example:
```dart
[0.12, -0.45, 9.81, 75.0]
```

### Model Input Window
The model requires exactly **320 samples** (10 seconds @ 32Hz):
```dart
List<List<double>> input = [
  [accX1, accY1, accZ1, bpm1],
  [accX2, accY2, accZ2, bpm2],
  ...
  [accX320, accY320, accZ320, bpm320]
]
```

## 🔧 Implementation Details

### PhoneDataListener Service
Located at: `lib/services/phone_data_listener.dart`

**Key Methods:**
- `startListening()` - Starts listening for watch data
- `stopListening()` - Stops listening
- `sensorBatchStream` - Stream of sensor batches from watch
- `heartRateStream` - Stream of heart rate only

### Tracker Page Integration
Located at: `lib/features/activity_classifier/presentation/tracker_page.dart`

**Key Features:**
- Automatic buffer management (sliding window of 320 samples)
- Real-time status display
- Source selection UI
- Error handling

### Code Example
```dart
// Subscribe to watch sensor batches
final phoneListener = Provider.of<PhoneDataListener>(context, listen: false);
phoneListener.startListening();

_sensorBatchSub = phoneListener.sensorBatchStream.listen((sensorBatch) {
  // Add all samples to buffer
  for (final sample in sensorBatch.samples) {
    _dataBuffer.add(sample); // [accX, accY, accZ, bpm]
    
    if (_dataBuffer.length > 320) {
      _dataBuffer.removeAt(0); // Sliding window
    }
  }
  
  // Run inference when buffer is full
  if (_dataBuffer.length == 320) {
    _runInference();
  }
});
```

## 📈 Status Indicators

The tracker page shows real-time status:

### Connection Status
- ✅ **Green checkmark** - Watch connected and sending data
- ⚠️ **Orange warning** - Waiting for watch data
- ❌ **Red error** - Connection failed

### Buffer Status
- Shows current buffer size: `Buffer: 320/320 samples`
- Green when full, orange when filling

### Data Source Display
- Shows which accelerometer source is active
- Shows which heart rate source is active
- Shows if using complete sensor batch from watch

## 🧪 Testing Scenarios

### Scenario 1: Stress Detection
1. Use watch integration
2. Sit still (low accelerometer activity)
3. Increase heart rate by exercising
4. Model should detect "Stress" when HR is high but movement is low

### Scenario 2: Cardio Activity
1. Use watch integration
2. Run or do jumping jacks
3. Both accelerometer and heart rate should be high
4. Model should detect "Cardio"

### Scenario 3: Strength Training
1. Use watch integration
2. Do resistance exercises (push-ups, weights)
3. Moderate heart rate, periodic movement bursts
4. Model should detect "Strength"

## 🐛 Troubleshooting

### Watch Not Connecting
**Problem:** Status shows "Waiting for watch data..."

**Solutions:**
1. Make sure watch app is running
2. Check Bluetooth connection
3. Restart watch app
4. Check phone's Bluetooth permissions
5. Call `startListening()` before subscribing to stream

### No Data in Buffer
**Problem:** Buffer stays at 0 samples

**Solutions:**
1. Verify watch is sending data (check watch app logs)
2. Check if `PhoneDataListener.startListening()` was called
3. Verify Wearable Data Layer is configured correctly
4. Check for errors in console

### Model Not Classifying
**Problem:** Buffer fills but no classification results

**Solutions:**
1. Check if TensorFlow Lite model is loaded
2. Verify model input shape matches (320, 4)
3. Check for errors in ViewModel
4. Ensure inference is not already running

### Incorrect Classifications
**Problem:** Model gives wrong activity predictions

**Solutions:**
1. Verify sensor data is correct (check raw values)
2. Ensure BPM values are reasonable (40-200)
3. Check accelerometer units (should be m/s²)
4. Retrain model with more diverse data

## 📋 Requirements Met

This implementation satisfies the following requirements:

- ✅ **Req 2.4**: Receive sensor batches from watch via Wearable Data Layer
- ✅ **Req 2.5**: Construct 4-feature vectors [accX, accY, accZ, bpm]
- ✅ **Req 8.2**: Stream heart rate data from watch
- ✅ **Req 8.3**: Log sensor data reception with timestamps
- ✅ **Req 9.4**: Validate JSON data from watch

## 🚀 Next Steps

### Phase 1: Current Implementation ✅
- [x] Watch sensor batch integration
- [x] Real-time data streaming
- [x] UI for source selection
- [x] Status indicators

### Phase 2: Enhancements
- [ ] Add data recording/playback
- [ ] Show raw sensor values in UI
- [ ] Add confidence threshold settings
- [ ] Export classification results

### Phase 3: Production
- [ ] Background processing
- [ ] Battery optimization
- [ ] Offline model updates
- [ ] Cloud sync for training data

## 📚 Related Documentation

- [Activity AI Watch Integration](implementation/ACTIVITY_AI_WATCH_INTEGRATION.md)
- [TensorFlow Model Data Requirements](TFLITE_MODEL_DATA_REQUIREMENTS.md)
- [IBI Data Collection Guide](IBI_DATA_COLLECTION_GUIDE.md)
- [Sensor Data Flow Debug](DEBUG_SENSOR_DATA_FLOW.md)

## 🎯 Summary

The watch sensor integration allows you to:
1. **Test the TensorFlow model with real watch data**
2. **Validate the complete data pipeline** (watch → phone → model)
3. **Compare different data sources** (phone vs watch vs simulation)
4. **Debug sensor data issues** with real-time status display

This is a critical step toward deploying the activity classification model in production with Galaxy Watch integration.
