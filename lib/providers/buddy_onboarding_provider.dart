import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/config/supabase_tables.dart';
import '../models/buddy_onboarding_state.dart';
import '../models/buddy_profile.dart';
import '../core/exceptions/buddy_exceptions.dart';
import '../services/buddy_offline_storage.dart';
import 'buddy_offline_storage_provider.dart';

Map<String, dynamic> buildBuddyUserProfileUpsertPayload({
  required String userId,
  String? nickname,
  List<String>? wellnessGoals,
  bool? notificationsEnabled,
}) {
  final payload = <String, dynamic>{
    'user_id': userId,
    'is_kids_mode': true,
    'survey_completed': true,
  };

  final trimmedNickname = nickname?.trim();
  if (trimmedNickname != null && trimmedNickname.isNotEmpty) {
    payload['nickname'] = trimmedNickname;
  }

  if (wellnessGoals != null && wellnessGoals.isNotEmpty) {
    payload['wellness_goals'] = wellnessGoals;
  }

  if (notificationsEnabled != null) {
    payload['notifications_enabled'] = notificationsEnabled;
  }

  return payload;
}

/// Notifier for managing Buddy onboarding flow state
///
/// This notifier handles the temporary state during the onboarding process,
/// validates user input, and persists data to Supabase when complete.
/// Includes error handling, retry logic, and offline support.
class BuddyOnboardingNotifier extends StateNotifier<BuddyOnboardingState> {
  final SupabaseClient? _supabase;
  final Uuid _uuid;
  final BuddyOfflineStorage? _offlineStorage;

  BuddyOnboardingNotifier({
    SupabaseClient? supabase,
    Uuid? uuid,
    BuddyOfflineStorage? offlineStorage,
  }) : _supabase = supabase,
       _uuid = uuid ?? const Uuid(),
       _offlineStorage = offlineStorage,
       super(const BuddyOnboardingState()) {
    _loadSavedState();
  }

  /// Get the Supabase client, initializing if needed
  SupabaseClient get _client {
    return _supabase ?? Supabase.instance.client;
  }

  /// Load saved onboarding state from offline storage
  Future<void> _loadSavedState() async {
    final storage = _offlineStorage;
    if (storage == null) return;

    try {
      final savedState = await storage.loadOnboardingState();
      if (savedState != null && !savedState.isComplete) {
        state = savedState;
      }
    } catch (e) {
      // Silently fail - we'll start with fresh state
    }
  }

  /// Save current state to offline storage
  Future<void> _saveStateLocally() async {
    final storage = _offlineStorage;
    if (storage == null) return;

    try {
      await storage.saveOnboardingState(state);
    } catch (e) {
      // Silently fail - offline storage is optional
    }
  }

  /// Select a color for the Buddy
  ///
  /// Updates the state with the selected color from the color selection screen.
  void selectColor(String color) {
    state = state.copyWith(selectedColor: color);
    _saveStateLocally();
  }

  /// Set the Buddy's name
  ///
  /// Updates the state with the user-chosen Buddy name.
  /// Should be called after validation passes.
  void setBuddyName(String name) {
    state = state.copyWith(buddyName: name);
    _saveStateLocally();
  }

  /// Set user's name (from step 2)
  void setUserName(String name) {
    state = state.copyWith(userName: name);
    _saveStateLocally();
  }

  /// Set user nickname (age not collected in whale onboarding)
  ///
  /// Updates the state with optional user nickname.
  void setUserNickname(String? nickname) {
    state = state.copyWith(userNickname: nickname);
    _saveStateLocally();
  }

  /// Set optional user nickname and age from the older onboarding API.
  void setUserInfo(String? nickname, int? age) {
    state = BuddyOnboardingState(
      currentStep: state.currentStep,
      userName: state.userName,
      selectedColor: state.selectedColor,
      buddyName: state.buddyName,
      userNickname: nickname,
      userAge: age,
      selectedGoals: state.selectedGoals,
      notificationsGranted: state.notificationsGranted,
      isComplete: state.isComplete,
    );
    _saveStateLocally();
  }

  /// Toggle wellness goal selection
  void toggleGoal(String goalId) {
    final currentGoals = List<String>.from(state.selectedGoals);
    if (currentGoals.contains(goalId)) {
      currentGoals.remove(goalId);
    } else {
      currentGoals.add(goalId);
    }
    state = state.copyWith(selectedGoals: currentGoals);
    _saveStateLocally();
  }

