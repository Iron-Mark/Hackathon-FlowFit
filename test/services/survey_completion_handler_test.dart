import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/services/survey_completion_handler.dart';
import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/core/exceptions/profile_exceptions.dart';

/// Mock implementation of ProfileRepository for testing
class MockProfileRepository implements ProfileRepository {
  UserProfile? _localProfile;
  UserProfile? _backendProfile;
  bool _shouldFailLocal = false;
  bool _shouldFailBackend = false;

  void setShouldFailLocal(bool value) => _shouldFailLocal = value;
  void setShouldFailBackend(bool value) => _shouldFailBackend = value;

  @override
  Future<UserProfile?> getLocalProfile(String userId) async {
    return _localProfile;
  }

  @override
  Future<void> saveLocalProfile(UserProfile profile) async {
    if (_shouldFailLocal) {
      throw LocalStorageException('Local save failed');
    }
    _localProfile = profile;
  }

  @override
  Future<void> deleteLocalProfile(String userId) async {
    _localProfile = null;
  }

  @override
  Future<UserProfile?> getBackendProfile(String userId) async {
    return _backendProfile;
  }

  @override
  Future<void> saveBackendProfile(UserProfile profile) async {
    if (_shouldFailBackend) {
      throw BackendSyncException('Backend save failed');
    }
    _backendProfile = profile;
  }

  @override
  Future<void> syncProfile(String userId) async {}

  @override
  Future<bool> hasPendingSync(String userId) async {
    return _localProfile?.isSynced == false;
  }

  @override
  Stream<SyncStatus> watchSyncStatus(String userId) {
    return Stream.value(SyncStatus.synced);
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    return _localProfile != null;
  }
}

void main() {
  group('SurveyCompletionHandler', () {
    late MockProfileRepository mockRepository;
    late SurveyCompletionHandler handler;

    setUp(() {
      mockRepository = MockProfileRepository();
      handler = SurveyCompletionHandler(profileRepository: mockRepository);
    });

    test('completeSurvey saves profile locally and syncs to backend', () async {
      // Arrange
      const userId = 'test-user-123';
      final surveyData = {
        'fullName': 'John Doe',
        'age': 30,
        'gender': 'male',
        'height': 180.0,
        'weight': 75.0,
        'activityLevel': 'moderately_active',
        'goals': ['lose_weight', 'improve_cardio'],
        'dailyCalorieTarget': 2000,
        'dailyStepsTarget': 10000,
        'dailyActiveMinutesTarget': 30,
        'dailyWaterTarget': 2.5,
      };

      // Act
      final result = await handler.completeSurvey(userId, surveyData);

      // Assert
      expect(result, true);
      expect(mockRepository._localProfile, isNotNull);
      expect(mockRepository._localProfile!.userId, userId);
      expect(mockRepository._localProfile!.fullName, 'John Doe');
      expect(mockRepository._localProfile!.age, 30);
      expect(mockRepository._localProfile!.isSynced, true);
      expect(mockRepository._backendProfile, isNotNull);
      expect(mockRepository._backendProfile!.surveyCompleted, true);
      expect(
        mockRepository._backendProfile!.toSupabaseJson()['survey_completed'],
        true,
      );
    });

    test('completeSurvey succeeds even if backend sync fails', () async {
      // Arrange
      const userId = 'test-user-123';
      final surveyData = {
        'fullName': 'Jane Doe',
        'age': 25,
        'gender': 'female',
        'height': 165.0,
        'weight': 60.0,
        'activityLevel': 'very_active',
        'goals': ['build_muscle'],
        'dailyCalorieTarget': 2200,
      };
      mockRepository.setShouldFailBackend(true);

      // Act
      final result = await handler.completeSurvey(userId, surveyData);

      // Assert
      expect(result, true);
      expect(mockRepository._localProfile, isNotNull);
      expect(mockRepository._localProfile!.isSynced, false);
      expect(mockRepository._backendProfile, isNull);
    });

    test('completeSurvey throws exception if local save fails', () async {
      // Arrange
      const userId = 'test-user-123';
      final surveyData = {
        'fullName': 'Test User',
        'age': 28,
        'gender': 'other',
        'height': 170.0,
        'weight': 70.0,
        'activityLevel': 'sedentary',
        'goals': ['maintain_weight'],
        'dailyCalorieTarget': 1800,
      };
      mockRepository.setShouldFailLocal(true);

      // Act & Assert
      expect(
        () => handler.completeSurvey(userId, surveyData),
        throwsA(isA<SurveyCompletionException>()),
      );
    });

    test('completeSurvey throws exception if survey data is empty', () async {
      // Arrange
      const userId = 'test-user-123';
      final surveyData = <String, dynamic>{};

      // Act & Assert
      expect(
        () => handler.completeSurvey(userId, surveyData),
        throwsA(isA<SurveyCompletionException>()),
      );
    });

    test('isSurveyComplete returns true for complete survey data', () {
      // Arrange
      final surveyData = {
        'fullName': 'John Doe',
        'age': 30,
        'gender': 'male',
        'height': 180.0,
        'weight': 75.0,
        'activityLevel': 'moderately_active',
        'goals': ['lose_weight'],
        'dailyCalorieTarget': 2000,
      };

      // Act
      final result = handler.isSurveyComplete(surveyData);

      // Assert
      expect(result, true);
    });

    test('isSurveyComplete returns false for incomplete survey data', () {
      // Arrange
      final surveyData = {
        'fullName': 'John Doe',
        'age': 30,
        // Missing required fields
      };

      // Act
      final result = handler.isSurveyComplete(surveyData);

      // Assert
      expect(result, false);
    });

    test(
      'completeSurvey uses defaults if survey data conversion fails',
      () async {
        // Arrange
        const userId = 'test-user-123';
        final surveyData = {
          'fullName': 'Test User',
          // Minimal data that might cause conversion issues
        };

        // Act
        final result = await handler.completeSurvey(userId, surveyData);

        // Assert
        expect(result, true);
        expect(mockRepository._localProfile, isNotNull);
        expect(mockRepository._localProfile!.userId, userId);
      },
    );
  });
}
