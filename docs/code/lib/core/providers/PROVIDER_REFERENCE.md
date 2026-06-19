# Provider Quick Reference

## Available Providers

### Data Sources

```dart
watchDataSourceProvider        // WatchBridge instance
supabaseDataSourceProvider     // SupabaseService instance
```

### Repositories

```dart
heartRateRepositoryProvider    // Heart rate data operations
activityRepositoryProvider     // Activity data (placeholder)
sleepRepositoryProvider        // Sleep data (placeholder)
```

### Services

```dart
heartRateServiceProvider       // Heart rate use cases
```

### State Providers

```dart
currentHeartRateProvider              // Stream<HeartRateData>
heartRateTrackingStateProvider        // bool (is tracking)
watchConnectionStateProvider          // Stream<bool> (is connected)
connectionControlProvider             // ConnectionState enum
userProfileProvider                   // FutureProvider<UserProfile?> (fetch profile)
userProfileNotifierProvider           // StateNotifier for profile updates
```

## Common Usage Patterns

### Read Once (No Rebuild)

```dart
final value = ref.read(providerName);
```

### Watch (Rebuild on Change)

```dart
final value = ref.watch(providerName);
```

### Listen (Side Effects)

```dart
ref.listen(providerName, (previous, next) {
  // Handle change
});
```

### Call Methods on Notifier

```dart
ref.read(heartRateTrackingStateProvider.notifier).startTracking();
ref.read(connectionControlProvider.notifier).connect();
```

### Handle Async Data

```dart
final asyncValue = ref.watch(currentHeartRateProvider);

asyncValue.when(
  data: (data) => Text('Data: $data'),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);

// Or use pattern matching
asyncValue.maybeWhen(
  data: (data) => Text('Data: $data'),
  orElse: () => Text('Loading...'),
);
```

## Widget Types

### ConsumerWidget

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(someProvider);
    return Text('$data');
  }
}
```

### ConsumerStatefulWidget

```dart
class MyScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(someProvider);
    return Text('$data');
  }
}
```

### Consumer (Widget)

```dart
Consumer(
  builder: (context, ref, child) {
    final data = ref.watch(someProvider);
    return Text('$data');
  },
)
```

## User Profile Provider Usage

### Fetch User Profile

```dart
// In a widget
final profileAsync = ref.watch(userProfileProvider(userId));

profileAsync.when(
  data: (profile) {
    if (profile == null) {
      return Text('No profile found');
    }
    return Text('Hello ${profile.nickname ?? profile.fullName}');
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### Update User Profile Fields

```dart
// Update nickname only
await ref.read(userProfileNotifierProvider(userId).notifier)
  .updateNickname('NewNickname');

// Update kids mode only
await ref.read(userProfileNotifierProvider(userId).notifier)
  .updateKidsMode(true);

// Update both nickname and kids mode
await ref.read(userProfileNotifierProvider(userId).notifier)
  .updateNicknameAndKidsMode(
    nickname: 'NewNickname',
    isKidsMode: true,
  );

// Update multiple profile fields
await ref.read(userProfileNotifierProvider(userId).notifier)
  .updateProfile(
    fullName: 'John Doe',
    age: 25,
    nickname: 'Johnny',
    isKidsMode: false,
  );
```

### Watch Profile State

```dart
// Watch profile state with loading/error handling
final profileState = ref.watch(userProfileNotifierProvider(userId));

profileState.when(
  data: (profile) => Text('Profile loaded'),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```
