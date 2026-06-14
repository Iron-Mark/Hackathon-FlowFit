# FlowFit Navigation Guide

## 🗺️ App Navigation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        LOADING SCREEN                           │
│                      (3 second splash)                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                       WELCOME SCREEN                            │
│                                                                 │
│              [Sign Up]          [Login]                         │
└──────────────┬──────────────────────┬──────────────────────────┘
               │                      │
               ▼                      ▼
        ┌─────────────┐        ┌─────────────┐
        │  SIGN UP    │        │   LOGIN     │
        │   SCREEN    │        │   SCREEN    │
        └──────┬──────┘        └──────┬──────┘
               │                      │
               └──────────┬───────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DASHBOARD SCREEN                           │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                      HOME TAB                           │   │
│  │                                                         │   │
│  │  Good Morning, Jim!                                     │   │
│  │  Let's make today a great day.                          │   │
│  │                                                         │   │
│  │  ┌──────────┐  ┌──────────┐                            │   │
│  │  │  Steps   │  │ Calories │                            │   │
│  │  │  6504    │  │  6504    │                            │   │
│  │  └──────────┘  └──────────┘                            │   │
│  │                                                         │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │         5-Day Streak 🔥                         │   │
│  │  │  You're on fire! Keep the momentum going.       │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                                                         │   │
│  │  Quick Track:                                           │   │
│  │  ┌──────────────┐  ┌──────────────┐                    │   │
│  │  │ Live Heart   │  │ Activity AI  │                    │   │
│  │  │ Rate ❤️      │  │ 🤖 TFLite    │                    │   │
│  │  │ Monitor from │  │ Model        │                    │   │
│  │  │ watch        │  │ classifier   │                    │   │
│  │  └──────┬───────┘  └──────┬───────┘                    │   │
│  │         │                  │                            │   │
│  │  ┌──────┴───────┐  ┌──────┴───────┐                    │   │
│  │  │ Log Water 💧 │  │ Add Meal 🍽️  │                    │   │
│  │  └──────────────┘  └──────────────┘                    │   │
│  │                                                         │   │
│  │  ┌──────────────┐  ┌──────────────┐                    │   │
│  │  │ Log Sleep 🌙 │  │ Track        │                    │   │
│  │  │              │  │ Workout 🏃   │                    │   │
│  │  └──────────────┘  └──────────────┘                    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  [Home] [Activity] [Track] [Progress] [Profile]                │
└─────────────────────────────────────────────────────────────────┘
                          │
                          │ Tap "Live Heart Rate"
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                  LIVE HEART RATE SCREEN                         │
│                                                                 │
│  FlowFit                                    [2 buffered] 🟢     │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Current Heart Rate ❤️                      │   │
│  │                                                         │   │
│  │                      78                                 │   │
│  │                     BPM                                 │   │
│  │                                                         │   │
│  │                  [ Light ]                              │   │
│  │                                                         │   │
│  │              HRV: 68.0 ms 📊                            │   │
│  │         IBI: 845, 777, 729 ms                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                     │
│  │ Average  │  │   Max    │  │   Min    │                     │
│  │   75     │  │   82     │  │   68     │                     │
│  └──────────┘  └──────────┘  └──────────┘                     │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ ✅ Connected                                            │   │
│  │    Received from watch                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Recent Readings 📜                    50 readings       │   │
│  │                                                         │   │
│  │  ● 78 BPM                                          ❤️   │   │
│  │    HRV: 68.0 ms • IBI: 3 • 2s ago                 📊   │   │
│  │  ─────────────────────────────────────────────────────  │   │
│  │  ● 75 BPM                                          ❤️   │   │
│  │    HRV: 65.2 ms • IBI: 3 • 5s ago                 📊   │   │
│  │  ─────────────────────────────────────────────────────  │   │
│  │  ● 72 BPM                                          ❤️   │   │
│  │    HRV: 62.8 ms • IBI: 3 • 8s ago                 📊   │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│                                          [Save 2] [Clear] 🔘   │
└─────────────────────────────────────────────────────────────────┘

                          │ Back to Dashboard
                          │ Tap "Activity AI"
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                  ACTIVITY AI SCREEN                             │
│                  (TensorFlow Lite Classifier)                   │
│                                                                 │
│  Anxiety Gap Demo                                          ✕    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                         │   │
│  │                      Stress                             │   │
│  │                   (or Cardio/Strength)                  │   │
│  │                                                         │   │
│  │              Stress: 78.5%                              │   │
│  │              Cardio: 15.2%                              │   │
│  │              Strength: 6.3%                             │   │
│  │                                                         │   │
│  │                  [Loading...]                           │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Simulate Watch Heart Rate: 120 BPM    [Use sim ✓]     │   │
│  │  ├────────●──────────────────────────┤                  │   │
│  │  60                                 180                  │   │
│  │  Drag slider HIGH to simulate Panic/Running             │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Simulate Movement [✓]  Amp: ├──●──┤  Freq: ├──●──┤     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  BPM Source:                                                    │
│  [Simulation] [Plugin] [Watch]                                  │
│                                                                 │
│  Watch BPM: 78 (or Watch not connected)                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 📍 Key Navigation Points

### 1. **Dashboard → Live Heart Rate**
- **Location**: Dashboard Home Tab → Quick Track section
- **Button**: "Live Heart Rate" (red heart icon)
- **Action**: Tap to navigate to real-time heart rate monitoring
- **Route**: `/home`

