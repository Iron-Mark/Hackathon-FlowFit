# Debug Screen Error Tracking

## Added Features

### 1. Lifecycle Logging 📝
The screen now logs every lifecycle event with emoji prefixes for easy identification:

- 🟢 `initState` - Screen is being created
- 🔨 `build` - Screen is being rebuilt
- 🔄 `didChangeAppLifecycleState` - App goes to background/foreground
- ⚠️ `deactivate` - Screen is being deactivated
- 🔴 `dispose` - Screen is being destroyed
- ⬅️ `onWillPop` - Back button pressed
- 📊 `onDetection` - Detection results received
- ❌ `Error` - An error occurred
- 💥 `Exception` - Camera widget error
- 🏠 `Navigation` - User navigating away

### 2. Error Display UI
When an error occurs:
- ❌ Red app bar to indicate error state
- 🔄 Refresh button to retry
- 📋 Full error message displayed (selectable for copying)
- 🔙 "Go Back" button to exit gracefully

### 3. Error Recovery
- Errors are caught and displayed instead of crashing
- User can retry without restarting the app
- Error state is tracked separately from camera state

### 4. WillPopScope
- Detects when user presses back button
- Logs navigation events
- Helps identify if screen is exiting unexpectedly

## How to Use

### Watch the Console
Look for these emoji-prefixed logs:

```
🟢 YoloDebugScreen: initState called
🔨 YoloDebugScreen: build called
📊 YoloDebugScreen: Received 3 detections
⬅️ YoloDebugScreen: Back button pressed
🔴 YoloDebugScreen: dispose called
```

### If Screen Exits Unexpectedly
Check the console for:
1. **Last lifecycle event** - What was happening when it exited?
2. **Error messages** (❌ or 💥) - Was there an error?
3. **Navigation logs** (⬅️ or 🏠) - Did user navigate away?
4. **App lifecycle** (🔄) - Did app go to background?

### Common Patterns

**Normal Exit:**
```
⬅️ YoloDebugScreen: Back button pressed
🔴 YoloDebugScreen: dispose called
```

**Error Exit:**
```
💥 YoloDebugScreen: Error building camera widget: [error]
❌ YoloDebugScreen: Error occurred: [error]
🔴 YoloDebugScreen: dispose called
```

**Background Exit:**
```
🔄 YoloDebugScreen: App lifecycle changed to paused
🔴 YoloDebugScreen: dispose called
```

## Next Steps

1. **Run the app** and watch the console
2. **Note the last log** before the screen exits
3. **Share the logs** to identify the root cause
4. **Check error UI** if it appears on screen

The comprehensive logging will help us identify exactly why the screen is exiting!
