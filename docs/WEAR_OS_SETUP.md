# FlowFit Wear OS Setup

This document outlines the Wear OS implementation for FlowFit, following best practices from Very Good Ventures' comprehensive Wear OS guide and official Flutter documentation.

## Device Compatibility

Optimized for Samsung Galaxy Watch 6 (40mm) and other Wear OS 3+ devices with:
- Round and square screen support
- Rotating bezel/crown input
- Ambient mode (always-on display)
- OLED battery optimization

## VGV Best Practices Implemented

### 1. Material 3 with Visual Density
- `useMaterial3: true` for modern Wear OS 3 compatibility
- `VisualDensity.compact` for optimal small screen spacing
- Dark theme with OLED optimization (saves battery)

### 2. Ambient Mode Support (Battery Saving)
- Automatic switching between active and ambient modes
- Monochromatic color scheme in ambient mode
- Theme adapts dynamically based on power state
- Reduced animations and simplified layouts

### 3. Rotary Input Support
- Full support for rotating bezel (Galaxy Watch 6)
- Rotating crown support (Pixel Watch)
- Navigate between screens using physical rotation
- Smooth page transitions with rotary events

### 4. Watch Shape Detection
- Automatic detection of round vs square watch faces
- Transparent background mode for seamless round screens
- Adaptive padding and layouts for different screen shapes

### 3. Dashboard Shortcuts
The Wear OS app opens to a compact dashboard with direct shortcuts:

#### Heart Rate
- Opens `wear_heart_rate_screen.dart`
- Large BPM display
- START/STOP tracking control
- SEND action for phone handoff after a reading is available
- Samsung Health service fallback in emulator/debug environments

#### Workout
- Opens `workout_screen.dart`
- Local workout timer
- BPM and calorie estimates
- Large circular start/stop control

#### Relax
- Opens `relax_screen.dart`
- Guided breathing session timer
- Animated active-mode background
- Start/pause control

Ambient mode keeps the dashboard non-interactive to reduce accidental input
and battery use.

### 4. Additional Screens

#### Workout Tracking Screen (`workout_screen.dart`)
- Real-time workout timer
- Heart rate and calorie tracking
- Large circular play/stop button
- Ambient mode support with minimal display

#### Relax/Meditation Screen (`relax_screen.dart`)
- Background gradient animation
- Audio playback controls
- Soothing visual transitions
- Ambient mode with static display

## Android Configuration

### AndroidManifest.xml Updates
```xml
<!-- Wear OS feature declaration -->
<uses-feature android:name="android.hardware.type.watch" />

<!-- Standalone app support -->
<meta-data
    android:name="com.google.android.wearable.standalone"
    android:value="true" />

<!-- Required permissions -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
```

### MainActivity.kt Updates (VGV Best Practices)
- Transparent background mode: `intent.putExtra("background_mode", "transparent")`
- Rotary input support via `onGenericMotionEvent` callback
- Proper lifecycle handling for Wear OS
- Method channels for Samsung Health integration

### build.gradle.kts Dependencies
```kotlin
// Minimum SDK 30 (Wear OS 3+) - VGV recommendation
minSdk = 30

// Wear OS libraries
implementation("androidx.wear:wear:1.3.0")
implementation("com.google.android.support:wearable:2.9.0")
  // Was `compileOnly` previously; using `implementation` to ensure runtime classes
  // (e.g. `WearableActivityController`) are available when plugins run on-device.
  implementation("com.google.android.wearable:wearable:2.9.0")

// Health Services
implementation("androidx.health:health-services-client:1.0.0-beta03")
```

### Flutter Dependencies
```yaml
dependencies:
  wear_plus: ^1.2.4      # Ambient mode & shape detection
  wearable_rotary: ^2.0.3 # Rotating bezel/crown support
```

## UI Design Principles (VGV Best Practices)

### One-Finger UI
- All interactions designed for single-finger input
- No multi-touch gestures required
- Large, easy-to-tap buttons

### Tiny Display Optimization
- Each view is self-contained (minimal scrolling)
- Visual density set to compact
- Font sizes optimized for 40mm screen
- Reduced padding (12px round, 10px square)

### Battery Conservation
- Dark backgrounds for OLED screens
- Monochromatic theme in ambient mode
- Minimal animations
- Efficient rendering

### Shape Adaptation
- Transparent background for seamless round screens
- Adaptive layouts for square watches
- Content properly centered
- Page indicators for navigation feedback

### Input Variety
- Touch screen support
- Rotating bezel navigation (Galaxy Watch 6)
- Physical button support
- Swipe gestures between pages

## Running the Wear OS App

### Development
```bash
# Run on connected Wear OS device
flutter run -d <wear_device_id> -t lib/main_wear.dart

# Build APK for Wear OS
flutter build apk -t lib/main_wear.dart
```

### Testing Ambient Mode
1. Enable Developer Options on Wear OS device
2. Enable "Stay awake when charging" (optional)
3. Let screen timeout to test ambient mode transition
4. Tap screen to return to active mode

## Known Limitations

As mentioned in the article:
- Some Material Icons may not display correctly on Wear OS
- watchOS support is not yet available in Flutter
- Performance optimization needed for complex animations
- Battery consumption should be monitored during extended use

## Future Enhancements

1. **Audio Playback**: Integrate `audioplayers` plugin for meditation sounds
2. **Real Sensor Data**: Connect to Samsung Health Sensor API for live metrics
3. **Workout Types**: Add multiple workout type selection
4. **Complications**: Add watch face complications support
5. **Notifications**: Implement workout completion notifications
6. **Data Sync**: Sync workout data with main mobile app

## Resources

- [Flutter Wear OS Guide](https://flutter.dev/docs/development/platform-integration/wear)
- [wear_plus Plugin](https://pub.dev/packages/wear_plus)
- [Wear OS Design Guidelines](https://developer.android.com/training/wearables/design)
- [Samsung Health Sensor API](https://developer.samsung.com/health)

## Testing Checklist

- [ ] App launches on Wear OS device
- [ ] Ambient mode transitions work correctly
- [ ] All 4 screens are swipeable
- [ ] Buttons are properly sized and responsive
- [ ] Text is readable on small screen
- [ ] Round and square watch faces display correctly
- [ ] Battery consumption is acceptable
- [ ] App works as standalone (no phone required)
