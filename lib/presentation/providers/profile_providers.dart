import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/domain/entities/user_profile.dart';
import '../../core/domain/repositories/profile_repository.dart';
import '../../core/data/repositories/profile_repository_impl.dart';
import '../../services/sync_queue_service.dart';
import '../../services/survey_completion_handler.dart';
import '../notifiers/profile_notifier.dart';

/// Provider for SharedPreferences instance.
///
/// Returns a Future that resolves to the SharedPreferences instance.
/// Used for local storage operations in profile repository.
///
/// Requirement 7.4: Use single source of truth
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

/// Provider for Supabase client instance.
///
/// Returns the singleton Supabase client for backend operations.
///
/// Requirement 7.4: Use single source of truth
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for profile repository instance.
///
/// Creates an instance of ProfileRepositoryImpl with SharedPreferences and Supabase.
/// This implements the offline-first architecture with local storage as primary source.
///
/// Dependencies:
/// - SharedPreferences for local storage
/// - SupabaseClient for backend sync
///
/// Requirement 7.4: Use single source of truth
/// Requirement 7.5: Notify all listeners via Riverpod state management
final profileRepositoryProvider = FutureProvider<ProfileRepository>((
  ref,
) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final supabase = ref.watch(supabaseClientProvider);

  return ProfileRepositoryImpl(prefs: prefs, supabase: supabase);
});

/// Provider for sync queue service instance.
///
/// Creates an instance of SyncQueueService for managing offline sync queue.
/// Handles automatic syncing when connectivity is restored and retry logic.
///
/// Dependencies:
/// - SharedPreferences for queue persistence
/// - ProfileRepository for sync operations
///
/// Requirement 6.2: Automatically sync local changes to backend when online
/// Requirement 6.3: Resolve conflicts using last-write-wins strategy
/// Requirement 6.4: Queue changes for sync when offline
final syncQueueServiceProvider = FutureProvider<SyncQueueService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final repository = await ref.watch(profileRepositoryProvider.future);

  final service = SyncQueueService(prefs: prefs, profileRepository: repository);

  // Cleanup on dispose
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for survey completion handler instance.
///
/// Creates an instance of SurveyCompletionHandler for handling survey completion
/// and profile creation. Orchestrates the process of converting survey data into
/// a user profile, saving it locally, and syncing to backend.
///
/// Dependencies:
/// - ProfileRepository for profile operations
/// - SyncQueueService for offline sync queue
///
/// Requirements:
/// - 5.1: Map all survey fields to profile fields
/// - 5.2: Include metadata (timestamp, version, source)
/// - 5.3: Handle missing fields gracefully with default values
/// - 5.4: Log errors and use safe defaults on migration failure
final surveyCompletionHandlerProvider = FutureProvider<SurveyCompletionHandler>(
  (ref) async {
    final repository = await ref.watch(profileRepositoryProvider.future);
    final syncQueue = await ref.watch(syncQueueServiceProvider.future);

    return SurveyCompletionHandler(
      profileRepository: repository,
      syncQueue: syncQueue,
    );
  },
);

/// Provider for checking if there are pending sync items.
///
/// Returns the count of items waiting to be synced.
/// Useful for showing sync status indicators in UI.
///
/// Requirement 6.5: Show sync status indicator when queue has pending changes
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final syncQueue = await ref.watch(syncQueueServiceProvider.future);
  return await syncQueue.getPendingCount();
});

/// Provider for manual sync trigger.
///
/// Call this to manually trigger sync from UI (e.g., pull-to-refresh).
/// Returns true if sync was attempted (has connectivity), false otherwise.
///
/// Usage:
/// ```dart
/// final result = await ref.read(manualSyncProvider.future);
/// if (result) {
///   // Sync attempted
/// } else {
///   // No connectivity
/// }
/// ```
final manualSyncProvider = FutureProvider.autoDispose<bool>((ref) async {
  final syncQueue = await ref.watch(syncQueueServiceProvider.future);
  return await syncQueue.manualSync();
});

/// StateNotifier provider family for user-specific profile state.
///
/// Manages user profile state with offline-first strategy:
/// - Loads from local storage first (fast, works offline)
/// - Syncs with backend in background
/// - Handles updates with local save + backend sync
///
/// This is a family provider, allowing multiple user profiles to be managed
/// independently by userId.
///
/// Usage:
/// ```dart
/// final profileAsync = ref.watch(profileNotifierProvider(userId));
/// ```
///
/// Requirements:
/// - 1.4: Load user profile data from local storage if available
/// - 1.5: Use local data as source of truth until backend sync completes
/// - 2.2: Update local storage on profile changes
/// - 2.3: Attempt backend sync after local save
/// - 7.1: Update all screens displaying profile data
/// - 7.2: Immediately reflect changes in profile screen
/// - 7.5: Notify all listeners via Riverpod state management
final profileNotifierProvider =
    StateNotifierProvider.family<
      ProfileNotifier,
      AsyncValue<UserProfile?>,
      String
    >((ref, userId) {
      // Watch the repository and sync queue providers
      final repositoryAsync = ref.watch(profileRepositoryProvider);
      final syncQueueAsync = ref.watch(syncQueueServiceProvider);

      // Handle the async initialization
      return repositoryAsync.when(
        data: (repository) {
          // Repository loaded successfully
          // Try to get sync queue if available
          final syncQueue = syncQueueAsync.valueOrNull;
          return ProfileNotifier(repository, userId, syncQueue: syncQueue);
        },
        loading: () {
          return ProfileNotifier.initializing(userId);
        },
        error: (error, stack) {
          return ProfileNotifier.failed(userId, error, stack);
        },
      );
    });

/// Provider for sync status monitoring.
///
/// Watches the sync status stream for a specific user and provides
/// real-time updates about profile synchronization state.
///
/// Returns a stream of SyncStatus values:
/// - synced: Profile is up-to-date with backend
/// - syncing: Sync operation in progress
/// - pendingSync: Local changes waiting to sync
/// - syncFailed: Sync attempt failed, will retry
/// - offline: No sync needed (offline mode)
///
/// Usage:
/// ```dart
/// final syncStatus = ref.watch(syncStatusProvider(userId));
/// syncStatus.when(
///   data: (status) => Text('Status: $status'),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error: $e'),
/// );
/// ```
///
/// Requirement 7.5: Notify all listeners via Riverpod state management
final syncStatusProvider = StreamProvider.family<SyncStatus, String>((
  ref,
  userId,
) {
  final repositoryAsync = ref.watch(profileRepositoryProvider);

  return repositoryAsync.when(
    data: (repository) {
      // Repository loaded - watch sync status stream
      return repository.watchSyncStatus(userId);
    },
    loading: () {
      // Repository loading - emit offline status
      return Stream.value(SyncStatus.offline);
    },
    error: (error, stack) {
      // Repository error - emit offline status
      return Stream.value(SyncStatus.offline);
    },
  );
});
