import '../../../../core/domain/entities/user_profile.dart';
import '../entities/streak.dart';

/// Abstract repository interface for profile data access
///
/// This interface defines the contract for profile data operations.
/// Implementations can be mock repositories or real backend integrations.
abstract class ProfileRepository {
  /// Get user profile
  ///
  /// Returns the profile for the user with the given [userId], or null if not found
  Future<UserProfile?> getUserProfile(String userId);

  /// Update user profile
  ///
  /// Updates the user profile with the same ID as [profile]
  Future<void> updateUserProfile(UserProfile profile);

  /// Get user streaks
  ///
  /// Returns all streak data for the user with the given [userId]
  Future<List<Streak>> getUserStreaks(String userId);

  /// Update streak data
  ///
  /// Updates the streak with the same type as [streak]
  Future<void> updateStreak(Streak streak);
}
