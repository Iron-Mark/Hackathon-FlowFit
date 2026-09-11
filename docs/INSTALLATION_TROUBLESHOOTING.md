# Installation Troubleshooting Guide

## Current Issues and Solutions

### Issue 1: `INSTALL_FAILED_MISSING_SHARED_LIBRARY: com.google.android.wearable`

**Problem**: The app requires the Google Wearable library which may not be available on all watches.

**Solution Applied**:
- Changed `android:required="true"` to `android:required="false"` in AndroidManifest.xml
- This makes the wearable library optional

**File**: `android/app/src/main/AndroidManifest.xml`
```xml
<uses-library
    android:name="com.google.android.wearable"
    android:required="false" />
```

### Issue 2: `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`

**Problem**: Installation is blocked by watch security settings or user didn't approve.

**Solutions**:

1. **Approve on Watch**:
   - When installing, watch will show "Install app?" prompt
   - Tap "Install" or swipe right to approve
   - Must approve within ~30 seconds

2. **Enable Developer Options on Watch**:
   ```
   Settings → About → Tap "Build number" 7 times
   ```

3. **Enable ADB Debugging**:
   ```
   Settings → Developer options → ADB debugging → ON
   ```

4. **Disable "Verify apps over USB"** (if present):
   ```
   Settings → Developer options → Verify apps over USB → OFF
   ```

5. **Check Watch is Unlocked**:
   - Watch must be unlocked during installation
   - Keep screen on during install

### Issue 3: Build Errors (ConnectionListener)

**Problem**: Samsung Health SDK API compatibility issues.

**Solution Applied**:
- Simplified HealthTrackingManager to not use ConnectionListener
- Removed async connection logic
- Direct synchronous connection

**File**: `android/app/src/main/kotlin/com/example/flowfit/HealthTrackingManager.kt`

## Installation Methods

### Method 1: Using Build Script (Recommended)

```bash
# Run the automated build and install script
build_and_install.bat
```

This script will:
1. Clean previous builds
2. Get dependencies
3. Build APK
4. Install on watch (6ece264d)

### Method 2: Manual Flutter Run

```bash
# Clean first
flutter clean
flutter pub get

# Run on watch
flutter run -d 6ece264d
```

**Important**: When you see the installation prompt on your watch, you must approve it!

### Method 3: Manual ADB Install

```bash
# Build APK
flutter build apk --debug

# Install on watch
adb -s 6ece264d install -r build\app\outputs\flutter-apk\app-debug.apk
```

## Pre-Installation Checklist

Before attempting installation:

- [ ] Watch is connected: `adb devices` shows `6ece264d device`
- [ ] Watch is unlocked (screen on)
- [ ] Developer options enabled on watch
- [ ] ADB debugging enabled on watch
- [ ] Watch has sufficient battery (>20%)
- [ ] Previous version uninstalled (if any): `adb -s 6ece264d uninstall com.msiazondev.flowfit`

## Verification Steps

After installation:

1. **Check app is installed**:
   ```bash
   adb -s 6ece264d shell pm list packages | findstr flowfit
   ```
   Should show: `package:com.msiazondev.flowfit`

2. **Launch app**:
   ```bash
   adb -s 6ece264d shell am start -n com.msiazondev.flowfit/.MainActivity
   ```

3. **View logs**:
   ```bash
   adb -s 6ece264d logcat | findstr "FlowFit MainActivity HealthTrackingManager"
   ```

## Common Error Messages

### "Performing Streamed Install"
- Normal message, wait for completion
- Watch will show approval prompt

### "INSTALL_FAILED_UPDATE_INCOMPATIBLE"
```bash
# Uninstall old version first
adb -s 6ece264d uninstall com.msiazondev.flowfit
# Then reinstall
flutter run -d 6ece264d
```

### "device offline"
```bash
# Reconnect watch
adb disconnect
adb connect <watch-ip>
# Or restart ADB
adb kill-server
adb start-server
```

### "no devices/emulators found"
```bash
# Check connection
adb devices

# If watch not showing, check:
# 1. USB debugging enabled on watch
# 2. Watch connected via USB or WiFi
# 3. Galaxy Wearable app on phone
```

## Watch-Specific Settings

### Galaxy Watch Settings Path

1. **Enable Developer Mode**:
   - Settings → About watch → Software → Tap "Software version" 7 times
   - You'll see "Developer mode has been turned on"

2. **Enable ADB Debugging**:
   - Settings → Developer options → ADB debugging → Toggle ON
   - Approve the prompt

3. **Enable WiFi Debugging** (if using wireless):
   - Settings → Developer options → Debug over Wi-Fi → Toggle ON
   - Note the IP address shown

4. **Disable Verify Apps** (optional):
   - Settings → Developer options → Verify apps over USB → Toggle OFF

## Installation Approval on Watch

When installing, watch will show:

```
Install app?
FlowFit
com.msiazondev.flowfit

[Cancel]  [Install]
```

**You must tap "Install" within 30 seconds!**

If you miss it:
1. Installation will fail with `INSTALL_FAILED_USER_RESTRICTED`
2. Simply run the install command again
3. Be ready to tap "Install" on watch

## Testing After Installation

1. **Open app on watch**:
   - Swipe up from watch face
   - Find "FlowFit" icon
   - Tap to open

2. **Grant permissions**:
   - App will request "Body sensors" permission
   - Tap "Allow"

3. **Test heart rate**:
   - Wear watch on wrist
   - Tap "Connect" button
   - Tap "Start" button
   - Wait 5-10 seconds for readings

## Still Having Issues?

### Check Logcat for Errors

```bash
# Full logs
adb -s 6ece264d logcat

# Filtered logs
adb -s 6ece264d logcat | findstr "FlowFit MainActivity HealthTrackingManager"

# Save logs to file
adb -s 6ece264d logcat > watch_logs.txt
```

### Verify Samsung Health SDK

```bash
# Check if Samsung Health Tracking Service is installed
adb -s 6ece264d shell pm list packages | findstr samsung.android.service.health
```

Should show: `package:com.samsung.android.service.health.tracking`

If not present:
- Update Samsung Health app on watch
- Update watch firmware
- Check if watch model supports Samsung Health Sensor SDK (need Watch4+)

### Clean Reinstall

```bash
# Complete clean reinstall
flutter clean
adb -s 6ece264d uninstall com.msiazondev.flowfit
flutter pub get
flutter run -d 6ece264d
```

## Contact Support

If none of these solutions work:

1. Save logcat output: `adb -s 6ece264d logcat > error_log.txt`
2. Note your watch model and software version
3. Note the exact error message
4. Check Samsung Developer forums
5. Review Samsung Health Sensor SDK documentation

## Quick Reference Commands

```bash
# Check devices
adb devices

# Install app
adb -s 6ece264d install -r build\app\outputs\flutter-apk\app-debug.apk

# Uninstall app
adb -s 6ece264d uninstall com.msiazondev.flowfit

# Launch app
adb -s 6ece264d shell am start -n com.msiazondev.flowfit/.MainActivity

# View logs
adb -s 6ece264d logcat | findstr "FlowFit"

# Check installed packages
adb -s 6ece264d shell pm list packages | findstr flowfit

# Check Samsung Health
adb -s 6ece264d shell pm list packages | findstr samsung.android.service.health
```