### 2. **Dashboard → Activity AI**
- **Location**: Dashboard Home Tab → Quick Track section
- **Button**: "Activity AI" (purple CPU icon)
- **Action**: Tap to open TensorFlow Lite activity classifier
- **Route**: `/activity-classifier`

### 3. **Live Heart Rate Features**
- ✅ Real-time BPM display
- ✅ Heart rate zone indicator (Resting, Light, Moderate, Hard, Maximum)
- ✅ HRV (Heart Rate Variability) in milliseconds
- ✅ IBI (Inter-Beat Intervals) values
- ✅ Statistics (Average, Max, Min)
- ✅ Connection status with Galaxy Watch
- ✅ Recent readings history (last 50)
- ✅ Buffer status indicator
- ✅ Save and Clear actions

### 4. **Activity AI Features (TensorFlow Lite)**
- ✅ Real-time activity classification (Stress, Cardio, Strength)
- ✅ Probability display for each class (0-100%)
- ✅ Simulated heart rate control (60-180 BPM slider)
- ✅ Simulated movement (synthetic accelerometer data)
- ✅ Multiple BPM sources:
  - **Simulation**: Manual slider control
  - **Plugin**: Heart BPM plugin (if available)
  - **Watch**: Real Galaxy Watch heart rate
- ✅ Adjustable amplitude and frequency for movement simulation
- ✅ 10-second sliding window (320 samples @ 32Hz)
- ✅ Live inference every ~1 second

### 5. **Data Flow**

#### Heart Rate Monitoring Flow:
```
Galaxy Watch (Kotlin)
    ↓
PhoneDataListener
    ↓
HeartRateDataManager (Buffer: 100 records)
    ↓
DatabaseService (SQLite: 10,000 records)
    ↓
DataSyncManager (Backend sync every 15 min)
```

#### Activity AI Flow:
```
Accelerometer Sensor (or Simulated)
    ↓
10-second Buffer (320 samples)
    ↓
TFLite Activity Classifier
    ↓
Activity Label + Probabilities
    ↓
UI Display (Stress/Cardio/Strength)
```

## 🎯 Quick Access Guide

### To Test Heart Rate Monitoring:

1. **Launch App**
   ```bash
   flutter run -d <phone_device_id>
   ```

2. **Navigate to Dashboard**
   - Wait for loading screen (3 seconds)
   - Tap "Login" or "Sign Up"
   - Complete authentication

3. **Access Heart Rate Monitor**
   - You'll land on Dashboard Home tab
   - Scroll to "Quick Track" section
   - Tap **"Live Heart Rate"** button

4. **Start Monitoring**
   - Ensure Galaxy Watch is connected
   - Watch will send heart rate data
   - Screen updates in real-time
   - Data is automatically saved

## 🔧 Available Routes

| Route | Screen | Description |
|-------|--------|-------------|
| `/` | LoadingScreen | Initial splash screen |
| `/welcome` | WelcomeScreen | Welcome with Sign Up/Login |
| `/login` | LoginScreen | User login |
| `/signup` | SignUpScreen | User registration |
| `/dashboard` | DashboardScreen | Main dashboard with tabs |
| `/home` | PhoneHomePage | **Live heart rate monitoring** |
| `/activity-classifier` | TrackerPage | Activity classifier |
| `/survey1` | SurveyScreen1 | Onboarding survey |
| `/survey2` | SurveyScreen2 | Onboarding survey |
| `/survey3` | SurveyScreen3 | Onboarding survey |
| `/onboarding1` | OnboardingScreen | Onboarding flow |

## 📊 Models Used in Heart Rate Screen

### HeartRateData
```dart
class HeartRateData {
  final int? bpm;              // Heart rate in BPM
  final DateTime timestamp;    // When measured
  final SensorStatus status;   // Sensor state
  final List<int> ibiValues;   // Inter-beat intervals
}
```

### TrackedData
```dart
class TrackedData {
  final int hr;                // Heart rate (BPM)
  final List<int> ibiValues;   // Inter-beat intervals (ms)
  final double hrv;            // Heart rate variability (RMSSD)
  final int spo2;              // Blood oxygen (%)
  final DateTime timestamp;
  final SensorStatus status;
}
```

### SensorError
```dart
class SensorError {
  final SensorErrorCode code;  // Error type
  final String message;        // Error description
  final dynamic details;       // Additional info
  final DateTime timestamp;
}
```

## 🧪 Testing Navigation

### Manual Testing
1. Run app: `flutter run`
2. Navigate through: Loading → Welcome → Login → Dashboard
3. Tap "Live Heart Rate" button
4. Verify screen displays correctly
5. Check watch connection status
6. Verify data updates in real-time

### Automated Testing
```bash
# Test models
flutter test test/models/

# Test all
flutter test
```

## 📝 Notes

- **Default Landing**: After login, users land on Dashboard Home tab
- **Quick Access**: "Live Heart Rate" is prominently displayed in Quick Track
- **Real-time Updates**: Screen refreshes automatically when watch sends data
- **Data Persistence**: All readings saved to SQLite database
- **Auto-sync**: Data syncs to backend every 15 minutes
- **Buffer Management**: Auto-flushes at 100 records, max 10,000 in database

---

**Ready to monitor!** 🚀

Tap "Live Heart Rate" on the Dashboard to start tracking your heart rate from your Galaxy Watch.
