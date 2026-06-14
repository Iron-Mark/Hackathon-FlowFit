import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/exceptions/auth_exceptions.dart' as domain_exceptions;
import '../../domain/repositories/i_profile_repository.dart';
import '../models/user_profile_model.dart';
import '../../core/utils/error_logger.dart';

/// Implementation of IProfileRepository that uses Supabase as the backend.
/// Handles profile CRUD operations with retry logic for reliability.
class ProfileRepository implements IProfileRepository {
  final SupabaseClient _client;
  static const String _tableName = 'user_profiles';
  static const int _maxRetries = 3;

  ProfileRepository(this._client);

  @override
  Future<UserProfile> createProfile(UserProfile profile) async {
    return _executeWithRetry(() async {
      try {
        // Convert domain entity to data model
        final model = UserProfileModel.fromDomain(profile);

        // Upsert so survey completion can repair/finish partial recovered rows.
        final response = await _client
            .from(_tableName)
            .upsert(model.toJson(), onConflict: 'user_id')
            .select()
            .single();

        // Convert response back to domain entity
        final createdModel = UserProfileModel.fromJson(response);
        return createdModel.toDomain();
      } on PostgrestException catch (e, stackTrace) {
        ErrorLogger.logError('ProfileRepository.createProfile', e, stackTrace);
        throw _mapPostgrestException(e);
      } catch (e, stackTrace) {
        ErrorLogger.logError('ProfileRepository.createProfile', e, stackTrace);
        throw domain_exceptions.UnknownException();
      }
    });
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    return _executeWithRetry(() async {
      try {
        // Convert domain entity to data model
        final model = UserProfileModel.fromDomain(profile);

        // Update in Supabase
        final response = await _client
            .from(_tableName)
            .update(model.toJson())
            .eq('user_id', profile.userId)
            .select()
            .single();

        // Convert response back to domain entity
        final updatedModel = UserProfileModel.fromJson(response);
        return updatedModel.toDomain();
      } on PostgrestException catch (e, stackTrace) {
        ErrorLogger.logError('ProfileRepository.updateProfile', e, stackTrace);
        throw _mapPostgrestException(e);
      } catch (e, stackTrace) {
        ErrorLogger.logError('ProfileRepository.updateProfile', e, stackTrace);
        throw domain_exceptions.UnknownException();
      }
    });
  }

  @override
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final model = UserProfileModel.fromJson(response);
      return model.toDomain();
    } on PostgrestException catch (e, stackTrace) {
      ErrorLogger.logError('ProfileRepository.getProfile', e, stackTrace);
      throw _mapPostgrestException(e);
    } catch (e, stackTrace) {
      ErrorLogger.logError('ProfileRepository.getProfile', e, stackTrace);
      throw domain_exceptions.UnknownException();
    }
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('survey_completed')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return false;
      }

      return response['survey_completed'] as bool;
    } on PostgrestException catch (e, stackTrace) {
      ErrorLogger.logError(
        'ProfileRepository.hasCompletedSurvey',
        e,
        stackTrace,
      );
      throw _mapPostgrestException(e);
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'ProfileRepository.hasCompletedSurvey',
        e,
        stackTrace,
      );
      throw domain_exceptions.UnknownException();
    }
  }

  /// Executes an operation with retry logic.
  /// Retries up to [_maxRetries] times on failure.
  ///
  /// This method is marked as @visibleForTesting to allow unit tests
  /// to verify retry behavior.
  @visibleForTesting
  Future<T> executeWithRetryForTest<T>(Future<T> Function() operation) async {
    return _executeWithRetry(operation);
  }

  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < _maxRetries) {
      try {
        return await operation();
      } catch (e) {
        lastException = e as Exception;
        attempts++;

        // Don't retry on validation errors or auth errors
        if (e is domain_exceptions.AuthException &&
            e is! domain_exceptions.NetworkException &&
            e is! domain_exceptions.UnknownException) {
          rethrow;
        }

        // If we've exhausted retries, throw the last exception
        if (attempts >= _maxRetries) {
          ErrorLogger.logWarning(
            'ProfileRepository._executeWithRetry',
            'Max retries ($attempts) reached, giving up',
          );
          rethrow;
        }

        // Log retry attempt
        ErrorLogger.logInfo(
          'ProfileRepository._executeWithRetry',
          'Retry attempt $attempts of $_maxRetries',
        );

        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(milliseconds: 100 * attempts));
      }
    }

    // This should never be reached, but just in case
    throw lastException ?? domain_exceptions.UnknownException();
  }

  /// Maps Supabase PostgrestException to domain-specific exceptions.
  domain_exceptions.AuthException _mapPostgrestException(PostgrestException e) {
    // Check for network-related errors
    if (e.message.toLowerCase().contains('network') ||
        e.message.toLowerCase().contains('connection') ||
        e.message.toLowerCase().contains('timeout')) {
      return domain_exceptions.NetworkException();
    }

    // For other errors, return a generic exception
    // Don't expose technical details to the user
    return domain_exceptions.UnknownException();
  }
}
