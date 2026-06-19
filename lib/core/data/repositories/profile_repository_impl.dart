import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../exceptions/profile_exceptions.dart';
import '../../config/supabase_tables.dart';
import '../../utils/logger.dart';

/// Implementation of ProfileRepository with local and backend storage
///
/// Uses SharedPreferences for local storage and Supabase for backend.
/// Implements offline-first architecture with automatic sync.
class ProfileRepositoryImpl implements ProfileRepository {
  final SharedPreferences _prefs;
  final SupabaseClient _supabase;
  final Logger _logger = Logger('ProfileRepositoryImpl');

  // Stream controllers for sync status
  final Map<String, StreamController<SyncStatus>> _syncStatusControllers = {};

  // Local storage key constants
  static const String _profileKeyPrefix = 'user_profile_';
  static const String _syncQueueKeyPrefix = 'sync_queue_';

  ProfileRepositoryImpl({
    required SharedPreferences prefs,
    required SupabaseClient supabase,
  }) : _prefs = prefs,
       _supabase = supabase;

  // ============================================================================
  // Local Storage Operations
  // ============================================================================

  @override
  Future<UserProfile?> getLocalProfile(String userId) async {
    try {
      _logger.debug('Loading local profile for user: $userId');
      final key = '$_profileKeyPrefix$userId';
      _logger.debug('Looking for profile with key: $key');
      final jsonString = _prefs.getString(key);

      if (jsonString == null) {
        _logger.warning('No local profile found for user: $userId (key: $key)');
        // Debug: List all keys in SharedPreferences (development only)
        if (kDebugMode) {
          final allKeys = _prefs.getKeys();
          _logger.debug('All SharedPreferences keys: $allKeys');
        }
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final profile = UserProfile.fromJson(json);
      _logger.info('Successfully loaded local profile for user: $userId');
      return profile;
    } on FormatException catch (e, stackTrace) {
      _logger.error(
        'Invalid JSON format in local profile for user: $userId',
        error: e,
        stackTrace: stackTrace,
      );
      throw LocalStorageException(
        'Failed to parse local profile data',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error loading local profile for user: $userId',
        error: e,
        stackTrace: stackTrace,
      );
      throw LocalStorageException(
        'Failed to load local profile',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> saveLocalProfile(UserProfile profile) async {
    try {
      _logger.debug('Saving local profile for user: ${profile.userId}');

      // Validate profile before saving
      final validationError = profile.validate();
      if (validationError != null) {
        throw ValidationException(validationError);
      }

      final key = '$_profileKeyPrefix${profile.userId}';
      final jsonString = jsonEncode(profile.toJson());

      final success = await _prefs.setString(key, jsonString);

      if (!success) {
        throw LocalStorageException('SharedPreferences returned false');
      }

      _logger.info(
        'Successfully saved local profile for user: ${profile.userId}',
      );
    } on ValidationException {
      rethrow;
    } catch (e, stackTrace) {
      _logger.error(
        'Error saving local profile for user: ${profile.userId}',
        error: e,
        stackTrace: stackTrace,
      );
      throw LocalStorageException(
        'Failed to save profile to local storage',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteLocalProfile(String userId) async {
    try {
      _logger.debug('Deleting local profile for user: $userId');
      final profileKey = '$_profileKeyPrefix$userId';
      final syncQueueKey = '$_syncQueueKeyPrefix$userId';

      await _prefs.remove(profileKey);
      await _prefs.remove(syncQueueKey);

      _logger.info('Successfully deleted local profile for user: $userId');
    } catch (e, stackTrace) {
      _logger.error(
        'Error deleting local profile for user: $userId',
        error: e,
        stackTrace: stackTrace,
      );
      throw LocalStorageException(
        'Failed to delete local profile',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================================
  // Backend Operations
  // ============================================================================

  @override
  Future<UserProfile?> getBackendProfile(String userId) async {
    try {
      _logger.debug('Fetching backend profile for user: $userId');

      final response = await _supabase
          .from(SupabaseTables.userProfiles)
          .select()
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException(
                'Backend request timed out after 10 seconds',
              );
            },
          );

      if (response == null) {
        _logger.debug('No backend profile found for user: $userId');
        return null;
      }

      final profile = UserProfile.fromJson(response);
      _logger.info('Successfully fetched backend profile for user: $userId');
      return profile;
    } on TimeoutException catch (e, stackTrace) {
      _logger.warning(
        'Backend request timed out for user: $userId',
        error: e,
        stackTrace: stackTrace,
      );
      throw BackendSyncException(
        'Request timed out while fetching profile',
        originalError: e,
        stackTrace: stackTrace,
        isTimeout: true,
      );
    } on SocketException catch (e, stackTrace) {
      _logger.warning(
        'Network error fetching backend profile for user: $userId',
        error: e,
        stackTrace: stackTrace,
      );
      throw BackendSyncException(
        'Network error: ${e.message}',
        originalError: e,
        stackTrace: stackTrace,
        isNetworkError: true,
      );
    } on PostgrestException catch (e, stackTrace) {
      _logger.error(
        'Supabase error fetching backend profile for user: $userId',
        error: e,
        stackTrace: stackTrace,
      );
      throw BackendSyncException(
        'Backend error: ${e.message}',
        originalError: e,
        stackTrace: stackTrace,
      );
    } on FormatException catch (e, stackTrace) {
      _logger.error(
        'Invalid data format from backend for user: $userId',
        error: e,
        stackTrace: stackTrace,
      );
      throw BackendSyncException(
        'Invalid data format received from backend',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Unexpected error fetching backend profile for user: $userId',
        error: e,
        stackTrace: stackTrace,
      );
      throw BackendSyncException(
        'Failed to fetch profile from backend',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> saveBackendProfile(UserProfile profile) async {
    try {
      _logger.debug('Saving backend profile for user: ${profile.userId}');

      // Validate profile before saving
      final validationError = profile.validate();
      if (validationError != null) {
        throw ValidationException(validationError);
      }

      await _supabase
          .from(SupabaseTables.userProfiles)
          .upsert(profile.toSupabaseJson(), onConflict: 'user_id')
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException(
                'Backend request timed out after 10 seconds',
              );
            },
          );

      _logger.info(
        'Successfully saved backend profile for user: ${profile.userId}',
      );
    } on ValidationException {
      rethrow;
    } on TimeoutException catch (e, stackTrace) {
      _logger.warning(
        'Backend request timed out for user: ${profile.userId}',
        error: e,
        stackTrace: stackTrace,
      );
      throw BackendSyncException(
        'Request timed out while saving profile',
        originalError: e,
        stackTrace: stackTrace,
        isTimeout: true,
      );
    } on SocketException catch (e, stackTrace) {
      _logger.warning(
        'Network error saving backend profile for user: ${profile.userId}',
        error: e,
        stackTrace: stackTrace,
      );
      throw BackendSyncException(
        'Network error: ${e.message}',
        originalError: e,
        stackTrace: stackTrace,
        isNetworkError: true,
      );
    } on PostgrestException catch (e, stackTrace) {
      _logger.error(
        'Supabase error saving backend profile for user: ${profile.userId}',
        error: e,
        stackTrace: stackTrace,
      );
      throw BackendSyncException(
        'Backend error: ${e.message}',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Unexpected error saving backend profile for user: ${profile.userId}',
        error: e,
        stackTrace: stackTrace,
      );
      throw BackendSyncException(
        'Failed to save profile to backend',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================================
  // Sync Operations
  // ============================================================================

  @override
  Future<void> syncProfile(String userId) async {
    try {
      _logger.info('Starting profile sync for user: $userId');
      _emitSyncStatus(userId, SyncStatus.syncing);

      // Get local profile
      UserProfile? localProfile;
      try {
        localProfile = await getLocalProfile(userId);
      } on LocalStorageException catch (e, stackTrace) {
        _logger.error(
          'Failed to load local profile during sync',
          error: e,
          stackTrace: stackTrace,
        );
        // Continue with null local profile
      }

      // Get backend profile
      UserProfile? backendProfile;
      try {
        backendProfile = await getBackendProfile(userId);
      } on BackendSyncException catch (e, stackTrace) {
        _logger.warning(
          'Failed to fetch backend profile during sync',
          error: e,
          stackTrace: stackTrace,
        );
        // Continue with null backend profile
      }

      // Determine which profile to use based on last-write-wins
      if (localProfile == null && backendProfile == null) {
        // No profile exists anywhere
        _logger.debug('No profile found for user: $userId');
        _emitSyncStatus(userId, SyncStatus.synced);
        return;
      } else if (localProfile == null) {
        // Only backend profile exists - save to local
        _logger.info('Pulling backend profile to local for user: $userId');
        await saveLocalProfile(backendProfile!.copyWith(isSynced: true));
      } else if (backendProfile == null) {
        // Only local profile exists - save to backend
        _logger.info('Pushing local profile to backend for user: $userId');
        await saveBackendProfile(localProfile);
        await saveLocalProfile(localProfile.copyWith(isSynced: true));
      } else {
        // Both exist - resolve conflict using last-write-wins
        if (localProfile.updatedAt.isAfter(backendProfile.updatedAt)) {
          // Local is newer - push to backend
          _logger.info(
            'Local profile is newer, pushing to backend for user: $userId',
          );
          await saveBackendProfile(localProfile);
          await saveLocalProfile(localProfile.copyWith(isSynced: true));
        } else if (backendProfile.updatedAt.isAfter(localProfile.updatedAt)) {
          // Backend is newer - pull to local
          _logger.info(
            'Backend profile is newer, pulling to local for user: $userId',
          );
          await saveLocalProfile(backendProfile.copyWith(isSynced: true));
        } else {
          // Same timestamp - already synced
          _logger.debug('Profiles already in sync for user: $userId');
          if (!localProfile.isSynced) {
            await saveLocalProfile(localProfile.copyWith(isSynced: true));
          }
        }
      }

      // Clear sync queue
      await _prefs.remove('$_syncQueueKeyPrefix$userId');

      _emitSyncStatus(userId, SyncStatus.synced);
      _logger.info('Successfully completed profile sync for user: $userId');
    } catch (e, stackTrace) {
      _logger.error(
        'Error syncing profile for user: $userId',
        error: e,
        stackTrace: stackTrace,
      );
      _emitSyncStatus(userId, SyncStatus.syncFailed);
      throw ProfileException(
        'Failed to sync profile',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<bool> hasPendingSync(String userId) async {
    try {
      // Check if local profile exists and is not synced
      final localProfile = await getLocalProfile(userId);

      if (localProfile == null) {
        return false;
      }

      return !localProfile.isSynced;
    } catch (e) {
      // If error, assume no pending sync
      return false;
    }
  }

  @override
  Stream<SyncStatus> watchSyncStatus(String userId) {
    final controller = _getSyncStatusController(userId);

    // Emit initial status
    hasPendingSync(userId).then((hasPending) {
      if (!controller.isClosed) {
        controller.add(hasPending ? SyncStatus.pendingSync : SyncStatus.synced);
      }
    });

    return controller.stream;
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Get or create sync status controller for a user
  StreamController<SyncStatus> _getSyncStatusController(String userId) {
    if (!_syncStatusControllers.containsKey(userId)) {
      _syncStatusControllers[userId] = StreamController<SyncStatus>.broadcast();
    }
    return _syncStatusControllers[userId]!;
  }

  /// Emit sync status update
  void _emitSyncStatus(String userId, SyncStatus status) {
    final controller = _getSyncStatusController(userId);
    if (!controller.isClosed) {
      controller.add(status);
    }
  }

  /// Dispose resources
  void dispose() {
    for (final controller in _syncStatusControllers.values) {
      controller.close();
    }
    _syncStatusControllers.clear();
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    try {
      _logger.info('Checking if survey completed for user: $userId');
      final profile = await getLocalProfile(userId);
      final hasCompleted = profile != null;
      _logger.info(
        'Survey completion check result: $hasCompleted (profile: ${profile?.fullName})',
      );
      return hasCompleted;
    } catch (e, stackTrace) {
      _logger.error(
        'Error checking survey completion',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
