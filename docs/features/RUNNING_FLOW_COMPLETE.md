# Running Flow - Complete Integration

## Summary
Fixed the complete running workout flow from mood selection to active running session with Strava-style UI.

## Complete Flow

### 1. Start Workout (Track Tab)
- User taps "START WORKOUT" button
- Mood check bottom sheet appears with Solar icon options

### 2. Mood Selection
- User selects mood (Very Bad, Bad, Neutral, Good, Energized)
- Icons: Solar icons with color coding
- Auto-dismisses and navigates to workout type selection

### 3. Workout Type Selection
- User selects "Running"
- Navigates to running setup screen

### 4. Running Setup Screen (NEW)
**Features:**
- Choose goal type: Distance or Duration
- Adjust target with slider:
  - Distance: 1-20 km
  - Duration: 5-120 minutes
- Clean UI with Solar icons
- "Start Running" button

**What Happens:**
- Gets pre-workout mood from workout flow provider
- Calls `runningSessionProvider.notifier.startSession()`
- Starts GPS tracking, timer, and heart rate monitoring
- Navigates to active running screen

### 5. Active Running Screen (Strava-style)
**Full-Screen Map Display:**
- Map covers entire screen as background
- Gradient overlay for readability
- Real-time route polyline drawing
- Current location marker with shadow

**Floating Header:**
- Back button
- Status badge (RUNNING/PAUSED)
- Menu button

**Bottom Metrics Panel:**
- **Large Metrics:**
  - Distance (km)
  - Duration (time)
  - Pace (min/km)
  
- **Small Metrics:**
  - Heart Rate (bpm)
  - Calories (cal)
  - Steps (ready for integration)

**Controls:**
- Large Pause/Resume button
- Stop button (shows confirmation dialog)

### 6. Session Management
**Active Session:**
- GPS tracking updates route in real-time
- Timer counts duration
- Heart rate monitoring (if available)
- Pace calculation
- Calorie calculation
- All metrics update live

**Pause/Resume:**
- Pause stops GPS, timer, and HR monitoring
- Resume restarts all services
- Status badge updates

**End Workout:**
- Confirmation dialog
- Stops all services
- Saves session to database
- Navigates to summary screen

## Technical Implementation

### Running Setup Screen
```dart
// Starts session with proper configuration
await ref.read(runningSessionProvider.notifier).startSession(
  goalType: _goalType,
  targetDistance: _goalType == GoalType.distance ? _targetDistance : null,
  targetDuration: _goalType == GoalType.duration ? _targetDuration : null,
  preMood: preMood,
);
```

### Session Provider
- Manages GPS tracking service
- Manages timer service
- Manages heart rate service
- Calculates pace and calories
- Updates state in real-time
- Saves to database

### Active Running Screen
- Watches `runningSessionProvider` for state changes
- Full-screen map with route overlay
- Real-time metric updates
- Pause/resume functionality
- End workout with confirmation

## User Experience

1. **Seamless Flow:** Mood → Type → Setup → Active → Summary
2. **Real-time Feedback:** All metrics update live during workout
3. **Professional UI:** Strava-like full-screen map experience
4. **Easy Controls:** Large, accessible pause/resume and stop buttons
5. **Visual Feedback:** Status badges, color-coded metrics, icons

## Next Steps

### Immediate:
- Test the complete flow end-to-end
- Verify GPS tracking works on device
- Test pause/resume functionality

### Future Enhancements:
1. **Step Counter Integration:**
   - Connect to Android step detection API
   - Display real-time step count

2. **Audio Cues:**
   - Distance milestone announcements
   - Pace alerts
   - Heart rate zone notifications

3. **Enhanced Map:**
   - Elevation profile
   - Split times on route
   - Waypoint markers

4. **Post-Workout:**
   - Mood check after workout
   - Summary screen with stats
   - Share functionality
