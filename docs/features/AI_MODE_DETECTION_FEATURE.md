# AI Activity Mode Detection Feature

## Overview
Added AI-powered activity mode detection to the running workout screen using TensorFlow Lite model. The feature detects whether the user is in **Calm**, **Stress**, or **Cardio** mode based on accelerometer data and heart rate.

## What Was Added

### 1. Activity Mode Provider (`lib/providers/activity_mode_provider.dart`)
- **ActivityMode enum**: Defines three modes (stress, cardio, calm)
- **ActivityModeState**: Holds detection state, confidence, and probabilities
- **ActivityModeNotifier**: Manages the detection process
  - Collects 10 seconds of accelerometer data (320 samples)
  - Combines accelerometer (X, Y, Z) with heart rate data
  - Runs TensorFlow Lite inference using the existing model
  - Returns detected mode with confidence percentage

### 2. Updated Active Running Screen
- Added "Detect Activity Mode (AI)" button in the bottom metrics panel
- Shows loading state while collecting sensor data (10 seconds)
- Displays detected mode badge with:
  - Mode name (CALM/STRESS/CARDIO)
  - Confidence percentage
  - Color-coded visual (green/red/orange)
  - Appropriate icon for each mode

## How It Works

1. **User clicks "Detect Activity Mode (AI)" button**
2. **System collects data for 10 seconds**:
   - Accelerometer readings (X, Y, Z axes)
   - Current heart rate from session
3. **TensorFlow Lite model processes the data**:
   - Input: 320 samples × 4 features [accX, accY, accZ, bpm]
   - Output: 3 probabilities [stress%, cardio%, calm%]
4. **Result displayed as badge**:
   - Shows the mode with highest probability
   - Displays confidence percentage
   - Badge appears above the metrics panel

## Visual Design

### Mode Colors & Icons
- **CALM** 🍃: Green badge with leaf icon
- **STRESS** ⚠️: Red badge with danger icon  
- **CARDIO** ❤️: Orange badge with heart pulse icon

### Button States
- **Idle**: Purple outlined button with CPU icon
- **Detecting**: Shows loading spinner with "Detecting Mode..." text
- **Completed**: Badge appears above metrics panel

## Technical Details

### Model Integration
- Uses existing `TFLiteActivityClassifier` from `lib/features/activity_classifier/`
- Model path: `assets/model/activity_tracker.tflite`
- Input shape: [1, 320, 4]
- Output shape: [1, 3]

### Sensor Data Collection
- Uses `sensors_plus` package (already in dependencies)
- Collects accelerometer events at device sampling rate
- Maintains rolling buffer of last 320 samples
- Combines with current heart rate from running session

### State Management
- Uses Riverpod for state management
- Provider: `activityModeProvider`
- Integrates with existing `runningSessionProvider` for heart rate

## Usage Flow

1. Start a running workout
2. Run for a few minutes to get stable metrics
3. Click "Detect Activity Mode (AI)" button
4. Wait 10 seconds while system collects sensor data
5. View detected mode badge showing your current activity intensity

## Benefits

- **Real-time feedback**: Know if you're pushing too hard (stress) or can increase intensity (calm)
- **AI-powered**: Uses machine learning for accurate detection
- **Non-intrusive**: Optional feature, doesn't affect normal workout flow
- **Visual clarity**: Color-coded badges make it easy to understand at a glance

## Future Enhancements

- Continuous monitoring mode (auto-detect every 30 seconds)
- Historical mode tracking throughout workout
- Personalized recommendations based on detected mode
- Integration with post-workout mood analysis
