import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flowfit/core/data/repositories/profile_repository_impl.dart';
import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/core/exceptions/profile_exceptions.dart';

/// Simple mock for Supabase client (not used in local storage tests)
class MockSupabaseClient extends SupabaseClient {
  MockSupabaseClient() : super('https://test.supabase.co', 'test-key');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileRepositoryImpl - Local Storage', () {
    late SharedPreferences prefs;
    late ProfileRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = ProfileRepositoryImpl(
        prefs: prefs,
        supabase: MockSupabaseClient(),
      );
    });

    group('getLocalProfile', () {
      test('returns null when no profile exists', () async {
        final result = await repository.getLocalProfile('user-123');
        expect(result, isNull);
      });

      test('returns profile when it exists', () async {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveLocalProfile(profile);
        final result = await repository.getLocalProfile('user-123');

        expect(result, isNotNull);
        expect(result!.userId, 'user-123');
        expect(result.fullName, 'John Doe');
        expect(result.age, 30);
      });

      test('throws LocalStorageException on invalid JSON', () async {
        // Manually set invalid JSON
        await prefs.setString('user_profile_user-123', 'invalid json');

        expect(
          () => repository.getLocalProfile('user-123'),
          throwsA(isA<LocalStorageException>()),
        );
      });

      test('handles multiple users independently', () async {
        final profile1 = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final profile2 = UserProfile(
          userId: 'user-456',
          fullName: 'Jane Doe',
          age: 25,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveLocalProfile(profile1);
        await repository.saveLocalProfile(profile2);

        final result1 = await repository.getLocalProfile('user-123');
        final result2 = await repository.getLocalProfile('user-456');

        expect(result1!.fullName, 'John Doe');
        expect(result2!.fullName, 'Jane Doe');
      });
    });

    group('saveLocalProfile', () {
      test('saves profile successfully', () async {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'Jane Doe',
          age: 25,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveLocalProfile(profile);

        final result = await repository.getLocalProfile('user-123');
        expect(result, isNotNull);
        expect(result!.fullName, 'Jane Doe');
      });

      test('throws ValidationException for invalid profile', () async {
        final profile = UserProfile(
          userId: 'user-123',
          age: 6, // Invalid age
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(
          () => repository.saveLocalProfile(profile),
          throwsA(isA<ValidationException>()),
        );
      });

      test('overwrites existing profile', () async {
        final profile1 = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final profile2 = UserProfile(
          userId: 'user-123',
          fullName: 'Jane Doe',
          age: 25,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveLocalProfile(profile1);
        await repository.saveLocalProfile(profile2);

        final result = await repository.getLocalProfile('user-123');
        expect(result!.fullName, 'Jane Doe');
        expect(result.age, 25);
      });

      test('preserves all profile fields', () async {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          gender: 'male',
          height: 180.0,
          weight: 75.0,
          heightUnit: 'cm',
          weightUnit: 'kg',
          activityLevel: 'moderately_active',
          goals: ['lose_weight', 'improve_cardio'],
          dailyCalorieTarget: 2000,
          dailyStepsTarget: 10000,
          dailyActiveMinutesTarget: 30,
          dailyWaterTarget: 2.5,
          profileImagePath: '/path/to/image.jpg',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        await repository.saveLocalProfile(profile);
        final result = await repository.getLocalProfile('user-123');

        expect(result!.fullName, 'John Doe');
        expect(result.age, 30);
        expect(result.gender, 'male');
        expect(result.height, 180.0);
        expect(result.weight, 75.0);
        expect(result.heightUnit, 'cm');
        expect(result.weightUnit, 'kg');
        expect(result.activityLevel, 'moderately_active');
        expect(result.goals, ['lose_weight', 'improve_cardio']);
        expect(result.dailyCalorieTarget, 2000);
        expect(result.dailyStepsTarget, 10000);
        expect(result.dailyActiveMinutesTarget, 30);
        expect(result.dailyWaterTarget, 2.5);
        expect(result.profileImagePath, '/path/to/image.jpg');
        expect(result.isSynced, true);
      });
    });

    group('deleteLocalProfile', () {
      test('deletes profile successfully', () async {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveLocalProfile(profile);
        await repository.deleteLocalProfile('user-123');

        final result = await repository.getLocalProfile('user-123');
        expect(result, isNull);
      });

      test('does not throw when profile does not exist', () async {
        expect(
          () => repository.deleteLocalProfile('user-123'),
          returnsNormally,
        );
      });

      test('only deletes specified user profile', () async {
        final profile1 = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final profile2 = UserProfile(
          userId: 'user-456',
          fullName: 'Jane Doe',
          age: 25,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveLocalProfile(profile1);
        await repository.saveLocalProfile(profile2);
        await repository.deleteLocalProfile('user-123');

        final result1 = await repository.getLocalProfile('user-123');
        final result2 = await repository.getLocalProfile('user-456');

        expect(result1, isNull);
        expect(result2, isNotNull);
        expect(result2!.fullName, 'Jane Doe');
      });
    });

    group('hasPendingSync', () {
      test('returns false when no profile exists', () async {
        final result = await repository.hasPendingSync('user-123');
        expect(result, false);
      });

      test('returns true when profile is not synced', () async {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: false,
        );

        await repository.saveLocalProfile(profile);

        final result = await repository.hasPendingSync('user-123');
        expect(result, true);
      });

      test('returns false when profile is synced', () async {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        await repository.saveLocalProfile(profile);

        final result = await repository.hasPendingSync('user-123');
        expect(result, false);
      });

      test('returns false on error', () async {
        // Manually corrupt the data
        await prefs.setString('user_profile_user-123', 'invalid');

        final result = await repository.hasPendingSync('user-123');
        expect(result, false);
      });
    });

    group('watchSyncStatus', () {
      test('emits initial status for non-existent profile', () async {
        final stream = repository.watchSyncStatus('user-123');

        expect(stream, emits(isA<SyncStatus>()));
      });

      test('emits pendingSync when profile is not synced', () async {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: false,
        );

        await repository.saveLocalProfile(profile);

        final stream = repository.watchSyncStatus('user-123');

        expect(stream, emits(SyncStatus.pendingSync));
      });

      test('emits synced when profile is synced', () async {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        await repository.saveLocalProfile(profile);

        final stream = repository.watchSyncStatus('user-123');

        expect(stream, emits(SyncStatus.synced));
      });
    });

    group('Data Persistence', () {
      test('profile survives repository recreation', () async {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveLocalProfile(profile);

        // Create new repository instance with same prefs
        final newRepository = ProfileRepositoryImpl(
          prefs: prefs,
          supabase: MockSupabaseClient(),
        );

        final result = await newRepository.getLocalProfile('user-123');
        expect(result, isNotNull);
        expect(result!.fullName, 'John Doe');
      });

      test('handles DateTime serialization correctly', () async {
        final now = DateTime.now();
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          createdAt: now,
          updatedAt: now,
        );

        await repository.saveLocalProfile(profile);
        final result = await repository.getLocalProfile('user-123');

        expect(result!.createdAt.year, now.year);
        expect(result.createdAt.month, now.month);
        expect(result.createdAt.day, now.day);
        expect(result.updatedAt.year, now.year);
      });

      test('handles null optional fields correctly', () async {
        final profile = UserProfile(
          userId: 'user-123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveLocalProfile(profile);
        final result = await repository.getLocalProfile('user-123');

        expect(result!.fullName, isNull);
        expect(result.age, isNull);
        expect(result.gender, isNull);
        expect(result.goals, isNull);
      });
    });
  });
}
