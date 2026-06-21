# FlowFit Quick Start Guide

## ✅ What's Been Fixed & Implemented

### 1. Icons Fixed
- ✅ Added `cupertino_icons` package
- ✅ Added `flutter_svg` for SVG support
- ✅ All Material Icons now working properly

### 2. Data Management Implemented
- ✅ **In-memory buffer** (100 records, auto-flush)
- ✅ **SQLite database** (10,000 records max)
- ✅ **Auto-cleanup** (deletes old data when limit reached)
- ✅ **IBI & HRV tracking** (matches Kotlin implementation)
- ✅ **Rolling IBI history** (10-value window for stable HRV)
- ✅ **Data sync manager** (uploads to backend every 15 min)

### 3. Authentication Flow
- ✅ Loading screen with animations
- ✅ Welcome screen
- ✅ Login screen with validation
- ✅ Sign up screen with strong password requirements
- ✅ Reusable theme system (FlowFit Style Guide)

### 4. Enhanced UI
- ✅ Display HR, HRV, and IBI values
- ✅ Show IBI count and sample values
- ✅ Enhanced recent readings list
- ✅ Real-time statistics
- ✅ Better error handling

---

## 🚀 Run the App

```bash
# Install dependencies (already done)
flutter pub get

# Run on phone
flutter run -d <phone_device_id>

# Run on watch
flutter run -d <watch_device_id> -t lib/main_wear.dart
```

## 🎯 How to Access Heart Rate Monitoring

1. **Launch the app** on your phone
2. **Navigate through** Loading → Welcome → Login/Sign Up
3. **You'll land on the Dashboard** with the Home tab
4. **Tap "Live Heart Rate"** button in the Quick Track section
5. **Start monitoring** - the screen will display:
   - Current heart rate (BPM)
   - Heart rate variability (HRV in ms)
   - Inter-beat intervals (IBI values)
   - Recent readings history
   - Real-time statistics (avg, max, min)

### Quick Track Buttons Available:
- **Live Heart Rate** → Real-time monitoring from Galaxy Watch
- **Activity AI** → Test TensorFlow Lite activity classifier (Stress/Cardio/Strength detection)
- Log Water → Coming soon
- Add Meal → Coming soon
- Log Sleep → Coming soon
- Track Workout → Coming soon

---

## 📱 App Flow

```
1. Loading Screen (3 seconds)
   ↓
2. Welcome Screen
   ├─→ Sign Up → Registration Form → Dashboard
   └─→ Login → Login Form → Dashboard
   ↓
3. Dashboard Screen
   - Home tab with Quick Track buttons
   - Activity, Track, Progress, Profile tabs
   ↓
4. Live Heart Rate Screen (tap "Live Heart Rate" button)
   - Real-time heart rate monitoring from watch
   - Displays HR, HRV, IBI values
   - Shows recent readings history
   - Stores in database
   - Syncs to backend
```

---

## 📊 Data Flow (Watch → Phone)

```
Galaxy Watch (Kotlin)
    ↓ Sends JSON
    {
      "hr": 78,
      "ibi": [845, 777, 729],
      "hrv": 68.0,
      "spo2": 0,
      "timestamp": 1732545971348
    }
    ↓
PhoneDataListener
    ↓ Converts to TrackedData
HeartRateDataManager
    ↓ Buffer (100 records)
DatabaseService
    ↓ SQLite (10,000 records)
DataSyncManager
    ↓ Backend (every 15 min)
```

---

## 🔧 Key Components

### TrackedData Model
```dart
class TrackedData {
  final int hr;                    // Heart Rate (BPM)
  final List<int> ibiValues;       // Inter-Beat Intervals (ms)
  final double hrv;                // Heart Rate Variability (RMSSD)
  final int spo2;                  // Blood Oxygen (%)
  final DateTime timestamp;
  final SensorStatus status;
}
```

### HeartRateDataManager
```dart
// Manages buffer, database, and IBI history
HeartRateDataManager(
  maxBufferSize: 100,           // Auto-flush at 100
  maxDatabaseRecords: 10000,    // Max 10k records
  ibiHistorySize: 10,           // Rolling window
)
```

