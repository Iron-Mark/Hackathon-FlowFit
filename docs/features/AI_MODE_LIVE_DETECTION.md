# AI Activity Mode - Live Detection Implementation

## Overview
Implemented **continuous, automatic AI activity mode detection** during running workouts using TensorFlow Lite. The system automatically detects and displays whether the user is in **CALM**, **STRESS**, or **CARDIO** mode in real-time without any button clicks.

## Implementation Details

### 1. Activity Mode Provider (`lib/providers/activity_mode_provider.dart`)

#### Key Features:
- **Continuous Detection**: Automatically runs every 15 seconds
- **Real-time Sensor Collection**: Collects accelerometer data continuously
- **TensorFlow Lite Integration**: Uses the existing `activity_tracker.tflite` model
- **Heart Rate Integration**: Combines accelerometer with live heart rate data

#### How It Works:
```dart
// Automatically starts when running screen loads
startContinuousDetection(heartRate: currentHeartRate)
  ↓
// Collects 320 samples of [accX, accY, accZ, bpm]
_addSensorData() → maintains rolling buffer
  ↓
// Runs inference every 15 seconds
_runDetection() → TFLite model prediction
  ↓
// Updates UI with detected mode
state = ActivityModeState(mode, confidence, probabilities)
  ↓
// Schedules next detection
_scheduleNextDetection(15 seconds)
```

#### Data Flow:
1. **Sensor Collection**: Accelerometer events → Buffer [320 samples × 4 features]
2. **Model Input**: `[accX, accY, accZ, bpm]` × 320 samples
3. **Model Output**: `[stress_prob, cardio_prob, calm_prob]`
4. **Result**: Highest probability determines the mode

### 2. Active Running Screen Integration

#### Automatic Startup:
```dart
@override
void initState() {
  // Starts detection 2 seconds after screen loads
  Future.delayed(Duration(seconds: 2), () {
    ref.read(activityModeProvider.notifier).startContinuousDetection(
      heartRate: session?.avgHeartRate,
    );
  });
}
```

#### Live Heart Rate Updates:
```dart
@override
void didUpdateWidget() {
  // Updates heart rate as it changes during workout
  if (session?.avgHeartRate != null) {
    ref.read(activityModeProvider.notifier).updateHeartRate(heartRate);
  }
}
```

#### Cleanup:
```dart
@override
void dispose() {
  // Stops detection when leaving screen
  ref.read(activityModeProvider.notifier).stopDetection();
}
```

### 3. Live UI Badge

#### Always Visible Badge:
The badge is **always displayed** above the metrics panel, showing:

**Loading State** (first 10 seconds):
- Purple gradient badge
- Spinning progress indicator
- "Analyzing..." text

**Detected State** (after first detection):
- Color-coded badge (green/red/orange)
- Mode name (CALM/STRESS/CARDIO)
- Confidence percentage
- Appropriate icon

#### Visual Design:

**CALM Mode** 🍃
- Color: Green gradient
- Icon: Leaf
- Meaning: Low intensity, can push harder

**STRESS Mode** ⚠️
- Color: Red gradient
- Icon: Danger/Warning
- Meaning: High intensity, consider slowing down

**CARDIO Mode** ❤️
- Color: Orange gradient
- Icon: Heart pulse
- Meaning: Optimal cardio zone

## TensorFlow Lite Model Integration

### Model Specifications:
- **Path**: `assets/model/activity_tracker.tflite`
- **Input Shape**: `[1, 320, 4]`
  - 1 = batch size
  - 320 = time window (samples)
  - 4 = features [accX, accY, accZ, bpm]
- **Output Shape**: `[1, 3]`
  - 3 classes: [Stress, Cardio, Calm/Strength]

### Inference Process:
```dart
// 1. Collect sensor buffer
List<List<double>> buffer = [
  [accX1, accY1, accZ1, bpm1],
  [accX2, accY2, accZ2, bpm2],
  ...
  [accX320, accY320, accZ320, bpm320]
];

// 2. Run TFLite inference
final probabilities = await _classifier.predict(buffer);
// Returns: [0.15, 0.25, 0.60] for example

// 3. Find highest probability
final maxIndex = probabilities.indexOf(max);
// maxIndex = 2 → CALM mode

// 4. Update UI
state = ActivityModeState(
  currentMode: ActivityMode.calm,
  confidence: 0.60,
  probabilities: [0.15, 0.25, 0.60]
);
```

## User Experience Flow

### During Running Workout:

1. **Start Running** → User begins workout
2. **2 seconds delay** → System initializes
3. **"Analyzing..." badge appears** → Purple, with spinner
4. **10 seconds** → Collecting sensor data
5. **First detection** → Badge updates with mode (e.g., "CARDIO 85%")
6. **Every 15 seconds** → Badge updates with new detection
7. **Continuous updates** → Mode changes as intensity changes
8. **End workout** → Detection stops automatically

### Real-time Feedback:
- User can see their current activity intensity at a glance
- Badge color provides instant visual feedback
- Confidence percentage shows detection reliability
- Updates every 15 seconds for fresh data

## Technical Architecture

### Sensor Data Collection:
```
Phone Accelerometer (sensors_plus)
    ↓
AccelerometerEvent stream
    ↓
_addSensorData() → Rolling buffer [320 samples]
    ↓
Combined with Heart Rate from session
    ↓
Ready for inference
```

### Detection Cycle:
```
Timer (15 seconds)
    ↓
Check buffer size (≥ 320 samples)
    ↓
Run TFLite inference
    ↓
Update UI state
    ↓
Schedule next detection
    ↓
Repeat
```

### State Management:
```
ActivityModeProvider (Riverpod)
    ↓
ActivityModeNotifier (StateNotifier)
    ↓
ActivityModeState
    ├── currentMode: ActivityMode?
    ├── confidence: double?
    ├── probabilities: List<double>?
    └── isDetecting: bool
```

## Performance Considerations

### Efficiency:
- **Rolling Buffer**: Only keeps last 320 samples (memory efficient)
- **15-second Intervals**: Balances accuracy with battery life
- **Automatic Cleanup**: Stops when screen is disposed
- **Lazy Loading**: Model loads only when needed

### Battery Impact:
- Accelerometer: Low power consumption
- TFLite Inference: Runs on-device (no network)
- 15-second intervals: Minimal CPU usage
- Stops automatically: No background drain

## Error Handling

### Insufficient Data:
```dart
if (_sensorBuffer.length < 320) {
  // Retry in 5 seconds
  _scheduleNextDetection(5);
}
```

### Inference Failure:
```dart
catch (e) {
  state = ActivityModeState(error: 'Detection failed: $e');
  // Retry in 10 seconds
  if (_isContinuousMode) {
    _scheduleNextDetection(10);
  }
}
```

### Model Loading:
```dart
if (!_classifier.isLoaded) {
  await _classifier.loadModel();
}
```

## Benefits

✅ **No User Action Required**: Fully automatic
✅ **Real-time Feedback**: Updates every 15 seconds
✅ **Always Visible**: Badge always shows current state
✅ **Accurate Detection**: Uses ML model with sensor fusion
✅ **Battery Efficient**: Optimized intervals and cleanup
✅ **Visual Clarity**: Color-coded for instant understanding
✅ **Confidence Display**: Shows detection reliability

## Future Enhancements

- [ ] Historical mode tracking (graph over time)
- [ ] Adjustable detection intervals (user preference)
- [ ] Mode-based coaching tips
- [ ] Integration with post-workout analysis
- [ ] Vibration alerts on mode changes
- [ ] Export mode data with workout summary
