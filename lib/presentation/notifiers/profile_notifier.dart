import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/domain/entities/user_profile.dart';
import '../../core/domain/repositories/profile_repository.dart';
import '../../core/exceptions/profile_exceptions.dart';
import '../../core/utils/logger.dart';
import '../../services/sync_queue_service.dart';

/// StateNotifier for managing user profile state.
///
/// Handles profile loading, updating, and field-level updates with
/// offline-first strategy (local storage first, then backend sync).
///
/// Requirements: 1.4, 1.5, 2.2, 2.3, 7.1, 7.2, 7.5
class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final ProfileRepository _repository;
  final SyncQueueService? _syncQueue;
  final String userId;
  final Logger _logger = Logger('ProfileNotifier');

  ProfileNotifier(this._repository, this.userId, {SyncQueueService? syncQueue})
    : _syncQueue = syncQueue,
      super(const AsyncValue.loading()) {
    loadProfile();
  }

  ProfileNotifier.initializing(this.userId)
    : _repository = _UnavailableProfileRepository(),
      _syncQueue = null,
      super(const AsyncValue.loading());

  ProfileNotifier.failed(this.userId, Object error, StackTrace stackTrace)
    : _repository = _UnavailableProfileRepository(),
      _syncQueue = null,
      super(AsyncValue.error(error, stackTrace));

  /// Load profile with local-first strategy.
  ///
  /// 1. Load from local storage first (fast, works offline)
  /// 2. Fetch from backend in background (sync latest data)
  /// 3. Update local cache if backend has newer data
  ///
  /// Requirement 1.4: Load user profile data from local storage if available
  /// Requirement 1.5: Use local data as source of truth until backend sync completes
  /// Requirement 7.1: Update all screens displaying profile data when it changes
  Future<void> loadProfile() async {
    _logger.info('Loading profile for user: $userId');
    state = const AsyncValue.loading();

    try {
      // Step 1: Load from local storage first (Requirement 1.4)
      UserProfile? localProfile;
      try {
        localProfile = await _repository.getLocalProfile(userId);
        if (localProfile != null) {
          _logger.debug('Loaded local profile for user: $userId');
          // Immediately show local data (Requirement 1.5)
          state = AsyncValue.data(localProfile);
        } else {
          _logger.debug('No local profile found for user: $userId');
        }
      } on LocalStorageException catch (e, stackTrace) {
        _logger.error(
          'Failed to load local profile',
          error: e,
          stackTrace: stackTrace,
        );
        // Continue to try backend fetch
      }

      // Step 2: Fetch from backend in background
      try {
        _logger.debug('Fetching backend profile for user: $userId');
        final backendProfile = await _repository.getBackendProfile(userId);
        if (backendProfile != null) {
          _logger.info('Fetched backend profile for user: $userId');
          // Step 3: Update local cache with backend data
          try {
            await _repository.saveLocalProfile(backendProfile);
          } on LocalStorageException catch (e, stackTrace) {
            _logger.warning(
              'Failed to cache backend profile locally',
              error: e,
              stackTrace: stackTrace,
            );
            // Continue anyway - we have the data
          }
          // Update state with backend data (Requirement 7.1)
          state = AsyncValue.data(backendProfile);
        } else if (localProfile == null) {
          // No profile exists anywhere
          _logger.debug('No profile exists for user: $userId');
          state = const AsyncValue.data(null);
        }
      } on BackendSyncException catch (e, stackTrace) {
        // Backend fetch failed, but we have local data
        if (localProfile != null) {
          // Keep showing local data, log backend error
          _logger.warning(
            'Backend fetch failed, using local data',
            error: e,
            stackTrace: stackTrace,
          );
          // State already set to local profile above
        } else {
          // No local data and backend failed
          _logger.error(
            'No local profile and backend fetch failed',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      }
    } catch (e, st) {
      // Complete failure - no local data and couldn't fetch
      _logger.error(
        'Failed to load profile for user: $userId',
        error: e,
        stackTrace: st,
      );
      state = AsyncValue.error(e, st);
    }
  }

  /// Update profile with local save + backend sync.
  ///
  /// 1. Save to local storage immediately (fast, works offline)
  /// 2. Update state with new profile
  /// 3. Attempt backend sync in background
  /// 4. Update sync status based on result
  ///
  /// Requirement 2.2: Update state to authenticated on success
  /// Requirement 2.3: Attempt to sync the change to backend
  /// Requirement 7.2: Immediately reflect changes in profile screen
  Future<void> updateProfile(UserProfile profile) async {
    _logger.info('Updating profile for user: ${profile.userId}');

    try {
      // Validate profile before saving
      final validationError = profile.validate();
      if (validationError != null) {
        _logger.warning('Profile validation failed: $validationError');
        throw ValidationException(validationError);
      }

      // Step 1: Save locally first (Requirement 2.2)
      final updatedProfile = profile.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      try {
        await _repository.saveLocalProfile(updatedProfile);
        _logger.debug('Saved profile locally for user: ${profile.userId}');
      } on LocalStorageException catch (e, stackTrace) {
        _logger.error(
          'Critical: Failed to save profile locally',
          error: e,
          stackTrace: stackTrace,
        );
        rethrow;
      }

      // Step 2: Update state immediately (Requirement 7.2)
      state = AsyncValue.data(updatedProfile);

      // Step 3: Sync to backend in background (Requirement 2.3)
      try {
        await _repository.saveBackendProfile(updatedProfile);
        _logger.info('Synced profile to backend for user: ${profile.userId}');

        // Step 4: Mark as synced
        final syncedProfile = updatedProfile.copyWith(isSynced: true);
        await _repository.saveLocalProfile(syncedProfile);
        state = AsyncValue.data(syncedProfile);
      } on BackendSyncException catch (e, stackTrace) {
        // Backend sync failed, but local save succeeded
        _logger.warning(
          'Backend sync failed, queuing for retry',
          error: e,
          stackTrace: stackTrace,
        );

        // Add to sync queue for retry (Requirement 6.4)
        if (_syncQueue != null) {
          try {
            await _syncQueue.enqueue(updatedProfile);
            _logger.debug('Added profile to sync queue');
          } catch (queueError, queueStackTrace) {
            _logger.error(
              'Failed to add profile to sync queue',
              error: queueError,
              stackTrace: queueStackTrace,
            );
          }
        }
        // State already set to updatedProfile with isSynced: false
      }
    } on ValidationException {
      rethrow;
    } catch (e, st) {
      // Local save failed - this is critical
      _logger.error(
        'Failed to update profile for user: ${profile.userId}',
        error: e,
        stackTrace: st,
      );
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update a single field in the profile.
  ///
  /// Convenience method for updating individual fields without
  /// needing to pass the entire profile object.
  ///
  /// Requirement 7.5: Notify all listeners via Riverpod state management
  Future<void> updateField(String field, dynamic value) async {
    final current = state.value;
    if (current == null) {
      // No profile to update
      return;
    }

    // Create updated profile with the new field value
    UserProfile updated;
    switch (field) {
      case 'fullName':
        updated = current.copyWith(fullName: value as String?);
        break;
      case 'age':
        updated = current.copyWith(age: value as int?);
        break;
      case 'gender':
        updated = current.copyWith(gender: value as String?);
        break;
      case 'height':
        updated = current.copyWith(height: value as double?);
        break;
      case 'weight':
        updated = current.copyWith(weight: value as double?);
        break;
      case 'heightUnit':
        updated = current.copyWith(heightUnit: value as String?);
        break;
      case 'weightUnit':
        updated = current.copyWith(weightUnit: value as String?);
        break;
      case 'activityLevel':
        updated = current.copyWith(activityLevel: value as String?);
        break;
      case 'goals':
        updated = current.copyWith(goals: value as List<String>?);
        break;
      case 'dailyCalorieTarget':
        updated = current.copyWith(dailyCalorieTarget: value as int?);
        break;
      case 'dailyStepsTarget':
        updated = current.copyWith(dailyStepsTarget: value as int?);
        break;
      case 'dailyActiveMinutesTarget':
        updated = current.copyWith(dailyActiveMinutesTarget: value as int?);
        break;
      case 'dailyWaterTarget':
        updated = current.copyWith(dailyWaterTarget: value as double?);
        break;
      case 'profileImagePath':
        updated = current.copyWith(profileImagePath: value as String?);
        break;
      default:
        // Unknown field, ignore
        return;
    }

    // Update the profile (Requirement 7.5)
    await updateProfile(updated);
  }

  /// Refresh profile from backend.
  ///
  /// Forces a fresh fetch from backend, useful for manual refresh.
  Future<void> refresh() async {
    await loadProfile();
  }

  /// Delete profile (for logout/account deletion).
  ///
  /// Removes profile from local storage and resets state.
  Future<void> deleteProfile() async {
    try {
      await _repository.deleteLocalProfile(userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class _UnavailableProfileRepository implements ProfileRepository {
  Never _throwUnavailable() {
    throw StateError('Profile repository is not available.');
  }

  @override
  Future<UserProfile?> getLocalProfile(String userId) async =>
      _throwUnavailable();

  @override
  Future<void> saveLocalProfile(UserProfile profile) async =>
      _throwUnavailable();

  @override
  Future<void> deleteLocalProfile(String userId) async => _throwUnavailable();

  @override
  Future<UserProfile?> getBackendProfile(String userId) async =>
      _throwUnavailable();

  @override
  Future<void> saveBackendProfile(UserProfile profile) async =>
      _throwUnavailable();

  @override
  Future<void> syncProfile(String userId) async => _throwUnavailable();

  @override
  Future<bool> hasPendingSync(String userId) async => _throwUnavailable();

  @override
  Stream<SyncStatus> watchSyncStatus(String userId) {
    return Stream.error(StateError('Profile repository is not available.'));
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async => _throwUnavailable();
}