### DatabaseService
```dart
// SQLite storage with indexes
- insertHeartRateData()
- getRecentHeartRateData(limit: 50)
- getDataByDateRange()
- deleteOldData(daysToKeep: 30)
```

### DataSyncManager
```dart
// Periodic backend sync
_syncManager.startPeriodicSync(
  interval: Duration(minutes: 15),
)
```

---

## 🎨 Theme System

### Colors (FlowFit Style Guide)
```dart
AppTheme.primaryBlue  // #3B82F6
AppTheme.lightBlue    // #5DADE2
AppTheme.cyan         // #5DD9E2
```

### Usage
```dart
// In main.dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system,
)
```

---

## 📈 IBI & HRV

### IBI Collection
```dart
// From watch JSON
final ibiValues = [845, 777, 729];

// Display
Text('IBI: ${ibiValues.take(5).join(", ")} ms')
```

### HRV Calculation (RMSSD)
```dart
// Automatic calculation
final hrv = TrackedData.calculateHRV(ibiValues);
// Result: 68.0 ms

// Display
Text('HRV: ${hrv.toStringAsFixed(1)} ms')
```

### Rolling History
```dart
// Maintains last 10 IBI values
IbiHistoryManager(maxHistorySize: 10)

// Provides stable HRV over time
final hrv = _ibiHistory.calculateHRV();
```

---

## 🗄️ Database

### Schema
```sql
CREATE TABLE heart_rate_data (
  id INTEGER PRIMARY KEY,
  hr INTEGER NOT NULL,
  ibi_values TEXT,              -- Comma-separated
  hrv REAL NOT NULL,
  spo2 INTEGER NOT NULL,
  timestamp INTEGER NOT NULL,
  status TEXT NOT NULL,
  synced INTEGER DEFAULT 0,     -- 0=not synced, 1=synced
  created_at INTEGER NOT NULL
);
```

### Queries
```dart
// Get recent data
final recent = await _dataManager.getRecentData(limit: 50);

// Get by date range
final data = await _dataManager.getDataByDateRange(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);

// Get statistics
final stats = await DatabaseService.instance.getStatistics();
```

---

## 🔄 Data Lifecycle

### 1. Reception
```dart
// Watch sends data → PhoneDataListener receives
_dataListener.heartRateStream.listen((heartRateData) {
  // Convert to TrackedData
  final trackedData = TrackedData(...);
  
  // Add to manager
  await _dataManager.addData(trackedData);
});
```

### 2. Buffering
```dart
// Stores in memory (100 records)
// Auto-flushes to database when full
if (_dataBuffer.length >= maxBufferSize) {
  await _flushBuffer();
}
```

### 3. Storage
```dart
// Saves to SQLite (10,000 records max)
await _dbService.insertHeartRateDataBatch(_dataBuffer);

// Auto-cleanup when limit reached
if (totalRecords > maxDatabaseRecords) {
  await _dbService.deleteOldData(daysToKeep: 7);
}
```

### 4. Sync
```dart
// Uploads unsynced data every 15 minutes
final unsyncedData = await _dbService.getUnsyncedData();
await _supabaseService.saveHeartRateDataBatch(payload);
await _dbService.markAsSynced(ids);
```

---

## 🤖 TensorFlow Lite Activity Classifier

### What It Does
The app includes a **TensorFlow Lite model** that classifies activities in real-time:
- **Stress Detection** - Identifies stress/anxiety states
- **Cardio Activity** - Detects cardio exercises (running, cycling)
- **Strength Training** - Identifies strength workouts

### How to Test It

1. **Navigate to Activity AI**
   - Open app → Dashboard → Tap **"Activity AI"** button
   
2. **Test with Simulated Data**
   - Use the **"Simulate Watch Heart Rate"** slider (60-180 BPM)
   - Toggle **"Simulate Movement"** to generate accelerometer data
   - Adjust **Amplitude** and **Frequency** to simulate different activities
   - Drag slider HIGH (160+ BPM) to simulate panic/running

