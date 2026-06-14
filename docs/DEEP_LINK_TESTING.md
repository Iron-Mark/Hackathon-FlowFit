# Deep Link Testing Guide

This guide shows you how to test deep linking without waiting for emails.

## Prerequisites

- Android device or emulator connected
- ADB (Android Debug Bridge) installed
- FlowFit app installed on device

## 1. Verify ADB Connection

```bash
# List connected devices
adb devices

# Should show something like:
# List of devices attached
# 22101320G       device
```

## 2. Test Deep Link Opening

### Basic Deep Link Test

Test if the app opens with a deep link:

```bash
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.oldstlabs.flowfit://auth-callback" \
  com.oldstlabs.flowfit
```

**Expected Result**: FlowFit app should open

### Test with Query Parameters

Simulate an auth callback with parameters:

```bash
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.oldstlabs.flowfit://auth-callback?type=signup&token=test123" \
  com.oldstlabs.flowfit
```

### Test Development Scheme

```bash
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.oldstlabs.flowfit.dev://auth-callback?type=signup" \
  com.oldstlabs.flowfit
```

## 3. Monitor App Logs

While testing, monitor the app logs to see debug output:

```bash
# Filter for FlowFit logs
adb logcat | grep -i "flutter\|flowfit"

# Or more specific
adb logcat | grep -i "deep link\|auth"
```

**Look for**:
- "Handling deep link: ..."
- "Auth state changed: ..."
- "User signed in via deep link: ..."

## 4. Test Real Email Flow

### Step 1: Sign Up

1. Run the app
2. Go to Sign Up screen
3. Enter a real email address you can access
4. Complete sign up

### Step 2: Check Email

1. Open your email inbox
2. Find the verification email from Supabase
3. Note the link format

### Step 3: Click Link

1. Click the verification link on your device
2. App should open automatically
3. User should be verified

### Step 4: Verify in Logs

```bash
adb logcat | grep -i "auth"
```

Look for successful authentication messages.

## 5. Test Error Handling

### Test with Invalid Token

```bash
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.oldstlabs.flowfit://auth-callback?error=invalid_token&error_description=Token%20expired" \
  com.oldstlabs.flowfit
```

**Expected**: App should handle error gracefully

### Test with Missing Parameters

```bash
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.oldstlabs.flowfit://auth-callback" \
  com.oldstlabs.flowfit
```

**Expected**: App should not crash

## 6. Verify Android Manifest

Check that your intent filter is registered:

```bash
# Dump app info
adb shell dumpsys package com.oldstlabs.flowfit | grep -A 20 "intent-filter"
```

**Look for**:
```
Action: "android.intent.action.VIEW"
Category: "android.intent.category.DEFAULT"
Category: "android.intent.category.BROWSABLE"
Scheme: "com.oldstlabs.flowfit"
Host: "auth-callback"
```

## 7. Android App Links Note

FlowFit auth callbacks currently use custom URI schemes:

- `com.oldstlabs.flowfit://auth-callback`
- `com.oldstlabs.flowfit.dev://auth-callback`

Do not use `adb shell pm get-app-links` as pass/fail evidence for these callbacks. That command verifies HTTPS Android App Links, not custom schemes. Digital Asset Links files are only needed if FlowFit later adds HTTPS app links.

## 8. Common Issues & Solutions

### Issue: App doesn't open

**Check**:
```bash
# Verify app is installed
adb shell pm list packages | grep flowfit

# Check if intent filter is registered
adb shell dumpsys package com.oldstlabs.flowfit | grep -A 10 "intent-filter"
```

**Solution**:
- Reinstall the app
- Verify AndroidManifest.xml has correct intent filter
- Check that `android:exported="true"` on MainActivity

### Issue: Link opens in browser

**Cause**: Android hasn't associated the scheme with your app

**Solution**:
- Try opening the link multiple times
- Clear default app associations:
  ```bash
  adb shell pm clear-package-preferred-activities com.oldstlabs.flowfit
  ```
- For custom schemes (not HTTPS), this is expected behavior on first use

### Issue: App crashes on deep link

**Check logs**:
```bash
adb logcat | grep -i "exception\|error"
```

**Common causes**:
- Missing deep link handler in code
- Null pointer when parsing URI
- Navigation context not available

## 9. Automated Testing Script

Create a test script `test_deep_links.sh`:

```bash
#!/bin/bash

echo "Testing FlowFit Deep Links..."

# Test 1: Basic deep link
echo "Test 1: Basic deep link"
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.oldstlabs.flowfit://auth-callback" \
  com.oldstlabs.flowfit
sleep 2

# Test 2: With parameters
echo "Test 2: With auth parameters"
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.oldstlabs.flowfit://auth-callback?type=signup&token=test123" \
  com.oldstlabs.flowfit
sleep 2

# Test 3: Development scheme
echo "Test 3: Development scheme"
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.oldstlabs.flowfit.dev://auth-callback" \
  com.oldstlabs.flowfit
sleep 2

# Test 4: Error handling
echo "Test 4: Error handling"
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.oldstlabs.flowfit://auth-callback?error=test_error" \
  com.oldstlabs.flowfit

echo "Tests complete!"
```

Run with:
```bash
chmod +x test_deep_links.sh
./test_deep_links.sh
```

## 10. Production Testing Checklist

Before releasing:

- [ ] Test on multiple Android versions (8.0+)
- [ ] Test on different device manufacturers (Samsung, Google, etc.)
- [ ] Test with real email addresses
- [ ] Test email delivery time
- [ ] Test link expiration (24 hours)
- [ ] Test error scenarios
- [ ] Test with slow network
- [ ] Test with app in background
- [ ] Test with app closed
- [ ] Verify analytics/logging works

## 11. Debugging Tips

### Enable Verbose Logging

In your `DeepLinkHandler`, add more debug output:

```dart
debugPrint('=== DEEP LINK DEBUG ===');
debugPrint('URI: $uri');
debugPrint('Host: ${uri.host}');
debugPrint('Path: ${uri.path}');
debugPrint('Query: ${uri.queryParameters}');
debugPrint('======================');
```

### Check Supabase Logs

In Supabase Dashboard:
1. Go to Logs Explorer
2. Filter for auth events
3. Look for verification attempts

### Use Flutter DevTools

```bash
flutter run --observatory-port=8888
```

Then open DevTools to inspect network requests and state.

## Resources

- [ADB Documentation](https://developer.android.com/studio/command-line/adb)
- [Android Deep Links](https://developer.android.com/training/app-links)
- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
