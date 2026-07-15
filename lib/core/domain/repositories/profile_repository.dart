import 'package:flowfit/core/domain/entities/user_profile.dart';

/// Sync status for profile data
enum SyncStatus {
  /// Profile is synced with backend
  synced,

  /// Profile is currently syncing
  syncing,

  /// Profile has pending changes to sync
  pendingSync,

  /// Sync failed, will retry
  syncFailed,

  /// No sync needed (offline mode)
  offline,
}

/// Repository interface for user profile operations
///
/// Provides methods for local storage, backend sync, and data consistency.
/// Implements offline-first architecture with local storage as primary source.
abstract class ProfileRepository {
  // ============================================================================
  // Local Storage Operations
  // ============================================================================

  /// Get user profile from local storage
  ///
  /// Returns null if no profile exists locally for the given [userId].
  /// This is the primary data source for offline-first architecture.
  Future<UserProfile?> getLocalProfile(String userId);

  /// Save user profile to local storage
  ///
  /// Saves [profile] to local storage immediately.
  /// Throws exception if save fails.
  Future<void> saveLocalProfile(UserProfile profile);

  /// Delete user profile from local storage
  ///
  /// Removes profile data for [userId] from local storage.
  /// Used for cleanup on logout or account deletion.
  Future<void> deleteLocalProfile(String userId);

  // ============================================================================
  // Backend Operations
  // ============================================================================

  /// Get user profile from backend (Supabase)
  ///
  /// Fetches profile data from Supabase for [userId].
  /// Returns null if no profile exists in backend.
  /// Throws exception on network errors or backend failures.
  Future<UserProfile?> getBackendProfile(String userId);

  /// Save user profile to backend (Supabase)
  ///
  /// Saves [profile] to Supabase using upsert logic.
  /// Creates new profile if it doesn't exist, updates if it does.
  /// Throws exception on network errors or backend failures.
  Future<void> saveBackendProfile(UserProfile profile);

  // ============================================================================
  // Sync Operations
  // ============================================================================

  /// Sync profile between local and backend storage
  ///
  /// Performs bidirectional sync with conflict resolution:
  /// 1. Fetches backend profile
  /// 2. Compares with local profile
  /// 3. Resolves conflicts using last-write-wins strategy
  /// 4. Updates both local and backend as needed
  ///
  /// Throws exception if sync fails.
  Future<void> syncProfile(String userId);

  /// Check if profile has pending sync operations
  ///
  /// Returns true if local profile has unsaved changes that need
  /// to be synced to backend (isSynced = false).
  Future<bool> hasPendingSync(String userId);

  /// Watch sync status for real-time updates
  ///
  /// Returns a stream that emits [SyncStatus] updates whenever
  /// the sync state changes for [userId].
  ///
  /// Useful for showing sync indicators in UI.
  Stream<SyncStatus> watchSyncStatus(String userId);

  /// Check if user has completed the onboarding survey
  ///
  /// Returns true if a profile exists locally for [userId],
  /// indicating the user has completed onboarding.
  Future<bool> hasCompletedSurvey(String userId);
}
