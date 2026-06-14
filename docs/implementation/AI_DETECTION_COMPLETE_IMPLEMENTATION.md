# AI Activity Detection - Complete Implementation Guide

## 📋 Overview

This document provides a comprehensive guide to the AI-powered activity detection system integrated into the running workout feature. The system uses TensorFlow Lite to classify user activity in real-time as **Stress**, **Cardio**, or **Strength** (Calm) based on sensor data from a Galaxy Watch.

---

## 🎯 Features Implemented

### 1. **Real-Time AI Classification**
- Automatic detection every 15 seconds during running workouts
- Uses TensorFlow Lite model (`activity_tracker.tflite`)
- Combines accelerometer data + heart rate from Galaxy Watch
- Displays live results with confidence percentages

### 2. **Live Watch Data Integration**
- Receives sensor batches from Galaxy Watch via `PhoneDataListener`
- Each batch contains: `[accX, accY, accZ, heartRate]`
- Maintains rolling buffer of 320 samples for inference
- Real-time heart rate display with live indicator

### 3. **Visual Feedback**
- Always-visible activity mode badge
- Color-coded by mode (Red/Orange/Green)
- Confidence percentage display
- Detailed probability breakdown for all three modes

### 4. **Data Persistence** (Ready for Implementation)
- Model structure prepared for saving AI detection history
- Fields added to `RunningSession` model:
  - `activityModeHistory` - List of detections throughout workout
  - `avgActivityProbabilities` - Average probabilities [stress, cardio, strength]
  - `dominantActivityMode` - Most common mode during workout

---

## 🏗️ Architecture

### Data Flow

```
Galaxy Watch
    ↓ Sends sensor batches via Wearable Data Layer
PhoneDataListener
    ↓ Receives JSON: {"samples": [[accX, accY, accZ, bpm], ...]}
Active Running Screen
    ↓ Maintains rolling buffer (320 samples)
TensorFlow Lite Model
    ↓ Input: [1, 320, 4] → Output: [1, 3]
ActivityClassifierViewModel
    ↓ Processes probabilities [stress%, cardio%, strength%]
UI Display
    ↓ Shows badge + breakdown
```

### Component Diagram

```
┌─────────────────────────────────────────────────────────┐
│           Active Running Screen                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Sensor Buffer (320 samples)                      │  │
│  │  [accX, accY, accZ, bpm] × 320                    │  │
│  └───────────────────────────────────────────────────┘  │
│                        ↓                                 │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Detection Timer (every 15 seconds)               │  │
│  └───────────────────────────────────────────────────┘  │
│                        ↓                                 │
│  ┌───────────────────────────────────────────────────┐  │
│  │  ActivityClassifierViewModel.classify()           │  │
│  │  - Runs TFLite inference                          │  │
│  │  - Returns [stress%, cardio%, strength%]          │  │
│  └───────────────────────────────────────────────────┘  │
│                        ↓                                 │
│  ┌───────────────────────────────────────────────────┐  │
│  │  UI Update                                        │  │
│  │  - Activity mode badge                            │  │
│  │  - Probability breakdown                          │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 Files Modified

### 1. **lib/screens/workout/running/active_running_screen.dart**

#### Key Changes:
- Added sensor data collection from watch
- Implemented continuous AI detection loop
- Added live heart rate display from watch
- Created activity mode badge UI
- Added probability breakdown UI

#### Code Highlights:

**Sensor Data Collection:**
```dart
// Subscribe to sensor batches from watch
_sensorSubscription = phoneDataListener.sensorBatchStream.listen((sensorBatch) {
  for (final sample in sensorBatch.samples) {
    if (sample.length == 4) {
      _sensorBuffer.add(sample);

      // Keep only last 320 samples
      if (_sensorBuffer.length > _windowSize) {
        _sensorBuffer.removeAt(0);
      }
    }
  }

  // Run inference when we have enough data
  if (_sensorBuffer.length >= _windowSize) {
    _runDetection();
  }
});
```

**AI Detection:**
```dart
Future<void> _runDetection() async {
  if (_sensorBuffer.length < _windowSize) {
    _scheduleNextDetection(5);
    return;
  }

  try {
    final viewModel = provider.Provider.of<ActivityClassifierViewModel>(context, listen: false);
    final bufferCopy = List<List<double>>.from(_sensorBuffer.take(_windowSize));
    await viewModel.classify(bufferCopy);

    // Schedule next detection in 15 seconds
    _scheduleNextDetection(15);
  } catch (e) {
    print('❌ Detection failed: $e');
    _scheduleNextDetection(10);
  }
}
```

**Activity Mode Badge:**
```dart
Widget _buildActivityModeBadge(ActivityClassifierViewModel viewModel) {
  // Show loading state while detecting
  if (viewModel.currentActivity == null) {
    return Container(
      // Purple gradient badge with spinner
      child: Row(
        children: [
          CircularProgressIndicator(),
          Text('Analyzing...'),
        ],
      ),
    );
  }

  final activity = viewModel.currentActivity!;
  final modeLabel = activity.label.toUpperCase();
  final confidence = activity.confidence;

  // Color-coded badge based on mode
  Color modeColor = activity.label == 'Stress' ? Colors.red
                  : activity.label == 'Cardio' ? Colors.orange
                  : Colors.green;

  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [modeColor, modeColor.withOpacity(0.7)]),
    ),
    child: Row(
      children: [
        Icon(modeIcon),
        Text('$modeLabel ${(confidence * 100).toStringAsFixed(0)}%'),
      ],
    ),
  );
}
```

**Probability Breakdown:**
```dart
Widget _buildAIMetricsBreakdown(ActivityClassifierViewModel viewModel) {
  final probabilities = viewModel.currentActivity!.probabilities;
  final stressProb = probabilities[0];
  final cardioProb = probabilities[1];
  final strengthProb = probabilities[2];

  return Container(
    child: Column(
      children: [
        _buildProbabilityBar('Stress', stressProb, Colors.red),
        _buildProbabilityBar('Cardio', cardioProb, Colors.orange),
        _buildProbabilityBar('Strength', strengthProb, Colors.green),
      ],
    ),
  );
}
```

### 2. **lib/models/running_session.dart**

#### Key Changes:
- Added AI detection data fields
- Prepared for data persistence

#### Code Highlights:

```dart
class RunningSession extends WorkoutSession {
  // ... existing fields ...

