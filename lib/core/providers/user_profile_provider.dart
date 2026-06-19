import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_tables.dart';
import '../domain/entities/user_profile.dart';

/// User Profile Provider
///
/// Fetches and manages user profile data from Supabase
final userProfileProvider = FutureProvider.family<UserProfile?, String>((
  ref,
  userId,
) async {
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase
        .from(SupabaseTables.userProfiles)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return UserProfile.fromJson(response);
  } catch (e) {
    // Return null if user profile doesn't exist yet
    return null;
  }
});

/// User Profile Notifier
///
/// Manages user profile state with methods to update profile fields
class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final String userId;

  UserProfileNotifier(this.userId) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  /// Load user profile from Supabase
  Future<void> loadProfile() async {
    state = const AsyncValue.loading();

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from(SupabaseTables.userProfiles)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final profile = UserProfile.fromJson(response);
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update user nickname
  ///
  /// Updates the nickname field in the user profile.
  /// This is used during Buddy onboarding and can be updated later.
  Future<void> updateNickname(String? nickname) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from(SupabaseTables.userProfiles)
          .update({
            'nickname': nickname,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      // Update local state
      state = AsyncValue.data(
        currentProfile.copyWith(nickname: nickname, updatedAt: DateTime.now()),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update kids mode flag
  ///
  /// Updates the is_kids_mode field in the user profile.
  /// This determines whether the app shows kid-friendly features like Buddy.
  Future<void> updateKidsMode(bool isKidsMode) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from(SupabaseTables.userProfiles)
          .update({
            'is_kids_mode': isKidsMode,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      // Update local state
      state = AsyncValue.data(
        currentProfile.copyWith(
          isKidsMode: isKidsMode,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update nickname and kids mode together
  ///
  /// Convenience method to update both fields in a single database operation.
  /// This is commonly used during Buddy onboarding completion.
  Future<void> updateNicknameAndKidsMode({
    String? nickname,
    required bool isKidsMode,
  }) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    try {
      final updates = <String, dynamic>{
        'is_kids_mode': isKidsMode,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (nickname != null && nickname.isNotEmpty) {
        updates['nickname'] = nickname;
      }

      final supabase = Supabase.instance.client;
      await supabase
          .from(SupabaseTables.userProfiles)
          .update(updates)
          .eq('user_id', userId);

      // Update local state
      state = AsyncValue.data(
        currentProfile.copyWith(
          nickname: nickname ?? currentProfile.nickname,
          isKidsMode: isKidsMode,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update full user profile
  ///
  /// Updates multiple fields in the user profile at once.
  /// Only non-null values will be updated.
  Future<void> updateProfile({
    String? fullName,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? heightUnit,
    String? weightUnit,
    String? activityLevel,
    List<String>? goals,
    int? dailyCalorieTarget,
    int? dailyStepsTarget,
    int? dailyActiveMinutesTarget,
    double? dailyWaterTarget,
    String? profileImagePath,
    String? nickname,
    bool? isKidsMode,
  }) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (age != null) updates['age'] = age;
      if (gender != null) updates['gender'] = gender;
      if (height != null) updates['height'] = height;
      if (weight != null) updates['weight'] = weight;
      if (heightUnit != null) updates['height_unit'] = heightUnit;
      if (weightUnit != null) updates['weight_unit'] = weightUnit;
      if (activityLevel != null) updates['activity_level'] = activityLevel;
      if (goals != null) updates['goals'] = goals;
      if (dailyCalorieTarget != null) {
        updates['daily_calorie_target'] = dailyCalorieTarget;
      }
      if (dailyStepsTarget != null) {
        updates['daily_steps_target'] = dailyStepsTarget;
      }
      if (dailyActiveMinutesTarget != null) {
        updates['daily_active_minutes_target'] = dailyActiveMinutesTarget;
      }
      if (dailyWaterTarget != null) {
        updates['daily_water_target'] = dailyWaterTarget;
      }
      if (profileImagePath != null) {
        updates['profile_image_url'] = profileImagePath;
      }
      if (nickname != null) updates['nickname'] = nickname;
      if (isKidsMode != null) updates['is_kids_mode'] = isKidsMode;

      final supabase = Supabase.instance.client;
      await supabase
          .from(SupabaseTables.userProfiles)
          .update(updates)
          .eq('user_id', userId);

      // Update local state
      state = AsyncValue.data(
        currentProfile.copyWith(
          fullName: fullName ?? currentProfile.fullName,
          age: age ?? currentProfile.age,
          gender: gender ?? currentProfile.gender,
          height: height ?? currentProfile.height,
          weight: weight ?? currentProfile.weight,
          heightUnit: heightUnit ?? currentProfile.heightUnit,
          weightUnit: weightUnit ?? currentProfile.weightUnit,
          activityLevel: activityLevel ?? currentProfile.activityLevel,
          goals: goals ?? currentProfile.goals,
          dailyCalorieTarget:
              dailyCalorieTarget ?? currentProfile.dailyCalorieTarget,
          dailyStepsTarget: dailyStepsTarget ?? currentProfile.dailyStepsTarget,
          dailyActiveMinutesTarget:
              dailyActiveMinutesTarget ??
              currentProfile.dailyActiveMinutesTarget,
          dailyWaterTarget: dailyWaterTarget ?? currentProfile.dailyWaterTarget,
          profileImagePath: profileImagePath ?? currentProfile.profileImagePath,
          nickname: nickname ?? currentProfile.nickname,
          isKidsMode: isKidsMode ?? currentProfile.isKidsMode,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// User Profile Notifier Provider
final userProfileNotifierProvider =
    StateNotifierProvider.family<
      UserProfileNotifier,
      AsyncValue<UserProfile?>,
      String
    >((ref, userId) => UserProfileNotifier(userId));
