import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../../core/utils/height_measurements.dart';
import '../../domain/exceptions/auth_exceptions.dart';

/// State class for survey data and progress.
class SurveyState {
  final Map<String, dynamic> surveyData;
  final int currentStep;
  final bool isLoading;
  final String? errorMessage;

  const SurveyState({
    required this.surveyData,
    required this.currentStep,
    required this.isLoading,
    this.errorMessage,
  });

  /// Factory constructor for initial state
  factory SurveyState.initial() =>
      const SurveyState(surveyData: {}, currentStep: 0, isLoading: false);

  /// Creates a copy of this state with the given fields replaced
  SurveyState copyWith({
    Map<String, dynamic>? surveyData,
    int? currentStep,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SurveyState(
      surveyData: surveyData ?? this.surveyData,
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurveyState &&
          runtimeType == other.runtimeType &&
          _mapEquals(surveyData, other.surveyData) &&
          currentStep == other.currentStep &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      surveyData.hashCode ^
      currentStep.hashCode ^
      isLoading.hashCode ^
      errorMessage.hashCode;

  bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (var key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

/// StateNotifier for managing survey data and submission.
///
/// Handles survey data collection, validation, local persistence,
/// and submission to the profile repository.
///
/// Requirements: 3.2, 3.3, 3.4, 3.5, 4.1, 4.3
class SurveyNotifier extends StateNotifier<SurveyState> {
  final IProfileRepository _profileRepository;
  static const String _storageKey = 'survey_data';
  static const int _maxRetries = 3;

  SurveyNotifier(this._profileRepository) : super(SurveyState.initial()) {
    _loadSurveyData();
  }

  /// Load survey data from local storage on initialization.
  ///
  /// Requirement 3.2: Preserve partial survey data locally
  Future<void> _loadSurveyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final data = json.decode(jsonString) as Map<String, dynamic>;
        state = state.copyWith(surveyData: data);
      }
    } catch (e) {
      // If loading fails, start with empty data
      state = SurveyState.initial();
    }
  }

  /// Updates survey data with a new key-value pair.
  ///
  /// Persists the updated data to local storage.
  ///
  /// Requirement 3.2: Preserve partial survey data locally
  Future<void> updateSurveyData(String key, dynamic value) async {
    final updatedData = Map<String, dynamic>.from(state.surveyData);
    updatedData[key] = value;

    state = state.copyWith(surveyData: updatedData, clearError: true);

    // Persist to local storage
    await _persistSurveyData();
  }

  /// Persists current survey data to local storage.
  Future<void> _persistSurveyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(state.surveyData);
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      // Silently fail - data is still in memory
    }
  }

  /// Validates basic info step data.
  ///
  /// Requirement 3.3: Validate all required fields before proceeding
  String? validateBasicInfo() {
    final fullName = state.surveyData['fullName'] as String?;
    final age = state.surveyData['age'] as int?;
    final gender = state.surveyData['gender'] as String?;

    if (fullName == null || fullName.trim().isEmpty) {
      return 'Full name is required';
    }

    if (age == null) {
      return 'Age is required';
    }

    if (age < 7 || age > 120) {
      return 'Age must be between 7 and 120';
    }

    if (gender == null || gender.isEmpty) {
      return 'Gender is required';
    }

    return null; // Valid
  }

  /// Validates body measurements step data.
  ///
  /// Requirement 3.4: Validate numeric inputs are within reasonable ranges
  String? validateBodyMeasurements() {
    final weight = (state.surveyData['weight'] as num?)?.toDouble();
    final height = (state.surveyData['height'] as num?)?.toDouble();
    final weightUnit = state.surveyData['weightUnit'] as String? ?? 'kg';
    final heightUnit = state.surveyData['heightUnit'] as String? ?? 'cm';

    if (weight == null) {
      return 'Weight is required';
    }

    final maxWeight = weightUnit == 'lbs' ? 1100.0 : 500.0;
    if (weight <= 0 || weight >= maxWeight) {
      return 'Weight must be between 0 and ${maxWeight.toStringAsFixed(0)} $weightUnit';
    }

    if (height == null) {
      return 'Height is required';
    }

    if (heightUnit == 'ft') {
      final totalInches = feetInchesFromHeightValue(
        height,
        rawHeightInput: state.surveyData['heightInput'] as String?,
      ).totalInches;
      if (totalInches <= 0 || totalInches >= 120) {
        return 'Height must be between 0 and 10 ft';
      }
      return null;
    }

    const maxHeight = 300.0;
    if (height <= 0 || height >= maxHeight) {
      return 'Height must be between 0 and 300 $heightUnit';
    }

    return null; // Valid
  }

