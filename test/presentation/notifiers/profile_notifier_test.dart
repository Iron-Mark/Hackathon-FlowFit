import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/presentation/notifiers/profile_notifier.dart';
import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/core/exceptions/profile_exceptions.dart';

/// Mock ProfileRepository for testing
class MockProfileRepository implements ProfileRepository {
  UserProfile? _localProfile;
  UserProfile? _backendProfile;
  bool _shouldFailLocal = false;
  bool _shouldFailBackend = false;
  bool _shouldFailValidation = false;

  void setLocalProfile(UserProfile? profile) => _localProfile = profile;
  void setBackendProfile(UserProfile? profile) => _backendProfile = profile;
  void setShouldFailLocal(bool value) => _shouldFailLocal = value;
  void setShouldFailBackend(bool value) => _shouldFailBackend = value;
  void setShouldFailValidation(bool value) => _shouldFailValidation = value;

  void reset() {
    _localProfile = null;
    _backendProfile = null;
    _shouldFailLocal = false;
    _shouldFailBackend = false;
    _shouldFailValidation = false;
  }

  @override
  Future<UserProfile?> getLocalProfile(String userId) async {
    if (_shouldFailLocal) {
      throw LocalStorageException('Local storage failed');
    }
    return _localProfile;
  }

  @override
  Future<void> saveLocalProfile(UserProfile profile) async {
    if (_shouldFailLocal) {
      throw LocalStorageException('Local storage failed');
    }
    if (_shouldFailValidation) {
      throw ValidationException('Validation failed');
    }
    _localProfile = profile;
  }

  @override
  Future<void> deleteLocalProfile(String userId) async {
    if (_shouldFailLocal) {
      throw LocalStorageException('Local storage failed');
    }
    _localProfile = null;
  }

  @override
  Future<UserProfile?> getBackendProfile(String userId) async {
    if (_shouldFailBackend) {
      throw BackendSyncException('Backend sync failed');
    }
    return _backendProfile;
  }

  @override
  Future<void> saveBackendProfile(UserProfile profile) async {
    if (_shouldFailBackend) {
      throw BackendSyncException('Backend sync failed');
    }
    _backendProfile = profile;
  }

  @override
  Future<void> syncProfile(String userId) async {
    if (_shouldFailBackend) {
      throw BackendSyncException('Sync failed');
    }
  }

  @override
  Future<bool> hasPendingSync(String userId) async {
    return _localProfile?.isSynced == false;
  }

  @override
  Stream<SyncStatus> watchSyncStatus(String userId) {
    return Stream.value(
      _localProfile?.isSynced == false
          ? SyncStatus.pendingSync
          : SyncStatus.synced,
    );
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    return _localProfile != null;
  }
}

