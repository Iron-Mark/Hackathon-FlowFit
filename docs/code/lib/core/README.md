# Core - Clean Architecture with Riverpod

This folder contains the core infrastructure for FlowFit's clean architecture implementation.

## Structure

```
core/
└── providers/              # Riverpod providers (dependency injection)
    ├── providers.dart      # Main export file - import this in your screens
    ├── data_sources/       # Data source providers (WatchBridge, Supabase)
    ├── repositories/       # Repository providers
    ├── services/           # Service/use case providers
    └── state/              # UI state providers
```

## Quick Start

### 1. Import providers in your screen
```dart
import 'package:flowfit/core/providers/providers.dart';
```

### 2. Use ConsumerWidget
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Your code here
  }
}
```

### 3. Watch providers
```dart
final heartRateAsync = ref.watch(currentHeartRateProvider);

heartRateAsync.when(
  data: (data) => Text('${data.bpm} BPM'),
  loading: () => CircularProgressIndicator(),
  error: (error, _) => Text('Error: $error'),
);
```

### 4. Call actions
```dart
ref.read(heartRateTrackingStateProvider.notifier).startTracking();
```

## Available Providers

See `PROVIDER_REFERENCE.md` for complete list and usage examples.

## Documentation

- **PROVIDER_REFERENCE.md** - Quick reference for all providers
- **docs/CLEAN_ARCHITECTURE_GUIDE.md** - Complete architecture guide
- **docs/ARCHITECTURE_DIAGRAM.md** - Visual diagrams
- **docs/MIGRATION_TO_CLEAN_ARCHITECTURE.md** - Migration guide

## Example

See `lib/screens/heart_rate_monitor_screen.dart` for a complete working example.
