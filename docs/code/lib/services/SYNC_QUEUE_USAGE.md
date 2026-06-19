# Sync Queue Service Usage Guide

## Overview

The `SyncQueueService` manages offline profile synchronization with automatic retry logic and exponential backoff. It ensures that profile updates made while offline are automatically synced when connectivity is restored.

## Features

- **Automatic Queueing**: Profile updates are automatically queued when backend sync fails
- **Connectivity Monitoring**: Checks connectivity every 30 seconds and processes queue when online
- **Exponential Backoff**: Implements retry logic with increasing delays (5s, 10s, 20s, 40s, 80s)
- **Persistent Queue**: Queue is persisted to local storage and survives app restarts
- **Max Retries**: Attempts up to 5 retries before discarding failed items
- **Real-time Status**: Provides stream of pending queue count for UI indicators

## Architecture

```
Profile Update
    ↓
ProfileNotifier.updateProfile()
    ↓
Save to Local Storage (immediate)
    ↓
Try Backend Sync
    ├─ Success → Mark as synced
    └─ Failure → Add to SyncQueue
                    ↓
            Connectivity Monitor (30s interval)
                    ↓
            Process Queue with Exponential Backoff
                    ↓
            Retry until success or max retries
```

## Integration

The sync queue is automatically integrated with the profile system through Riverpod providers:

```dart
// Sync queue service provider
final syncQueueServiceProvider = FutureProvider<SyncQueueService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final repository = await ref.watch(profileRepositoryProvider.future);
  return SyncQueueService(prefs: prefs, profileRepository: repository);
});

// Profile notifier automatically uses sync queue
final profileNotifierProvider = StateNotifierProvider.family<
  ProfileNotifier,
  AsyncValue<UserProfile?>,
  String
>((ref, userId) {
  final repository = ref.watch(profileRepositoryProvider).value;
  final syncQueue = ref.watch(syncQueueServiceProvider).valueOrNull;
  return ProfileNotifier(repository, userId, syncQueue: syncQueue);
});
```

## Usage Examples

### 1. Automatic Queueing (Default Behavior)

Profile updates automatically use the sync queue when backend sync fails:

```dart
// In your UI code
final profileNotifier = ref.read(profileNotifierProvider(userId).notifier);

// This automatically queues if offline
await profileNotifier.updateProfile(updatedProfile);
```

### 2. Check Pending Sync Count

Display sync status in UI:

```dart
class SyncStatusWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingSyncCountProvider);

    return pendingCount.when(
      data: (count) {
        if (count == 0) {
          return Icon(Icons.cloud_done, color: Colors.green);
        }
        return Badge(
          label: Text('$count'),
          child: Icon(Icons.cloud_upload, color: Colors.orange),
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (e, st) => Icon(Icons.cloud_off, color: Colors.red),
    );
  }
}
```

### 3. Manual Sync Trigger

Trigger sync manually (e.g., pull-to-refresh):

```dart
class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        // Trigger manual sync
        final hasConnectivity = await ref.read(manualSyncProvider.future);

        if (!hasConnectivity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No internet connection')),
          );
        } else {
          // Also refresh profile data
          await ref.read(profileNotifierProvider(userId).notifier).refresh();
        }
      },
      child: ProfileView(),
    );
  }
}
```

### 4. Watch Queue Status Stream

Monitor queue status in real-time:

```dart
class SyncMonitor extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(syncQueueServiceProvider).when(
      data: (syncQueue) {
        return StreamBuilder<int>(
          stream: syncQueue.queueStatus,
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Text('Pending syncs: $count');
          },
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (e, st) => Text('Error: $e'),
    );
  }
}
```

### 5. Check User-Specific Pending Sync

Check if a specific user has pending sync:

```dart
final syncQueue = await ref.read(syncQueueServiceProvider.future);
final hasPending = await syncQueue.hasPendingSync(userId);

if (hasPending) {
  // Show indicator that user has unsaved changes
}
```

## Retry Logic

The service implements exponential backoff with the following configuration:

