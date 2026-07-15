import 'package:flowfit/domain/entities/user_profile.dart';

/// Interface for user profile repository operations.
abstract class IProfileRepository {
  /// Creates a new user profile.
  ///
  /// [profile] - The user profile to create
  ///
  /// Returns the created [UserProfile] entity.
  /// Throws [AuthException] on failure.
  Future<UserProfile> createProfile(UserProfile profile);

  /// Updates an existing user profile.
  ///
  /// [profile] - The user profile with updated data
  ///
  /// Returns the updated [UserProfile] entity.
  /// Throws [AuthException] on failure.
  Future<UserProfile> updateProfile(UserProfile profile);

  /// Gets a user profile by user ID.
  ///
  /// [userId] - The ID of the user
  ///
  /// Returns a [UserProfile] entity if found, null otherwise.
  Future<UserProfile?> getProfile(String userId);

  /// Checks if a user has completed the survey.
  ///
  /// [userId] - The ID of the user
  ///
  /// Returns true if the user has completed the survey, false otherwise.
  Future<bool> hasCompletedSurvey(String userId);
}
