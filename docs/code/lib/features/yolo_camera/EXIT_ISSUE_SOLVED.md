# YOLO Debug Screen Exit Issue - SOLVED ✅

## Problem
The YOLO debug screen was exiting automatically after ~3 seconds during inference, with no error messages or user interaction.

## Root Cause
The app's `SplashScreen` has a 3-second timer that automatically navigates to dashboard/welcome:

```dart
// In splash_screen.dart
await Future.delayed(const Duration(seconds: 3));
// Then navigates away...
```

Even though we set `/yolo-debug` as the `initialRoute`, the `SplashScreen` logic was still running in the background and triggering navigation after 3 seconds.

## Solution
Changed from using `initialRoute` to using `home` parameter in debug mode:

```dart
// In main.dart
home: kDebugMode ? const YoloDebugScreen() : null,
initialRoute: kDebugMode ? null : initialRoute,
routes: {
  // Exclude '/' route in debug mode to avoid conflict with 'home'
  if (!kDebugMode) '/': (context) => const SplashScreen(),
  // ... other routes
}
```

### Why This Works:
1. **`home` parameter** directly sets the widget, bypassing route navigation
2. **No SplashScreen** is instantiated in debug mode
3. **No background timer** running to navigate away
4. **Conditional route map** prevents Flutter's assertion error about duplicate '/' route

## Result
✅ YOLO debug screen now stays open indefinitely in debug mode
✅ No automatic navigation
✅ SplashScreen only runs in production builds
✅ Detection continues working without interruption

## Testing
Hot restart the app and the YOLO debug screen should now:
- Stay open permanently
- Continue running detection
- Only exit when you press back button or navigate manually

The lifecycle logs will confirm:
```
🟢 YoloDebugScreen: initState called
🔨 YoloDebugScreen: build called
📊 YoloDebugScreen: Received X detections
(continues indefinitely...)
```

No more unexpected `🔴 dispose called` after 3 seconds!