  /// AI Activity mode detections throughout workout
  final List<ActivityModeDetection>? activityModeHistory;

  /// Average activity mode probabilities [stress, cardio, strength]
  final List<double>? avgActivityProbabilities;

  /// Dominant activity mode during workout
  final String? dominantActivityMode;

  RunningSession({
    // ... existing parameters ...
    this.activityModeHistory,
    this.avgActivityProbabilities,
    this.dominantActivityMode,
  }) : super(type: WorkoutType.running);
}
```

**Note:** The `ActivityModeDetection` class needs to be created to store individual detection records:

```dart
class ActivityModeDetection {
  final DateTime timestamp;
  final String mode; // 'Stress', 'Cardio', or 'Strength'
  final double confidence;
  final List<double> probabilities; // [stress, cardio, strength]

  ActivityModeDetection({
    required this.timestamp,
    required this.mode,
    required this.confidence,
    required this.probabilities,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'mode': mode,
    'confidence': confidence,
    'probabilities': probabilities,
  };

  factory ActivityModeDetection.fromJson(Map<String, dynamic> json) {
    return ActivityModeDetection(
      timestamp: DateTime.parse(json['timestamp']),
      mode: json['mode'],
      confidence: json['confidence'],
      probabilities: List<double>.from(json['probabilities']),
    );
  }
}
```

### 3. **lib/providers/running_session_provider.dart**

#### Current State:
- Already receives heart rate from watch via `PhoneDataListener`
- Updates session state with real-time metrics

#### Ready for Enhancement:
- Can be extended to save AI detection history
- Can calculate average probabilities and dominant mode

---

## 🎨 UI Components

### 1. Activity Mode Badge

**States:**

**Loading (First 10 seconds):**
```
┌─────────────────────────────────────┐
│  🔄  AI Activity Detection          │
│      Analyzing...                   │
└─────────────────────────────────────┘
```

**Stress Mode:**
```
┌─────────────────────────────────────┐
│  ⚠️  AI Activity Mode               │
│      STRESS  85%                    │
└─────────────────────────────────────┘
```

**Cardio Mode:**
```
┌─────────────────────────────────────┐
│  ❤️  AI Activity Mode               │
│      CARDIO  72%                    │
└─────────────────────────────────────┘
```

**Strength/Calm Mode:**
```
┌─────────────────────────────────────┐
│  🍃  AI Activity Mode               │
│      STRENGTH  68%                  │
└─────────────────────────────────────┘
```

### 2. Probability Breakdown

```
┌─────────────────────────────────────┐
│  🖥️ AI Detection Breakdown          │
│                                     │
│  ⚠️ Stress      ████░░░░░░  15.2%  │
│  ❤️ Cardio      ████████░░  72.3%  │
│  🍃 Strength    ███░░░░░░░  12.5%  │
└─────────────────────────────────────┘
```

### 3. Live Heart Rate Indicator

```
┌─────────────────────────────────────┐
│  ❤️  78  bpm                        │
│  Heart Rate (Live) 🟢              │
└─────────────────────────────────────┘
```

---

## 🔧 TensorFlow Lite Model

### Model Specifications

- **File:** `assets/model/activity_tracker.tflite`
- **Input Shape:** `[1, 320, 4]`
  - Batch size: 1
  - Time window: 320 samples (~10 seconds at 32 Hz)
  - Features: 4 [accX, accY, accZ, heartRate]
- **Output Shape:** `[1, 3]`
  - 3 classes: [Stress, Cardio, Strength/Calm]
- **Output Format:** Probabilities (sum to 1.0)

### Inference Process

```dart
// 1. Prepare input buffer (320 samples × 4 features)
List<List<double>> buffer = [
  [accX1, accY1, accZ1, bpm1],
  [accX2, accY2, accZ2, bpm2],
  // ... 320 samples total
];

// 2. Run inference
final probabilities = await classifier.predict(buffer);
// Returns: [0.15, 0.72, 0.13] for example

// 3. Find dominant mode
final maxIndex = probabilities.indexOf(probabilities.reduce(max));
final modes = ['Stress', 'Cardio', 'Strength'];
final detectedMode = modes[maxIndex];
final confidence = probabilities[maxIndex];
```

---

## 📊 Data Persistence Strategy

### Saving AI Detection Data

**During Workout:**
1. Every 15 seconds, after AI detection:
   ```dart
   final detection = ActivityModeDetection(
     timestamp: DateTime.now(),
     mode: viewModel.currentActivity!.label,
     confidence: viewModel.currentActivity!.confidence,
     probabilities: viewModel.currentActivity!.probabilities,
   );