  /// Validates activity goals step data.
  ///
  /// Requirement 3.5: Validate at least one goal is selected
  String? validateActivityGoals() {
    final activityLevel = state.surveyData['activityLevel'] as String?;
    final goals = state.surveyData['goals'] as List<dynamic>?;

    if (activityLevel == null || activityLevel.isEmpty) {
      return 'Activity level is required';
    }

    final validActivityLevels = [
      'sedentary',
      'lightly_active',
      'moderately_active',
      'very_active',
      'extremely_active',
    ];

    if (!validActivityLevels.contains(activityLevel)) {
      return 'Invalid activity level';
    }

    if (goals == null || goals.isEmpty) {
      return 'At least one goal must be selected';
    }

    if (goals.length > 5) {
      return 'Maximum 5 goals can be selected';
    }

    return null; // Valid
  }

  /// Validates all survey data before submission.
  String? validateAllData() {
    String? error;

    error = validateBasicInfo();
    if (error != null) return error;

    error = validateBodyMeasurements();
    if (error != null) return error;

    error = validateActivityGoals();
    if (error != null) return error;

    // Validate daily calorie target exists
    final dailyCalorieTarget = state.surveyData['dailyCalorieTarget'] as int?;
    if (dailyCalorieTarget == null || dailyCalorieTarget <= 0) {
      return 'Daily calorie target must be calculated';
    }

    return null; // All valid
  }

  /// Submits the complete survey data to create a user profile.
  ///
  /// Validates all data, creates a UserProfile entity, and calls the repository
  /// with retry logic (up to 3 attempts).
  ///
  /// Requirement 4.1: Save all survey data to Supabase
  /// Requirement 4.3: Retry operation up to 3 times on failure
  Future<bool> submitSurvey(String userId) async {
    // Validate all data
    final validationError = validateAllData();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    // Create UserProfile entity from survey data
    final profile = UserProfile(
      userId: userId,
      fullName: state.surveyData['fullName'] as String,
      age: state.surveyData['age'] as int,
      gender: state.surveyData['gender'] as String,
      weight: state.surveyData['weight'] as double,
      height: state.surveyData['height'] as double,
      heightUnit: state.surveyData['heightUnit'] as String? ?? 'cm',
      weightUnit: state.surveyData['weightUnit'] as String? ?? 'kg',
      activityLevel: state.surveyData['activityLevel'] as String,
      goals: (state.surveyData['goals'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      dailyCalorieTarget: state.surveyData['dailyCalorieTarget'] as int,
      dailyStepsTarget: state.surveyData['dailyStepsTarget'] as int?,
      dailyActiveMinutesTarget:
          state.surveyData['dailyActiveMinutesTarget'] as int?,
      dailyWaterTarget: (state.surveyData['dailyWaterTarget'] as num?)
          ?.toDouble(),
      surveyCompleted: true,
    );

    // Attempt to save with retry logic (Requirement 4.3)
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        await _profileRepository.createProfile(profile);

        // Success - clear local storage and reset state
        await _clearSurveyData();
        state = SurveyState.initial();
        return true;
      } on AuthException catch (e) {
        if (attempt == _maxRetries) {
          // Final attempt failed
          state = state.copyWith(isLoading: false, errorMessage: e.message);
          return false;
        }
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempt));
      } catch (e) {
        if (attempt == _maxRetries) {
          // Final attempt failed
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Failed to save profile. Please try again.',
          );
          return false;
        }
        // Wait before retrying
        await Future.delayed(Duration(seconds: attempt));
      }
    }

    return false;
  }

  /// Clears survey data from local storage.
  Future<void> _clearSurveyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      // Silently fail
    }
  }

  /// Moves to the next survey step.
  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  /// Moves to the previous survey step.
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Resets the survey to initial state and clears local storage.
  Future<void> resetSurvey() async {
    await _clearSurveyData();
    state = SurveyState.initial();
  }
}