- **Initial Backoff**: 5 seconds
- **Backoff Multiplier**: 2x
- **Max Retries**: 5 attempts
- **Retry Schedule**:
  - Attempt 1: Immediate
  - Attempt 2: After 5 seconds
  - Attempt 3: After 10 seconds
  - Attempt 4: After 20 seconds
  - Attempt 5: After 40 seconds
  - Attempt 6: After 80 seconds
  - After 6 attempts: Item is discarded

## Connectivity Monitoring

The service uses two timers for monitoring:

1. **Connectivity Timer** (30 seconds): Checks internet connectivity and processes queue
2. **Retry Timer** (10 seconds): Checks for items ready to retry based on backoff schedule

Connectivity is checked by attempting to lookup `google.com`. This is a simple but effective method that works across platforms.

## Storage

Queue items are persisted to SharedPreferences under the key `sync_queue`. Each item contains:

```dart
{
  "userId": "user-uuid",
  "profile": { /* UserProfile JSON */ },
  "queuedAt": "2024-01-01T12:00:00.000Z",
  "retryCount": 2,
  "nextRetryAt": "2024-01-01T12:00:20.000Z"
}
```

## Error Handling

The service is designed to be resilient:

- **Queue Load Errors**: Returns empty queue, logs error
- **Queue Save Errors**: Logs error but doesn't throw
- **Sync Errors**: Increments retry count and schedules next attempt
- **Max Retries**: Logs and discards item after 5 failed attempts

## Best Practices

1. **Don't manually enqueue**: Let ProfileNotifier handle queueing automatically
2. **Use providers**: Access sync queue through Riverpod providers, not directly
3. **Show status**: Display sync status to users so they know when data is pending
4. **Handle offline**: Design UI to work offline, sync happens in background
5. **Test offline**: Test your app in airplane mode to verify offline behavior

## Testing

### Test Offline Behavior

```dart
// 1. Turn off internet
// 2. Update profile
await profileNotifier.updateProfile(updatedProfile);

// 3. Verify queued
final syncQueue = await ref.read(syncQueueServiceProvider.future);
final count = await syncQueue.getPendingCount();
expect(count, 1);

// 4. Turn on internet
// 5. Wait for auto-sync (up to 30 seconds)
await Future.delayed(Duration(seconds: 35));

// 6. Verify synced
final newCount = await syncQueue.getPendingCount();
expect(newCount, 0);
```

### Test Manual Sync

```dart
// Queue some items while offline
await profileNotifier.updateProfile(profile1);
await profileNotifier.updateProfile(profile2);

// Manually trigger sync
final syncQueue = await ref.read(syncQueueServiceProvider.future);
await syncQueue.processPendingSync();

// Verify queue is empty
final count = await syncQueue.getPendingCount();
expect(count, 0);
```

## Troubleshooting

### Queue items not syncing

1. Check internet connectivity
2. Verify Supabase credentials are correct
3. Check console logs for sync errors
4. Verify RLS policies allow user to update their profile

### Queue growing too large

1. Check if backend is accessible
2. Verify user has permission to update profile
3. Check for network timeouts
4. Review console logs for repeated errors

### Items discarded after max retries

1. Check backend error logs
2. Verify data format is correct
3. Check for validation errors in backend
4. Review RLS policies

## Performance Considerations

- **Memory**: Queue is loaded into memory during processing, keep queue size reasonable
- **Storage**: Queue is persisted to SharedPreferences, which has size limits (~1MB on some platforms)
- **Network**: Connectivity checks use DNS lookup, which is lightweight
- **Battery**: Timers run in background, but are infrequent (10s and 30s intervals)

## Future Enhancements

Potential improvements for future versions:

1. **Configurable retry policy**: Allow customization of backoff and max retries
2. **Priority queue**: Prioritize certain updates over others
3. **Batch sync**: Sync multiple items in a single request
4. **Conflict resolution UI**: Let users resolve conflicts manually
5. **Sync analytics**: Track sync success rates and performance
6. **Background sync**: Use platform background tasks for more reliable sync
7. **Compression**: Compress queue data to save storage space