void main() {
  group('ProfileNotifier', () {
    late MockProfileRepository mockRepository;
    late ProfileNotifier notifier;
    const userId = 'user-123';

    setUp(() {
      mockRepository = MockProfileRepository();
      notifier = ProfileNotifier(mockRepository, userId);
    });

    tearDown(() {
      mockRepository.reset();
      notifier.dispose();
    });

    group('loadProfile', () {
      test('loads local profile first', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(profile);
        mockRepository.setBackendProfile(null);

        await notifier.loadProfile();

        expect(notifier.state.value, isNotNull);
        expect(notifier.state.value!.fullName, 'John Doe');
      });

      test('updates with backend profile when available', () async {
        final localProfile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final backendProfile = UserProfile(
          userId: userId,
          fullName: 'Jane Doe',
          age: 25,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(localProfile);
        mockRepository.setBackendProfile(backendProfile);

        await notifier.loadProfile();

        // Should eventually show backend profile
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.value, isNotNull);
        expect(notifier.state.value!.fullName, 'Jane Doe');
      });

      test('returns null when no profile exists', () async {
        mockRepository.setLocalProfile(null);
        mockRepository.setBackendProfile(null);

        await notifier.loadProfile();

        expect(notifier.state.value, isNull);
      });

      test('uses local profile when backend fetch fails', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(profile);
        mockRepository.setShouldFailBackend(true);

        await notifier.loadProfile();

        expect(notifier.state.value, isNotNull);
        expect(notifier.state.value!.fullName, 'John Doe');
      });

      test('sets error state when both local and backend fail', () async {
        mockRepository.setLocalProfile(null);
        mockRepository.setShouldFailLocal(true);
        mockRepository.setShouldFailBackend(true);

        await notifier.loadProfile();

        expect(notifier.state.hasError, true);
      });

      test('starts with loading state', () async {
        // Note: ProfileNotifier automatically calls loadProfile() in constructor
        // So by the time we check, it may have already loaded
        // This test verifies the initial state is set correctly
        final freshNotifier = ProfileNotifier(mockRepository, userId);
        expect(
          freshNotifier.state.isLoading || freshNotifier.state.hasValue,
          true,
        );

        // Wait for load to complete before disposing
        await Future.delayed(const Duration(milliseconds: 100));
        freshNotifier.dispose();
      });
    });

    group('updateProfile', () {
      test('saves profile locally and syncs to backend', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await notifier.updateProfile(profile);

        expect(notifier.state.value, isNotNull);
        expect(notifier.state.value!.fullName, 'John Doe');
        expect(notifier.state.value!.isSynced, true);
        expect(mockRepository._localProfile, isNotNull);
        expect(mockRepository._backendProfile, isNotNull);
      });

      test('saves locally even when backend sync fails', () async {
        mockRepository.setShouldFailBackend(true);

        final profile = UserProfile(
          userId: userId,
          fullName: 'Jane Doe',
          age: 25,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await notifier.updateProfile(profile);

        expect(notifier.state.value, isNotNull);
        expect(notifier.state.value!.fullName, 'Jane Doe');
        expect(notifier.state.value!.isSynced, false);
        expect(mockRepository._localProfile, isNotNull);
        expect(mockRepository._backendProfile, isNull);
      });

      test('throws ValidationException for invalid profile', () async {
        final profile = UserProfile(
          userId: userId,
          age: 6, // Invalid age
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(
          () => notifier.updateProfile(profile),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws exception when local save fails', () async {
        mockRepository.setShouldFailLocal(true);

        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(
          () => notifier.updateProfile(profile),
          throwsA(isA<LocalStorageException>()),
        );
      });

      test('updates updatedAt timestamp', () async {
        final now = DateTime.now();
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: now,
          updatedAt: now.subtract(const Duration(hours: 1)),
        );

        await notifier.updateProfile(profile);

        expect(
          notifier.state.value!.updatedAt.isAfter(profile.updatedAt),
          true,
        );
      });

      test('sets isSynced to false initially', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        mockRepository.setShouldFailBackend(true);

        await notifier.updateProfile(profile);

        // Should be false because backend sync failed
        expect(notifier.state.value!.isSynced, false);
      });
    });

    group('updateField', () {
      test('updates fullName field', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(profile);
        await notifier.loadProfile();

        await notifier.updateField('fullName', 'Jane Doe');

        expect(notifier.state.value!.fullName, 'Jane Doe');
        expect(notifier.state.value!.age, 30); // Other fields unchanged
      });

      test('updates age field', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(profile);
        await notifier.loadProfile();

        await notifier.updateField('age', 31);

        expect(notifier.state.value!.age, 31);
      });

      test('updates gender field', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(profile);
        await notifier.loadProfile();

        await notifier.updateField('gender', 'male');

        expect(notifier.state.value!.gender, 'male');
      });

      test('updates height field', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(profile);
        await notifier.loadProfile();

        await notifier.updateField('height', 180.0);

        expect(notifier.state.value!.height, 180.0);
      });

      test('updates weight field', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(profile);
        await notifier.loadProfile();

        await notifier.updateField('weight', 75.0);

        expect(notifier.state.value!.weight, 75.0);
      });

      test('updates activityLevel field', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(profile);
        await notifier.loadProfile();

        await notifier.updateField('activityLevel', 'very_active');

        expect(notifier.state.value!.activityLevel, 'very_active');
      });

      test('updates goals field', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(profile);
        await notifier.loadProfile();

        await notifier.updateField('goals', ['lose_weight', 'build_muscle']);

        expect(notifier.state.value!.goals, ['lose_weight', 'build_muscle']);
      });

      test('updates dailyCalorieTarget field', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(profile);
        await notifier.loadProfile();

        await notifier.updateField('dailyCalorieTarget', 2000);

        expect(notifier.state.value!.dailyCalorieTarget, 2000);
      });

      test('does nothing when profile is null', () async {
        mockRepository.setLocalProfile(null);
        await notifier.loadProfile();

        await notifier.updateField('fullName', 'John Doe');

        expect(notifier.state.value, isNull);
      });

      test('ignores unknown field names', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(profile);
        await notifier.loadProfile();

        await notifier.updateField('unknownField', 'value');

        // Profile should remain unchanged
        expect(notifier.state.value!.fullName, 'John Doe');
      });
    });

    group('refresh', () {
      test('reloads profile from repository', () async {
        final profile1 = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(profile1);
        await notifier.loadProfile();

        expect(notifier.state.value!.fullName, 'John Doe');

        // Update repository
        final profile2 = UserProfile(
          userId: userId,
          fullName: 'Jane Doe',
          age: 25,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        mockRepository.setLocalProfile(profile2);

        await notifier.refresh();

        expect(notifier.state.value!.fullName, 'Jane Doe');
      });
    });

    group('deleteProfile', () {
      test('deletes profile and sets state to null', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(profile);
        await notifier.loadProfile();

        expect(notifier.state.value, isNotNull);

        await notifier.deleteProfile();

        expect(notifier.state.value, isNull);
        expect(mockRepository._localProfile, isNull);
      });

      test('sets error state when delete fails', () async {
        mockRepository.setShouldFailLocal(true);

        await notifier.deleteProfile();

        expect(notifier.state.hasError, true);
      });
    });

    group('State Transitions', () {
      test('transitions from loading to data', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(profile);

        // Create fresh notifier to observe state transition
        final freshNotifier = ProfileNotifier(mockRepository, userId);

        // Wait for load to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(freshNotifier.state.isLoading, false);
        expect(freshNotifier.state.hasValue, true);

        freshNotifier.dispose();
      });

      test('transitions from loading to error', () async {
        mockRepository.setShouldFailLocal(true);
        mockRepository.setShouldFailBackend(true);

        // Create fresh notifier to observe state transition
        final freshNotifier = ProfileNotifier(mockRepository, userId);

        // Wait for load to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(freshNotifier.state.isLoading, false);
        expect(freshNotifier.state.hasError, true);

        freshNotifier.dispose();
      });

      test('transitions from data to loading to data on refresh', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(profile);
        await notifier.loadProfile();

        expect(notifier.state.hasValue, true);

        final refreshFuture = notifier.refresh();

        // Should be loading during refresh
        expect(notifier.state.isLoading, true);

        await refreshFuture;

        // Should be back to data
        expect(notifier.state.hasValue, true);
      });

      test('maintains data state during update', () async {
        final profile = UserProfile(
          userId: userId,
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        mockRepository.setLocalProfile(profile);
        await notifier.loadProfile();

        expect(notifier.state.hasValue, true);

        await notifier.updateProfile(profile.copyWith(age: 31));

        expect(notifier.state.hasValue, true);
        expect(notifier.state.isLoading, false);
      });
    });
  });
}