   // Add to session history
   ref.read(runningSessionProvider.notifier).addActivityDetection(detection);
   ```

2. Update running session provider:
   ```dart
   void addActivityDetection(ActivityModeDetection detection) {
     if (state == null) return;

     final updatedHistory = [...?state!.activityModeHistory, detection];

     state = state!.copyWith(
       activityModeHistory: updatedHistory,
     );
   }
   ```

**At Workout End:**
1. Calculate average probabilities:
   ```dart
   List<double> calculateAvgProbabilities(List<ActivityModeDetection> history) {
     if (history.isEmpty) return [0, 0, 0];

     double sumStress = 0, sumCardio = 0, sumStrength = 0;
     for (final detection in history) {
       sumStress += detection.probabilities[0];
       sumCardio += detection.probabilities[1];
       sumStrength += detection.probabilities[2];
     }

     final count = history.length;
     return [
       sumStress / count,
       sumCardio / count,
       sumStrength / count,
     ];
   }
   ```

2. Determine dominant mode:
   ```dart
   String calculateDominantMode(List<ActivityModeDetection> history) {
     if (history.isEmpty) return 'Unknown';

     final modeCounts = <String, int>{};
     for (final detection in history) {
       modeCounts[detection.mode] = (modeCounts[detection.mode] ?? 0) + 1;
     }

     return modeCounts.entries
         .reduce((a, b) => a.value > b.value ? a : b)
         .key;
   }
   ```

3. Save to database:
   ```dart
   await _sessionService.saveSession(state!.copyWith(
     avgActivityProbabilities: calculateAvgProbabilities(state!.activityModeHistory!),
     dominantActivityMode: calculateDominantMode(state!.activityModeHistory!),
   ));
   ```

---

## 📈 Summary Screen Integration

### Display AI Analysis

**Add to `running_summary_screen.dart`:**

```dart
Widget _buildAIActivityAnalysis(ThemeData theme, dynamic session) {
  if (session.activityModeHistory == null || session.activityModeHistory!.isEmpty) {
    return const SizedBox.shrink();
  }

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Activity Analysis',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Dominant mode
        Row(
          children: [
            Icon(_getModeIcon(session.dominantActivityMode)),
            const SizedBox(width: 8),
            Text('Dominant Mode: ${session.dominantActivityMode}'),
          ],
        ),

        const SizedBox(height: 16),

        // Average probabilities
        _buildProbabilityBar('Stress', session.avgActivityProbabilities[0], Colors.red),
        const SizedBox(height: 8),
        _buildProbabilityBar('Cardio', session.avgActivityProbabilities[1], Colors.orange),
        const SizedBox(height: 8),
        _buildProbabilityBar('Strength', session.avgActivityProbabilities[2], Colors.green),

        const SizedBox(height: 16),

        // Detection count
        Text(
          '${session.activityModeHistory!.length} detections during workout',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}
```

---

## 🧪 Testing Guide

### Manual Testing Steps

1. **Start Running Workout:**
   ```
   Dashboard → Track Tab → Running → Select Goal → Start Workout
   ```

2. **Verify Watch Connection:**
   - Check that Galaxy Watch is connected
   - Ensure watch app is running
   - Verify heart rate is being sent

3. **Observe AI Detection:**
   - Wait 2 seconds for initialization
   - See "Analyzing..." badge appear
   - After 10 seconds, see first detection result
   - Badge updates every 15 seconds

4. **Check Live Heart Rate:**
   - Look for live indicator (🟢) on heart rate metric
   - Verify BPM matches watch display

5. **Test Different Intensities:**
   - Walk slowly → Should detect "Strength/Calm"
   - Jog moderately → Should detect "Cardio"
   - Sprint → Should detect "Stress"

6. **End Workout:**
   - Tap "End Workout" button
   - Navigate to summary screen
   - Verify all metrics are displayed

### Debug Logging

The implementation includes extensive debug logging:

```dart
print('💓 Live HR from watch: ${heartRateData.bpm} bpm');
print('🟢 Running AI detection with ${_sensorBuffer.length} samples');
print('✅ AI detection completed');
print('❌ Detection failed: $e');
print('🔴 Buffer not ready: ${_sensorBuffer.length}/$_windowSize samples');
```

---

## 🚀 Future Enhancements

### Phase 1: Data Persistence (Next Step)
- [ ] Create `ActivityModeDetection` model class
- [ ] Implement `addActivityDetection()` in provider
- [ ] Calculate average probabilities at workout end
- [ ] Determine dominant mode
- [ ] Save to database

### Phase 2: Summary Screen
- [ ] Display AI activity analysis card
- [ ] Show dominant mode with icon
- [ ] Display average probability breakdown
- [ ] Show detection count

### Phase 3: Advanced Features
- [ ] Activity mode timeline graph
- [ ] Mode-based coaching tips
- [ ] Vibration alerts on mode changes
- [ ] Adjustable detection intervals
- [ ] Export AI data with workout

### Phase 4: Sharing
- [ ] Include AI analysis in shared achievements
- [ ] Generate visual charts for social media
- [ ] Add mode badges to shared images

---

## 📚 Related Documentation

- `AI_MODE_DETECTION_FEATURE.md` - Initial feature overview
- `AI_MODE_LIVE_DETECTION.md` - Live detection implementation
- `ACTIVITY_AI_WATCH_INTEGRATION.md` - Watch data integration
- `RUNNING_FLOW_COMPLETE.md` - Complete running flow

---

## 🎓 Key Learnings

### What Works Well:
✅ Real-time sensor data from Galaxy Watch
✅ TensorFlow Lite inference on-device
✅ Rolling buffer for continuous detection
✅ Visual feedback with color-coded badges
✅ Live heart rate integration

### Challenges Solved:
✅ Maintaining 320-sample buffer efficiently
✅ Scheduling detections every 15 seconds
✅ Handling missing or invalid sensor data
✅ UI updates with Consumer/Provider pattern
✅ Cleanup on screen disposal

### Best Practices:
✅ Use rolling buffer to limit memory usage
✅ Filter invalid sensor data (null, 0 values)
✅ Schedule next detection after current completes
✅ Cancel subscriptions in dispose()
✅ Provide visual feedback during loading

---

## 📞 Support

For questions or issues:
1. Check debug logs in console
2. Verify watch connection in Galaxy Wearable app
3. Ensure TFLite model is in `assets/model/`
4. Review sensor data format from watch

---

**Last Updated:** November 29, 2025
**Status:** ✅ Core Implementation Complete | 🚧 Data Persistence Ready for Implementation
