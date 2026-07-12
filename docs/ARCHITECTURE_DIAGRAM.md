# FlowFit Architecture Diagram

## Complete System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                        │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Screens    │  │   Widgets    │  │  Navigation  │          │
│  │              │  │              │  │              │          │
│  │ - phone_home │  │ - Custom UI  │  │ - GoRouter   │          │
│  │ - dashboard  │  │ - Charts     │  │ - Routes     │          │
│  │ - wear_dash  │  │ - Cards      │  │              │          │
│  └──────┬───────┘  └──────┬───────┘  └──────────────┘          │
│         │                 │                                      │
│         └─────────────────┴──────────────────┐                  │
│                                               ▼                  │
│                                    ┌──────────────────┐          │
│                                    │   WidgetRef      │          │
│                                    │   (Riverpod)     │          │
│                                    └──────────────────┘          │
└─────────────────────────────────────────┬───────────────────────┘
                                          │
┌─────────────────────────────────────────▼───────────────────────┐
│                        PROVIDER LAYER                            │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    State Providers                       │   │
│  │  - currentHeartRateProvider (Stream<HeartRateData>)     │   │
│  │  - heartRateTrackingStateProvider (bool)                │   │
│  │  - watchConnectionStateProvider (Stream<bool>)          │   │
│  │  - connectionControlProvider (ConnectionState)          │   │
│  └──────────────────────────┬───────────────────────────────┘   │
│                             │                                    │
│  ┌──────────────────────────▼───────────────────────────────┐   │
│  │                  Service Providers                       │   │
│  │  - heartRateServiceProvider                             │   │
│  │    (Orchestrates business logic)                        │   │
│  └──────────────────────────┬───────────────────────────────┘   │
│                             │                                    │
│  ┌──────────────────────────▼───────────────────────────────┐   │
│  │                Repository Providers                      │   │
│  │  - heartRateRepositoryProvider                          │   │
│  │  - activityRepositoryProvider                           │   │
│  │  - sleepRepositoryProvider                              │   │
│  └──────────────────────────┬───────────────────────────────┘   │
│                             │                                    │
│  ┌──────────────────────────▼───────────────────────────────┐   │
│  │              Data Source Providers                       │   │
│  │  - watchDataSourceProvider (WatchBridge)                │   │
│  │  - supabaseDataSourceProvider (SupabaseService)         │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────┬───────────────────────┘
                                          │
┌─────────────────────────────────────────▼───────────────────────┐
│                         DOMAIN LAYER                             │
│                    (Business Logic - Pure Dart)                  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                      Entities                            │   │
│  │  - HeartRateData (bpm, ibiValues, timestamp, status)    │   │
│  │  - ActivityData (future)                                │   │
│  │  - SleepData (future)                                   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Repository Interfaces                       │   │
│  │  - HeartRateRepository                                  │   │
│  │    • Stream<HeartRateData> heartRateStream              │   │
│  │    • startTracking()                                    │   │
│  │    • stopTracking()                                     │   │
│  │    • saveHeartRateData()                                │   │
│  │    • getHistoricalData()                                │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────┬───────────────────────┘
                                          │
┌─────────────────────────────────────────▼───────────────────────┐
│                          DATA LAYER                              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           Repository Implementations                     │   │
│  │  - HeartRateRepositoryImpl                              │   │
│  │    (Implements HeartRateRepository interface)           │   │
│  └──────────────┬───────────────────────┬───────────────────┘   │
│                 │                       │                        │
│  ┌──────────────▼───────────┐  ┌───────▼──────────────────┐    │
│  │      WatchBridge         │  │   SupabaseService        │    │
│  │  (Platform Channel)      │  │   (Backend API)          │    │
│  │                          │  │                          │    │
│  │ - heartRateStream        │  │ - saveHeartRateData()    │    │
│  │ - startTracking()        │  │ - getHeartRateData()     │    │
│  │ - stopTracking()         │  │ - syncData()             │    │
│  └──────────────┬───────────┘  └───────┬──────────────────┘    │
└─────────────────┼───────────────────────┼───────────────────────┘
                  │                       │
