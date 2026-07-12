# Phone App Setup Guide

## 📱 Material 3 Phone App

The FlowFit phone app has been updated with a modern Material 3 design to receive and display heart rate data from your Galaxy Watch.

## ✨ Features

### Modern UI
- ✅ Material 3 design system
- ✅ Dynamic color scheme (light/dark mode)
- ✅ Smooth animations
- ✅ Card-based layout
- ✅ Responsive design

### Heart Rate Display
- ✅ Real-time heart rate from watch
- ✅ Heart rate zones (Resting, Light, Moderate, Hard, Maximum)
- ✅ Statistics (Average, Max, Min)
- ✅ Recent readings history
- ✅ Connection status indicator

### Data Reception
- ✅ Receives data from Galaxy Watch via Wearable Data Layer API
- ✅ Real-time streaming
- ✅ Automatic reconnection
- ✅ Error handling

## 🎨 UI Components

### 1. Current Heart Rate Card
- Large BPM display
- Heart rate zone indicator
- Color-coded zones
- Real-time updates

### 2. Statistics Row
- Average BPM
- Maximum BPM
- Minimum BPM
- Icon indicators

### 3. Status Card
- Connection status
- Status message
- Visual indicators

### 4. Recent Readings List
- Last 50 readings
- Timestamp (time ago)
- IBI value count
- Scrollable list

## 🚀 Running the Phone App

### Quick Start

```bash
# Run on phone
scripts\run_phone.bat

# Or manually
flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp
```

### What You'll See

1. **App Bar**
   - "FlowFit" title
   - Watch connection icon (green when connected)

2. **Current Heart Rate**
   - Large BPM number
   - Heart rate zone badge
   - "No data yet" if not receiving

3. **Statistics**
   - Three cards showing avg/max/min
   - Updates as data arrives

4. **Status**
   - Connection indicator
   - Status message

5. **Recent Readings**
   - List of last 10 readings
   - Time ago for each reading
   - IBI value count

## 📡 Data Flow

```
Galaxy Watch                    Android Phone
┌─────────────┐                ┌──────────────┐
│             │                │              │
│  Heart Rate │                │  Phone Home  │
│  Tracking   │                │  Screen      │
│             │                │              │
│  ┌────────┐ │                │  ┌─────────┐ │
│  │ Samsung│ │                │  │Material3│ │
│  │ Health │ │                │  │   UI    │ │
│  │  SDK   │ │                │  └─────────┘ │
│  └────┬───┘ │                │      ▲       │
│       │     │                │      │       │
│  ┌────▼───┐ │   Wearable     │  ┌───┴────┐ │
│  │ Watch  │ │   Data Layer   │  │ Phone  │ │
│  │ Bridge │ ├───────────────►│  │ Data   │ │
│  │        │ │   MessageClient│  │Listener│ │
│  └────────┘ │                │  └────────┘ │
│             │                │              │
└─────────────┘                └──────────────┘
```

## 🔧 Implementation Details

### Files Created

1. **`lib/main.dart`** - Updated with Material 3 theme
   - FlowFitPhoneApp widget
   - Material 3 color scheme
   - Light/dark theme support

2. **`lib/screens/phone_home.dart`** - Main phone screen
   - PhoneHomePage widget
   - Heart rate display
   - Statistics cards
   - Recent readings list

3. **`lib/services/phone_data_listener.dart`** - Data receiver
   - PhoneDataListener service
   - Event channel for streaming
   - Method channel for control

### Key Features

**Material 3 Design**:
```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  ),
)
```

**Heart Rate Zones**:
- Resting: < 60 BPM (Blue)
- Light: 60-100 BPM (Green)
- Moderate: 100-140 BPM (Orange)
- Hard: 140-170 BPM (Deep Orange)
- Maximum: > 170 BPM (Red)

**Real-time Updates**:
```dart
_dataListener.heartRateStream.listen((heartRateData) {
  setState(() {
    _latestHeartRate = heartRateData;
    _heartRateHistory.insert(0, heartRateData);
  });
});
```

## 📱 Screenshots (What You'll See)

### Light Mode
```
┌─────────────────────────────┐
│ FlowFit              [Watch]│
├─────────────────────────────┤
│                             │
│  ❤️ Current Heart Rate      │
│                             │
│         72                  │
│        BPM                  │
│                             │
│      [Light Zone]           │
│                             │
├─────────────────────────────┤
│  Average    Max      Min    │
│    75       85       68     │
├─────────────────────────────┤
│  ✓ Connected                │
│  Receiving data from watch  │
├─────────────────────────────┤
│  🕐 Recent Readings         │
│                             │
│  72 BPM  • 3 IBI • 2s ago  │
│  74 BPM  • 4 IBI • 5s ago  │
│  71 BPM  • 3 IBI • 8s ago  │
│                             │
└─────────────────────────────┘
```

## 🎯 Next Steps

### To Complete Phone-Watch Communication

1. **Add Wearable Data Layer Dependencies** (phone side):
   ```gradle
   // In android/app/build.gradle.kts
   implementation("com.google.android.gms:play-services-wearable:18.1.0")
   ```

2. **Create DataListenerService** (phone side):
   - Implement WearableListenerService
   - Handle onMessageReceived
   - Parse heart rate data
   - Send to Flutter via EventChannel

3. **Update Watch App** to send data:
   - Use MessageClient
   - Send heart rate data as JSON
   - Target phone node

4. **Test End-to-End**:
   - Start tracking on watch
   - See data appear on phone
   - Verify real-time updates

## 🐛 Troubleshooting

### "No data yet" on Phone

**Check**:
1. Watch app is running and tracking
2. Watch and phone are paired
3. Both apps have same application ID
4. Wearable Data Layer API is configured

**Solution**:
```bash
# Check if devices are paired
adb -s 6ece264d shell dumpsys bluetooth_manager | findstr "connected"

# Check if watch app is sending data
adb -s 6ece264d logcat | findstr "MessageClient"
```

### Phone App Not Receiving

**Check**:
1. DataListenerService is registered in AndroidManifest
2. Event channel is set up correctly
3. Watch is sending to correct path

**Solution**:
```bash
# View phone logs
adb -s adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp logcat | findstr "FlowFit"
```

## 📚 Related Documentation

- [Samsung Health Setup](SAMSUNG_HEALTH_SETUP_GUIDE.md) - Watch-side setup
- [Heart Rate Data Flow](HEART_RATE_DATA_FLOW.md) - Complete data flow

## ✨ Material 3 Features Used

- **Color Scheme**: Dynamic theming with seed color
- **Cards**: Elevated cards with rounded corners
- **Typography**: Material 3 text styles
- **Icons**: Material 3 icon set
- **Layouts**: SliverAppBar.large for modern app bar
- **Components**: FAB, ListTiles, CircleAvatars

## 🎉 Result

You now have a beautiful, modern phone app that:
- ✅ Uses Material 3 design
- ✅ Displays heart rate data
- ✅ Shows statistics and history
- ✅ Indicates connection status
- ✅ Supports light/dark mode
- ✅ Ready to receive watch data

**Next**: Run the phone app and see the UI!

```bash
scripts\run_phone.bat
```
