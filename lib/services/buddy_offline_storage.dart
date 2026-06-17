import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/buddy_onboarding_state.dart';
import '../models/buddy_profile.dart';

/// Service for offline storage of Buddy onboarding data
///
/// Provides local persistence for onboarding state and buddy profiles
/// to support offline mode and data recovery.
class BuddyOfflineStorage {
  static const String _onboardingStateKey = 'buddy_onboarding_state';
  static const String _pendingBuddyProfileKey = 'pending_buddy_profile';
  static const String _onboardingTimestampKey = 'buddy_onboarding_timestamp';

  final SharedPreferences _prefs;

  BuddyOfflineStorage(this._prefs);

  /// Save onboarding state locally
  Future<void> saveOnboardingState(BuddyOnboardingState state) async {
    final stateJson = {
      'currentStep': state.currentStep,
      'userName': state.userName,
      'selectedColor': state.selectedColor,
      'buddyName': state.buddyName,
      'userNickname': state.userNickname,
      'userAge': state.userAge,
      'selectedGoals': state.selectedGoals,
      'notificationsGranted': state.notificationsGranted,
      'isComplete': state.isComplete,
    };

    await _prefs.setString(_onboardingStateKey, jsonEncode(stateJson));
    await _prefs.setInt(
      _onboardingTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Load onboarding state from local storage
  Future<BuddyOnboardingState?> loadOnboardingState() async {
    final stateString = _prefs.getString(_onboardingStateKey);
    if (stateString == null) return null;

    // Check if data is stale (older than 24 hours)
    final timestamp = _prefs.getInt(_onboardingTimestampKey);
    if (timestamp != null) {
      final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(savedTime);
      if (age.inHours > 24 && !await hasPendingBuddyProfile()) {
        // Data is stale, clear it
        await clearOnboardingState();
        return null;
      }
    }

    try {
      final stateJson = jsonDecode(stateString) as Map<String, dynamic>;
      return BuddyOnboardingState(
        currentStep: stateJson['currentStep'] as int? ?? 0,
        userName: stateJson['userName'] as String?,
        selectedColor: stateJson['selectedColor'] as String?,
        buddyName: stateJson['buddyName'] as String?,
        userNickname: stateJson['userNickname'] as String?,
        userAge: stateJson['userAge'] as int?,
        selectedGoals:
            (stateJson['selectedGoals'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        notificationsGranted:
            stateJson['notificationsGranted'] as bool? ?? false,
        isComplete: stateJson['isComplete'] as bool? ?? false,
      );
    } catch (e) {
      // If parsing fails, clear corrupted data
      await clearOnboardingState();
      return null;
    }
  }

  /// Clear onboarding state from local storage
  Future<void> clearOnboardingState() async {
    await _prefs.remove(_onboardingStateKey);
    await _prefs.remove(_onboardingTimestampKey);
  }

  /// Save pending buddy profile for later sync
  Future<void> savePendingBuddyProfile(BuddyProfile profile) async {
    await _prefs.setString(
      _pendingBuddyProfileKey,
      jsonEncode(profile.toJson()),
    );
  }

  /// Load pending buddy profile
  Future<BuddyProfile?> loadPendingBuddyProfile() async {
    final profileString = _prefs.getString(_pendingBuddyProfileKey);
    if (profileString == null) return null;

    try {
      final profileJson = jsonDecode(profileString) as Map<String, dynamic>;
      return BuddyProfile.fromJson(profileJson);
    } catch (e) {
      // If parsing fails, clear corrupted data
      await clearPendingBuddyProfile();
      return null;
    }
  }

  /// Clear pending buddy profile
  Future<void> clearPendingBuddyProfile() async {
    await _prefs.remove(_pendingBuddyProfileKey);
  }

  /// Check if there's a pending buddy profile to sync
  Future<bool> hasPendingBuddyProfile() async {
    return _prefs.containsKey(_pendingBuddyProfileKey);
  }
}
