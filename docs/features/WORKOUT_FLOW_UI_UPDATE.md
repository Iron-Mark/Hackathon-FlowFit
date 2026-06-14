# Workout Flow UI Update

## Summary
Updated the Track tab workout flow with improved UI design:
1. Replaced emoji mood indicators with Solar icons
2. Redesigned active running screen with Strava-like full-screen map UI
3. Added comprehensive metrics display including pace, duration, BPM, steps, and calories

## Changes Made

### 1. Mood Check Bottom Sheet (`lib/widgets/quick_mood_check_bottom_sheet.dart`)

**Before:**
- Used emoji characters (😢, 😕, 😐, 🙂, 💪) for mood selection
- Simple circular backgrounds

**After:**
- Replaced with Solar icons:
  - Very Bad: `SolarIconsBold.sadCircle` (Red)
  - Bad: `SolarIconsBold.confoundedCircle` (Orange)
  - Neutral: `SolarIconsBold.expressionlessCircle` (Grey)
  - Good: `SolarIconsBold.smileCircle` (Green)
  - Energized: `SolarIconsBold.fire` (Blue)
- Color-coded circular backgrounds matching mood sentiment
- Improved visual consistency with app design system

### 2. Active Running Screen (`lib/screens/workout/running/active_running_screen.dart`)

**Complete UI Redesign - Strava-like Experience:**

#### Layout Changes:
- **Full-screen map background** instead of small map widget
- **Gradient overlay** for better text readability
- **Floating header** with transparent background
- **Bottom metrics panel** with comprehensive workout data

#### Header Features:
- Back button (left)
- Status badge showing "RUNNING" or "PAUSED" with icon (center)
- Menu button (right)
- All controls have semi-transparent white backgrounds

#### Bottom Metrics Panel:
**Primary Metrics (Large Display):**
- Distance (km) with map icon
- Duration (time) with clock icon
- Pace (min/km) with speedometer icon

**Secondary Metrics (Compact Display):**
- Heart Rate (bpm) with heart pulse icon
- Calories (cal) with fire icon
- Steps (steps) with walking icon - *Ready for Android integration*

**Control Buttons:**
- Large Pause/Resume button (blue)
- Stop button (red) with icon

#### Visual Improvements:
- Solar icons throughout for consistency
- Color-coded metrics (blue, orange, green, red)
- Enhanced map polyline with white border
- Larger location marker with shadow
- Professional gradient overlays
- Rounded corners and modern spacing

### 3. Map Enhancements

**Full-Screen Map:**
- Covers entire screen as background
- Zoom level increased to 16 for better detail
- Thicker route polyline (5px) with white border
- Larger current location marker (24px) with enhanced shadow
- Better GPS waiting state with icon and message

## Features Ready for Integration

### Step Counter
The UI includes a steps metric display that's ready to receive data from the Android step counter layer. The placeholder shows `--` until integrated.

**Integration Point:**
```dart
_buildSmallMetric(
  'Steps',
  '--', // TODO: Integrate step counter from Android
  'steps',
  SolarIconsBold.walking,
  const Color(0xFF3B82F6),
),
```

### Heart Rate Monitor
Already integrated with the session provider, displays real-time BPM when available.

### GPS Tracking
Fully functional with:
- Real-time route polyline drawing
- Current location marker
- Distance calculation
- Pace calculation

## User Experience Flow

1. **Start Workout** → User taps "START WORKOUT" in Track tab
2. **Mood Check** → Bottom sheet appears with Solar icon mood options
3. **Workout Type** → User selects Running
4. **Running Setup** → User configures distance/time goal
5. **Active Running** → Full-screen map with live metrics:
   - See route on map in real-time
   - Monitor distance, pace, duration at a glance
   - Check heart rate, calories, steps
   - Pause/resume or stop workout
6. **Post-Workout** → Mood check and summary

## Design Consistency

All UI elements now use:
- Solar icons for visual consistency
- App theme colors (primary blue, orange, green, red)
- Consistent border radius (12-24px)
- Proper spacing and padding
- Material Design 3 principles

## Testing Recommendations

1. Test mood selection with all 5 options
2. Verify running screen displays correctly on different screen sizes
3. Test pause/resume functionality
4. Verify map rendering and route tracking
5. Check metric updates in real-time
6. Test stop workout dialog and navigation

## Next Steps

1. **Integrate Android Step Counter:**
   - Connect to Android's step detection API
   - Update the steps metric in real-time
   - Store step data in workout session

2. **Add Haptic Feedback:**
   - Vibrate on mood selection
   - Vibrate on pause/resume
   - Vibrate on workout milestones

3. **Add Audio Cues:**
   - Voice feedback for distance milestones
   - Pace alerts
   - Heart rate zone notifications

4. **Enhance Map Features:**
   - Add route elevation profile
   - Show split times on map
   - Add waypoint markers
