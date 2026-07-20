import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flowfit/core/config/supabase_tables.dart';
import 'package:flowfit/models/buddy_profile.dart';
import 'package:flowfit/providers/current_user_id_provider.dart';

typedef BuddyCustomizationSave =
    Future<void> Function(String userId, Map<String, dynamic> updates);

final buddyCustomizationCurrentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserIdProvider);
});

final buddyCustomizationSaveProvider = Provider<BuddyCustomizationSave>((ref) {
  return (userId, updates) async {
    await Supabase.instance.client
        .from(SupabaseTables.buddyProfiles)
        .update(updates)
        .eq('user_id', userId);
  };
});

/// Buddy Profile Provider
///
/// Fetches and manages Buddy profile data from Supabase
final buddyProfileProvider = FutureProvider.family<BuddyProfile?, String>((
  ref,
  userId,
) async {
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase
        .from(SupabaseTables.buddyProfiles)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return BuddyProfile.fromJson(response);
  } catch (e) {
    // Return null if buddy profile doesn't exist yet
    return null;
  }
});

/// Buddy Profile Notifier
///
/// Manages Buddy profile state with methods to update
class BuddyProfileNotifier extends StateNotifier<AsyncValue<BuddyProfile?>> {
  final String userId;

  BuddyProfileNotifier(this.userId) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  /// Load Buddy profile from Supabase
  Future<void> loadProfile() async {
    state = const AsyncValue.loading();

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from(SupabaseTables.buddyProfiles)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final profile = BuddyProfile.fromJson(response);
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update Buddy color
  Future<void> updateColor(String color) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from(SupabaseTables.buddyProfiles)
          .update({
            'color': color,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      // Update local state
      state = AsyncValue.data(
        currentProfile.copyWith(color: color, updatedAt: DateTime.now()),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Add XP and check for level up
  Future<void> addXP(int xpAmount) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    try {
      final newXP = currentProfile.xp + xpAmount;
      final newLevel = _calculateLevel(newXP);

      final supabase = Supabase.instance.client;
      await supabase
          .from(SupabaseTables.buddyProfiles)
          .update({
            'xp': newXP,
            'level': newLevel,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      // Update local state
      state = AsyncValue.data(
        currentProfile.copyWith(
          xp: newXP,
          level: newLevel,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Calculate level from XP
  int _calculateLevel(int totalXP) {
    if (totalXP <= 0) return 1;

    int level = 1;
    int xpAccumulated = 0;

    while (xpAccumulated + (level * 100) <= totalXP) {
      xpAccumulated += level * 100;
      level++;
    }

    return level;
  }
}

/// Buddy Profile Notifier Provider
final buddyProfileNotifierProvider =
    StateNotifierProvider.family<
      BuddyProfileNotifier,
      AsyncValue<BuddyProfile?>,
      String
    >((ref, userId) => BuddyProfileNotifier(userId));