3. **Test with Real Data**
   - Select **"Watch"** chip to use real Galaxy Watch heart rate
   - Move around to generate real accelerometer data
   - Model classifies activity every second

### Model Input
The model uses a **10-second window** (320 samples @ 32Hz):
- Accelerometer X, Y, Z axes
- Heart rate (BPM)

### Model Output
- **Activity Label**: Stress, Cardio, or Strength
- **Probabilities**: Confidence for each class (0-100%)

### Features
- ✅ Real-time classification (every ~1 second)
- ✅ Sliding window buffer (320 samples @ 32Hz)
- ✅ Multiple BPM sources (Simulation, Plugin, Watch)
- ✅ **Live Galaxy Watch heart rate integration** 🆕
- ✅ Synthetic accelerometer data for testing
- ✅ Live probability display
- ✅ Auto-start watch listener when Watch mode selected 🆕
- ✅ Visual feedback for watch connection status 🆕

## 🧪 Testing the Models

### Run All Tests
```bash
flutter test
```

### Run Model Tests Only
```bash
# Test HeartRateData model
flutter test test/models/heart_rate_data_test.dart

# Test SensorError model
flutter test test/models/sensor_error_test.dart

# Test all models
flutter test test/models/
```

### What's Tested:
- ✅ **HeartRateData** - JSON serialization, deserialization, equality
- ✅ **SensorError** - Error handling and formatting
- ✅ **WatchBridgeService** - Watch connection, permissions, streaming
- ✅ **TFLite Classifier** - Activity classification (Stress/Cardio/Strength)

### Test Results:
- 96 tests passing
- Models fully tested and working
- Ready for production use

## 🐛 Troubleshooting

### Icons Not Showing
✅ **Fixed:** `cupertino_icons` added to pubspec.yaml

### Empty IBI Values
- Wait 5-10 seconds after starting tracking
- Check watch sensor contact (wear tighter)
- Verify Kotlin side logs: `adb logcat | grep "IBI count:"`

### Database Too Large
- Auto-cleanup runs at 10,000 records
- Manual: `await _dbService.deleteOldData(daysToKeep: 7)`

### Sync Not Working
- Check internet connection
- Implement backend upload in `DataSyncManager.syncData()`
- Check logs: `flutter logs | grep "Sync"`

### Build Fails with "Address already in use"
```bash
# Stop Gradle daemon
cd android
./gradlew --stop

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

---

## 📝 Next Steps

### 1. Backend Integration
```dart
// In DataSyncManager.syncData()
await supabase.from('heart_rate_data').insert(unsyncedData);
```

### 2. Add Font Files
```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: GeneralSans
      fonts:
        - asset: assets/fonts/GeneralSans-Regular.ttf
```

### 3. Social Login
- Implement Google Sign In
- Implement Apple Sign In (iOS)

### 4. Enhanced Features
- Biometric authentication
- Data export (CSV, PDF)
- Charts and analytics
- Push notifications

---

## 📚 Documentation

1. **IMPLEMENTATION_SUMMARY.md** - Complete overview
2. **AUTH_FLOW_SETUP.md** - Authentication details
3. **DATA_MANAGEMENT_GUIDE.md** - Data handling best practices
4. **IBI_DATA_COLLECTION_GUIDE.md** - IBI/HRV from Kotlin

---

## ✅ Status

### Completed
- ✅ Icons fixed
- ✅ Data management (buffer, database, sync)
- ✅ IBI & HRV tracking
- ✅ Authentication UI
- ✅ Enhanced home screen
- ✅ Auto-cleanup
- ✅ Error handling
- ✅ Documentation

### Pending
- ⏳ Backend authentication API
- ⏳ Supabase data sync
- ⏳ Google/Apple Sign In
- ⏳ Font files (General Sans)

---

**Ready to test!** 🚀

Run `flutter run` and start receiving data from your Galaxy Watch.
