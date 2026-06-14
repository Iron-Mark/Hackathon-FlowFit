# Wellness Map - GPS Tracking & Path Visualization

## Overview
Enhanced the wellness map widget to include real-time GPS tracking with path visualization, similar to the running/walking workout screens.

## Features Implemented

### 1. Real-Time GPS Tracking ✅
- **Continuous Location Updates**: Uses `GPSTrackingService` to stream location updates
- **Auto-Follow**: Map automatically centers on user's current position as they move
- **10-Meter Distance Filter**: Updates only when user moves 10+ meters (battery efficient)
- **Permission Handling**: Automatically requests and checks location permissions

### 2. Path Visualization ✅
- **Green Polyline**: User's walking path is drawn in green (#10B981) with white border
- **Real-Time Updates**: Path extends automatically as user walks
- **Path Statistics**: Shows number of GPS points and total distance traveled
- **Clear Path Button**: Red button in top-left to reset the tracked path

### 3. Multi-Layer Map Display ✅
The map now has proper layering:
1. **Base Layer**: OpenStreetMap tiles
2. **User Path**: Green polyline showing where you've walked (bottom layer)
3. **Calming Routes**: Blue polylines for stress-relief routes (middle layer)
4. **User Marker**: Blue pulsing circle showing current location (top layer)

### 4. Map Controls ✅
- **Path Info Card** (top-right):
  - Number of GPS points tracked
  - Total distance in kilometers
  - Only visible when path has 2+ points
  
- **Clear Path Button** (top-left):
  - Small red floating action button
  - Clears the tracked path
  - Resets to current location

## Technical Implementation

### GPS Tracking Service Integration
```dart
// Start continuous GPS tracking
await _gpsService.startTracking();

// Listen to location updates
_locationSubscription = _gpsService.locationStream.listen((location) {
  setState(() {
    _userLocation = location;
    if (_isTrackingPath) {
      _userPath.add(location);
    }
  });
  _mapController.move(location, _mapController.camera.zoom);
});
```

### Path Polyline Rendering
```dart
// User's walking path
if (_userPath.length > 1)
  PolylineLayer(
    polylines: [
      Polyline(
        points: _userPath,
        strokeWidth: 4,
        color: const Color(0xFF10B981), // Green
        borderStrokeWidth: 2,
        borderColor: Colors.white,
      ),
    ],
  ),
```

### Distance Calculation
```dart
// Calculate total distance of tracked path
double distance = _gpsService.calculateRouteDistance(_userPath);
```

## User Experience

### When You Open Wellness Tracker:
1. Map loads with your current location
2. GPS tracking starts automatically
3. A green path begins forming as you walk
4. Your location marker (blue circle) updates in real-time
5. Map follows you smoothly as you move

### Path Tracking:
- **Automatic**: Starts tracking immediately when map loads
- **Persistent**: Path remains visible throughout your wellness session
- **Clearable**: Tap the red button to start fresh

### In STRESS State:
- Your green path remains visible
- Blue calming routes appear as suggestions
- You can see both your actual path and suggested routes simultaneously

## Battery Optimization

The implementation includes several battery-saving features:
- **Distance Filter**: Only updates when you move 10+ meters
- **High Accuracy Mode**: Uses GPS only when needed
- **Proper Cleanup**: Stops tracking when widget is disposed
- **Stream Cancellation**: Properly cancels subscriptions to prevent leaks

## Comparison with Running/Walking Screens

| Feature | Running Screen | Wellness Map |
|---------|---------------|--------------|
| GPS Tracking | ✅ | ✅ |
| Path Polyline | ✅ Blue | ✅ Green |
| Real-time Updates | ✅ | ✅ |
| Distance Calculation | ✅ | ✅ |
| Auto-follow | ✅ | ✅ |
| Clear Path | ❌ | ✅ |
| Path Statistics | ❌ | ✅ |

## Code Changes

### Files Modified:
- `lib/widgets/wellness/wellness_map_widget.dart`

### Key Additions:
1. `List<LatLng> _userPath` - Stores GPS coordinates
2. `StreamSubscription<LatLng>? _locationSubscription` - Listens to GPS updates
3. `_startGPSTracking()` - Initializes continuous tracking
4. `_clearPath()` - Resets the tracked path
5. Path polyline layer in map
6. Path statistics card
7. Clear path button

## Testing

### Test Scenarios:
1. **Indoor Testing**: Map should load with last known location
2. **Outdoor Walking**: Path should draw as you walk
3. **Clear Path**: Button should reset path to current location only
4. **State Changes**: Path should persist when wellness state changes
5. **App Backgrounding**: GPS should continue tracking (if permissions allow)

### Expected Behavior:
- Path appears as green line with white border
- Distance updates in real-time
- Map smoothly follows your movement
- No lag or stuttering during updates

## Future Enhancements

Potential improvements:
1. **Path Colors by State**: Different colors for CALM/STRESS/CARDIO segments
2. **Path Replay**: Ability to replay your walking session
3. **Export Path**: Save path as GPX file
4. **Heatmap**: Show areas where you spend most time
5. **Speed Indicators**: Color-code path by walking speed
6. **Elevation Profile**: Show elevation changes along path
7. **Path Smoothing**: Apply Kalman filter to reduce GPS jitter

## Performance Notes

- **Memory Usage**: Each GPS point is ~16 bytes (2 doubles)
- **Typical Session**: 1-hour walk = ~360 points = ~6KB
- **Rendering**: flutter_map efficiently handles 1000+ points
- **Battery Impact**: ~2-5% per hour (similar to running apps)

## Troubleshooting

### Path Not Appearing:
- Check location permissions
- Ensure GPS is enabled
- Walk at least 10 meters to trigger first update
- Check for "Waiting for GPS signal..." message

### Map Not Following:
- Verify `_mapController.move()` is being called
- Check if location stream is active
- Look for GPS tracking logs in console

### Distance Incorrect:
- GPS accuracy varies (typically ±5-10 meters)
- Indoor GPS is less accurate
- Path may show slight zigzag due to GPS drift