┌─────────────────▼───────────┐  ┌───────▼──────────────────┐
│    NATIVE ANDROID LAYER     │  │    SUPABASE BACKEND      │
│                             │  │                          │
│  ┌──────────────────────┐   │  │  ┌──────────────────┐   │
│  │  MainActivity.kt     │   │  │  │  PostgreSQL DB   │   │
│  │  (Method Channel)    │   │  │  │  - heart_rate    │   │
│  └──────────┬───────────┘   │  │  │  - activities    │   │
│             │               │  │  │  - sleep_data    │   │
│  ┌──────────▼───────────┐   │  │  └──────────────────┘   │
│  │ HealthTrackingMgr.kt │   │  │                          │
│  │ (Samsung Health SDK) │   │  │  ┌──────────────────┐   │
│  │                      │   │  │  │  REST API        │   │
│  │ - connectService()   │   │  │  │  - Auth          │   │
│  │ - startTracking()    │   │  │  │  - Real-time     │   │
│  │ - onDataReceived()   │   │  │  └──────────────────┘   │
│  └──────────┬───────────┘   │  │                          │
│             │               │  └──────────────────────────┘
│  ┌──────────▼───────────┐   │
│  │ WatchToPhoneSyncMgr  │   │
│  │ (Wear Data Layer)    │   │
│  └──────────────────────┘   │
└─────────────────────────────┘
```

## Data Flow: Heart Rate Tracking

### 1. User Starts Tracking
```
User taps "Start" button
    ↓
Screen calls: ref.read(heartRateTrackingStateProvider.notifier).startTracking()
    ↓
HeartRateTrackingNotifier.startTracking()
    ↓
HeartRateRepository.startTracking()
    ↓
HeartRateRepositoryImpl.startTracking()
    ↓
WatchBridge.startHeartRateTracking()
    ↓
Platform Channel → MainActivity.kt
    ↓
HealthTrackingManager.startTracking()
    ↓
Samsung Health SDK starts measuring
```

### 2. Heart Rate Data Flows Back
```
Samsung Health SDK measures heart rate
    ↓
HealthTrackingManager.onDataReceived()
    ↓
MainActivity sends data via Platform Channel
    ↓
WatchBridge.heartRateStream emits data
    ↓
HeartRateRepositoryImpl.heartRateStream transforms to HeartRateData
    ↓
currentHeartRateProvider emits HeartRateData
    ↓
UI automatically rebuilds with new data
```

### 3. Data Persistence
```
HeartRateService listens to heartRateStream
    ↓
On new data: HeartRateRepository.saveHeartRateData()
    ↓
SupabaseService.saveHeartRateData()
    ↓
Data sent to Supabase backend
    ↓
Stored in PostgreSQL database
```

## Key Benefits of This Architecture

1. **Separation of Concerns**: Each layer has a single responsibility
2. **Testability**: Can mock any layer for testing
3. **Flexibility**: Easy to swap implementations (e.g., different backend)
4. **Maintainability**: Changes in one layer don't affect others
5. **Scalability**: Easy to add new features following the same pattern
6. **Type Safety**: Compile-time checks throughout the stack
7. **Reactive**: UI automatically updates when data changes

## File Organization

```
lib/
├── core/
│   └── providers/              # Riverpod providers (wiring)
│       ├── data_sources/       # WatchBridge, Supabase providers
│       ├── repositories/       # Repository providers
│       ├── services/           # Service providers
│       └── state/              # UI state providers
│
├── domain/                     # Business logic (pure Dart)
│   ├── entities/               # HeartRateData, etc.
│   └── repositories/           # Repository interfaces
│
├── data/                       # Implementation details
│   └── repositories/           # Repository implementations
│
├── services/                   # External services
│   ├── watch_bridge.dart       # Platform channel to Android
│   └── supabase_service.dart   # Backend API client
│
└── screens/                    # UI (ConsumerWidget)
    ├── phone_home.dart
    ├── dashboard_screen.dart
    └── phone/phone_heart_rate_screen.dart
```