  /// Set notification permission
  void setNotificationPermission(bool granted) {
    state = state.copyWith(notificationsGranted: granted);
    _saveStateLocally();
  }

  /// Move to next step
  void nextStep() {
    if (state.currentStep < 7) {
      state = state.copyWith(currentStep: state.currentStep + 1);
      _saveStateLocally();
    }
  }

  /// Move to previous step
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
      _saveStateLocally();
    }
  }

  /// Validate the Buddy name
  ///
  /// Returns an error message if validation fails, or null if valid.
  ///
  /// Validation rules:
  /// - Name must not be empty
  /// - Name must be between 1 and 20 characters
  /// - Name should not contain special characters (optional)
  String? validateBuddyName(String name) {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return 'Please give your buddy a name!';
    }

    if (trimmedName.length > 20) {
      return 'That name is too long! Try something shorter.';
    }

    // Optional: Check for inappropriate characters
    final hasInvalidChars = RegExp(r'[<>{}[\]\\|`~]').hasMatch(trimmedName);
    if (hasInvalidChars) {
      return 'Please use only letters, numbers, and simple symbols.';
    }

    return null;
  }

  /// Check if network is available
  Future<bool> _isNetworkAvailable() async {
    try {
      // Try a simple query to check connectivity
      await _client.from(SupabaseTables.buddyProfiles).select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Complete the onboarding process with error handling and offline support
  ///
  /// Saves the Buddy profile and user information to Supabase.
  /// If network is unavailable, saves locally for later sync.
  /// Marks the onboarding as complete in the state.
  ///
  /// Throws BuddyException variants for different error scenarios.
  Future<void> completeOnboarding(
    String userId, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    // Validate required fields
    final missingFields = <String>[];
    if (state.buddyName == null || state.buddyName!.isEmpty) {
      missingFields.add('buddyName');
    }

    if (missingFields.isNotEmpty) {
      throw BuddyDataException(
        'Required fields missing: ${missingFields.join(", ")}',
        userFriendlyMessage: 'Please give your buddy a name before continuing!',
        missingFields: missingFields,
      );
    }

    final selectedColor = state.selectedColor ?? 'blue';
    final now = DateTime.now();
    final buddyProfile = BuddyProfile(
      id: _uuid.v4(),
      userId: userId,
      name: state.buddyName!,
      color: selectedColor,
      level: 1,
      xp: 0,
      unlockedColors: [selectedColor],
      createdAt: now,
      updatedAt: now,
    );

    // Try to save online with retry logic
    Exception? lastError;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Check network availability
        final hasNetwork = await _isNetworkAvailable();

        if (!hasNetwork) {
          // Save locally for offline mode
          await _saveOffline(buddyProfile);
          state = state.copyWith(isComplete: true);
          return;
        }

        // Save Buddy profile to Supabase
        await _saveBuddyProfile(buddyProfile);

        // Update user profile with all whale-themed onboarding data
        await _updateUserProfile(
          userId,
          state.userNickname ?? state.userName,
          wellnessGoals: state.selectedGoals,
          notificationsEnabled: state.notificationsGranted,
        );

        // Success! Clear offline storage and mark complete
        final storage = _offlineStorage;
        if (storage != null) {
          await storage.clearOnboardingState();
          await storage.clearPendingBuddyProfile();
        }
        state = state.copyWith(isComplete: true);
        return;
      } on PostgrestException catch (e) {
        lastError = BuddyNetworkException(
          'Database error: ${e.message}',
          userFriendlyMessage:
              'Oops! We couldn\'t save your Buddy. Let\'s try again!',
          originalError: e,
          canRetry: true,
        );

        // Wait before retry (except on last attempt)
        if (attempt < maxRetries - 1) {
          await Future.delayed(retryDelay);
        }
      } on AuthException catch (e) {
        // Auth errors shouldn't retry
        throw BuddyAuthException(
          'Authentication error: ${e.message}',
          userFriendlyMessage:
              'Oops! You need to be logged in to create your Buddy.',
          originalError: e,
        );
      } catch (e) {
        lastError = BuddyNetworkException(
          'Unexpected error: $e',
          userFriendlyMessage:
              'Oops! Something went wrong. Check your internet connection.',
          originalError: e,
          canRetry: true,
        );

        // Wait before retry (except on last attempt)
        if (attempt < maxRetries - 1) {
          await Future.delayed(retryDelay);
        }
      }
    }

    // All retries failed - try to save offline
    try {
      await _saveOffline(buddyProfile);
      state = state.copyWith(isComplete: true);
      throw BuddySaveException(
        'Failed to save online after $maxRetries attempts',
        userFriendlyMessage:
            'Your Buddy is saved! We\'ll sync when you\'re back online.',
        originalError: lastError,
        savedLocally: true,
      );
    } catch (e) {
      if (e is BuddySaveException) rethrow;

      // Offline save also failed
      throw BuddySaveException(
        'Failed to save both online and offline',
        userFriendlyMessage:
            'Oops! We couldn\'t save your Buddy. Please try again!',
        originalError: e,
        savedLocally: false,
      );
    }
  }

  /// Save buddy profile and state offline for later sync
  Future<void> _saveOffline(BuddyProfile profile) async {
    final storage = _offlineStorage;
    if (storage == null) {
      throw BuddySaveException(
        'Offline storage not available',
        userFriendlyMessage: 'Oops! We couldn\'t save your Buddy offline.',
        savedLocally: false,
      );
    }

    await storage.savePendingBuddyProfile(profile);
    await storage.saveOnboardingState(state);
  }

  /// Sync pending buddy profile from offline storage
  Future<void> syncPendingProfile({String? expectedUserId}) async {
    final storage = _offlineStorage;
    if (storage == null) return;

    final hasPending = await storage.hasPendingBuddyProfile();
    if (!hasPending) return;

    try {
      final pendingProfile = await storage.loadPendingBuddyProfile();
      if (pendingProfile == null) return;
      if (expectedUserId != null && pendingProfile.userId != expectedUserId) {
        return;
      }
      final savedState = await storage.loadOnboardingState();
      final onboardingState = savedState ?? state;

      // Try to save to Supabase
      await _saveBuddyProfile(pendingProfile);
      await _updateUserProfile(
        pendingProfile.userId,
        onboardingState.userNickname ?? onboardingState.userName,
        wellnessGoals: onboardingState.selectedGoals,
        notificationsEnabled: onboardingState.notificationsGranted,
      );

      // Success! Clear pending profile and replayed onboarding state.
      await storage.clearPendingBuddyProfile();
      await storage.clearOnboardingState();
    } catch (e) {
      // Sync failed - will retry later
      throw BuddyNetworkException(
        'Failed to sync pending profile: $e',
        userFriendlyMessage: 'We\'ll sync your Buddy when you\'re back online.',
        originalError: e,
      );
    }
  }

  /// Save Buddy profile to Supabase
  Future<void> _saveBuddyProfile(BuddyProfile profile) async {
    await _client
        .from(SupabaseTables.buddyProfiles)
        .upsert(profile.toJson(), onConflict: 'user_id');
  }

  /// Update user profile with nickname and kids mode flag
  Future<void> _updateUserProfile(
    String userId,
    String? nickname, {
    List<String>? wellnessGoals,
    bool? notificationsEnabled,
  }) async {
    await _client
        .from(SupabaseTables.userProfiles)
        .upsert(
          buildBuddyUserProfileUpsertPayload(
            userId: userId,
            nickname: nickname,
            wellnessGoals: wellnessGoals,
            notificationsEnabled: notificationsEnabled,
          ),
          onConflict: 'user_id',
        );
  }

  /// Reset the onboarding state
  ///
  /// Useful for testing or if user wants to restart the flow.
  Future<void> reset() async {
    state = const BuddyOnboardingState();
    final storage = _offlineStorage;
    if (storage != null) {
      await storage.clearOnboardingState();
      await storage.clearPendingBuddyProfile();
    }
  }
}

/// Provider for Buddy onboarding state management
final buddyOnboardingProvider =
    StateNotifierProvider<BuddyOnboardingNotifier, BuddyOnboardingState>((ref) {
      final offlineStorage = ref.watch(buddyOfflineStorageProvider);
      return BuddyOnboardingNotifier(offlineStorage: offlineStorage);
    });
