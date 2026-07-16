import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/core/exceptions/profile_exceptions.dart';
import 'package:flowfit/core/utils/logger.dart';
import 'package:flowfit/services/backend/sync_queue_service.dart';

/// Service for handling survey completion and profile creation.
///
/// This handler orchestrates the process of converting survey data into
/// a user profile, saving it locally, syncing to backend, and cleaning up
/// survey state.
///
/// Requirements: 5.1, 5.2, 5.3, 5.4
class SurveyCompletionHandler {
  final ProfileRepository _profileRepository;
  final SyncQueueService? _syncQueue;
  final Logger _logger = Logger('SurveyCompletionHandler');

  SurveyCompletionHandler({
    required ProfileRepository profileRepository,
    SyncQueueService? syncQueue,
  }) : _profileRepository = profileRepository,
       _syncQueue = syncQueue;

  /// Complete the survey and create user profile.
  ///
  /// This method performs the following steps:
  /// 1. Validate survey data is not empty
  /// 2. Convert survey data to UserProfile entity
  /// 3. Save profile to local storage (primary, works offline)
  /// 4. Attempt to sync profile to backend (best effort)
  ///
  /// Returns true if the profile was successfully saved locally.
  /// Backend sync failures are logged but don't prevent completion.
  ///
  /// Throws SurveyCompletionException if local save fails (critical error).
  ///
  /// Parameters:
  /// - [userId]: The user ID to associate with the profile
  /// - [surveyData]: The survey data collected from the onboarding flow
  ///
  /// Requirements:
  /// - 5.1: Map all survey fields to profile fields
  /// - 5.2: Include metadata (timestamp, version, source)
  /// - 5.3: Handle missing fields gracefully with default values
  /// - 5.4: Log errors and use safe defaults on migration failure
  Future<bool> completeSurvey(
    String userId,
    Map<String, dynamic> surveyData,
  ) async {
    _logger.info('Completing survey for user: $userId');

    try {
      // Step 1: Validate survey data
      if (surveyData.isEmpty) {
        _logger.error('Survey data is empty for user: $userId');
        throw SurveyCompletionException(
          'Survey data is empty. Cannot create profile.',
        );
      }

      _logger.debug('Survey data contains ${surveyData.length} fields');

      // Step 2: Convert survey data to profile (Requirement 5.1)
      UserProfile profile;
      try {
        profile = UserProfile.fromSurveyData(userId, surveyData);

        // This is a kids app (7-12), so always set is_kids_mode = true
        profile = profile.copyWith(isKidsMode: true);

        _logger.info(
          'Successfully converted survey data to profile (kids mode)',
        );
        // Requirement 5.2: Metadata is included in fromSurveyData
        // (createdAt, updatedAt timestamps)
      } catch (e, stackTrace) {
        // Requirement 5.4: Handle migration errors with safe defaults
        _logger.error(
          'Survey data migration failed, using defaults',
          error: e,
          stackTrace: stackTrace,
        );

        // Use defaults for any missing/invalid fields
        profile = UserProfile.withDefaults(userId);

        throw DataMigrationException(
          'Failed to convert survey data to profile',
          originalError: e,
          stackTrace: stackTrace,
        );
      }

      // Validate the created profile
      final validationError = profile.validate();
      if (validationError != null) {
        _logger.warning('Profile validation warning: $validationError');
        // Continue anyway - validation errors are warnings, not blockers
      }

      // Step 3: Save to local storage first (Requirement 5.3)
      // This is the critical operation - must succeed
      try {
        await _profileRepository.saveLocalProfile(profile);
        _logger.info('Successfully saved profile locally for user: $userId');
      } on LocalStorageException catch (e, stackTrace) {
        _logger.critical(
          'Critical: Failed to save profile locally',
          error: e,
          stackTrace: stackTrace,
        );
        throw SurveyCompletionException(
          'Failed to save profile locally',
          originalError: e,
          stackTrace: stackTrace,
        );
      }

      // Step 4: Attempt backend sync (best effort)
      // Failures here don't prevent completion
      try {
        await _profileRepository.saveBackendProfile(profile);
        _logger.info(
          'Successfully synced profile to backend for user: $userId',
        );

        // Mark as synced if backend save succeeded
        final syncedProfile = profile.copyWith(isSynced: true);
        await _profileRepository.saveLocalProfile(syncedProfile);
      } on BackendSyncException catch (e, stackTrace) {
        // Backend sync failed - add to sync queue for retry (Requirement 6.4)
        _logger.warning(
          'Backend sync failed during survey completion, queuing for retry',
          error: e,
          stackTrace: stackTrace,
        );

        if (_syncQueue != null) {
          try {
            await _syncQueue.enqueue(profile);
            _logger.debug('Added profile to sync queue');
          } catch (queueError, queueStackTrace) {
            _logger.error(
              'Failed to add profile to sync queue',
              error: queueError,
              stackTrace: queueStackTrace,
            );
          }
        }
        // Profile remains with isSynced: false, will be picked up by sync queue
      }

      _logger.info('Survey completion successful for user: $userId');
      return true;
    } on SurveyCompletionException {
      rethrow;
    } on DataMigrationException {
      rethrow;
    } catch (e, stackTrace) {
      // Unexpected error
      _logger.critical(
        'Unexpected error completing survey for user: $userId',
        error: e,
        stackTrace: stackTrace,
      );
      throw SurveyCompletionException(
        'Failed to complete survey',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if survey data is complete and ready for submission.
  ///
  /// Validates that all required fields are present in survey data.
  ///
  /// Parameters:
  /// - [surveyData]: The survey data to validate
  ///
  /// Returns true if all required fields are present.
  bool isSurveyComplete(Map<String, dynamic> surveyData) {
    // Check required fields
    return surveyData.containsKey('fullName') &&
        surveyData.containsKey('age') &&
        surveyData.containsKey('gender') &&
        surveyData.containsKey('height') &&
        surveyData.containsKey('weight') &&
        surveyData.containsKey('activityLevel') &&
        surveyData.containsKey('goals') &&
        surveyData.containsKey('dailyCalorieTarget');
  }
}
