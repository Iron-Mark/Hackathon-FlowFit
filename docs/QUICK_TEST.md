# Quick Test Guide

## 🚀 Test in 3 Steps

### 1. Deploy Apps
```bash
# Terminal 1: Phone app
cd scripts
test-phone.bat

# Terminal 2: Watch app
test-watch.bat
```

### 2. Test Heart Rate
1. Open watch app
2. Tap "Heart Rate" button
3. Tap "START"
4. Wait 5-10 seconds for reading
5. Tap "SEND"
6. Check phone app receives data

### 3. Check Logs (if issues)
```bash
# Watch connection logs
adb -s SM_R930 logcat | findstr "WatchToPhoneSync"

# Should see:
# ✓ Connected node: [Phone Name]
# ✓ Message sent successfully
```

## ✅ What You Should See

### On Watch
```
┌──────────────┐
│   FlowFit    │
│   ❤️ Icon    │
│              │
│  ┌────────┐  │
│  │  ❤️    │  │
│  │  Heart │  │
│  │  Rate  │  │
│  └────────┘  │
└──────────────┘
```

Tap → Heart Rate Screen:
```
┌──────────────┐
│      ❤️      │
│              │
│      72      │
│      BPM     │
│              │
│   [START]    │
│   [SEND]     │
│              │
│      ●       │
│    Ready     │
└──────────────┘
```

### On Phone
- Heart rate card updates with new reading
- Shows BPM, timestamp, IBI values
- Recent readings list updates

## 🐛 Troubleshooting

### "No connected nodes"
→ Check Galaxy Wearable app shows watch connected
→ Restart both apps

### "SDK unavailable"
→ Ensure Samsung Health installed on watch
→ Grant body sensor permission

### "Send failed"
→ Ensure phone app is running
→ Check logs: `adb -s 22101320G logcat | findstr "PhoneDataListener"`

## 📚 More Help

- **Connection issues:** `docs/WATCH_CONNECTION_GUIDE.md`
- **Device commands:** `DEVICE_REFERENCE.md`

## 🎯 Success Criteria

✅ Watch shows "Ready" status
✅ Heart rate reading appears (5-10 sec)
✅ "SEND" button works
✅ Phone receives and displays data
✅ Logs show "✓ Message sent successfully"

That's it! You're done. 🎉
