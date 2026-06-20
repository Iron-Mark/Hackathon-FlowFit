# Watch Connection Troubleshooting Guide

## Quick Fix Checklist

### 1. Verify Device Pairing
- Open Galaxy Wearable app on phone
- Ensure watch shows as "Connected"
- Check Bluetooth is enabled on both devices

### 2. Check App Installation
```bash
# Verify watch app is installed
adb -s SM_R930 shell pm list packages | findstr flowfit

# Verify phone app is installed  
adb -s 22101320G shell pm list packages | findstr flowfit
```

### 3. Test Connection
```bash
# Run watch app with logging
flutter run -d SM_R930 --release

# In another terminal, watch logs
adb -s SM_R930 logcat | findstr "WatchToPhoneSync\|HealthTracking"
```

## Common Issues

### Issue: "No connected nodes"
**Cause:** Phone and watch not paired or apps not running

**Fix:**
1. Open Galaxy Wearable app on phone
2. Ensure watch is connected
3. Start phone app first, then watch app
4. Check logs: `adb -s SM_R930 logcat | findstr "WatchToPhoneSync"`

### Issue: "SDK unavailable"
**Cause:** Samsung Health SDK not initialized

**Fix:**
1. Ensure Samsung Health is installed on watch
2. Grant all permissions when prompted
3. Restart watch app
4. Check logs: `adb -s SM_R930 logcat | findstr "HealthTracking"`

### Issue: "Send failed"
**Cause:** Message delivery failed

**Fix:**
1. Ensure phone app is running in foreground
2. Check phone logs: `adb -s 22101320G logcat | findstr "PhoneDataListener"`
3. Verify both devices on same Google account
4. Try restarting both apps

## Testing Steps

### 1. Deploy Watch App
```bash
cd scripts
test-watch.bat
```

### 2. Deploy Phone App
```bash
cd scripts
test-phone.bat
```

### 3. Test Heart Rate Flow
1. Open watch app → tap "Heart Rate"
2. Tap "START" → wait for heart rate reading
3. Tap "SEND" → check phone app receives data
4. Watch logs for connection status

## Log Analysis

### Watch Logs (Good Connection)
```
WatchToPhoneSync: === Checking phone connection ===
WatchToPhoneSync: ✓ Connected node: Xiaomi 11T Pro (abc123)
WatchToPhoneSync: === Sending heart rate data ===
WatchToPhoneSync: ✓ Message sent successfully
```

### Watch Logs (No Connection)
```
WatchToPhoneSync: === Checking phone connection ===
WatchToPhoneSync: ✗ No connected nodes found
WatchToPhoneSync: No connected nodes - ensure phone is paired
```

### Phone Logs (Receiving Data)
```
PhoneDataListener: Message received from watch
PhoneDataListener: Heart rate: 72 BPM
```

## UI Improvements

### New Clean Design
- **Dashboard:** Single large "Heart Rate" button
- **Heart Rate Screen:** 
  - Large BPM display (56pt font)
  - Simple START/STOP button
  - SEND button (appears after reading)
  - Minimal status indicator

### Removed Clutter
- No scrolling menu
- No unrelated menu items on the watch-first heart-rate screen
- No complex status messages
- Focus on core functionality

## Performance Tips

1. **Keep phone app running:** Android may kill background apps
2. **Use release mode:** Debug mode is slower on watch
3. **Check battery:** Low battery affects Bluetooth
4. **Stay nearby:** Keep devices within 10 meters

## Next Steps

If still having issues:
1. Check `adb devices` shows both devices
2. Verify permissions in Settings → Apps → FlowFit
3. Restart both devices
4. Re-pair watch in Galaxy Wearable app
