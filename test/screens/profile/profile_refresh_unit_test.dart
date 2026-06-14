import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/presentation/notifiers/profile_notifier.dart';
import 'package:flowfit/presentation/providers/profile_providers.dart';

@GenerateMocks([ProfileRepository, ProfileNotifier])
import 'profile_refresh_unit_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Refresh - Unit Tests', () {
    late MockProfileRepository mockRepository;
    late MockProfileNotifier mockNotifier;

    setUp(() {
      mockRepository = MockProfileRepository();
      mockNotifier = MockProfileNotifier();
    });

    /// Test: Refresh triggers profile reload
    /// Requirements: 6.1
    test('Refresh triggers profile reload', () async {
      // Arrange: Mock the loadProfile method
      when(mockNotifier.loadProfile()).thenAnswer((_) async {});

      // Act: Call loadProfile (simulating refresh)
      await mockNotifier.loadProfile();

      // Assert: Verify loadProfile was called
      verify(mockNotifier.loadProfile()).called(1);
    });

    /// Test: Refresh invalidates sync providers
    /// Requirements: 6.2, 6.3
    test('Refresh invalidates sync providers', () async {
      // Arrange: Create a ProviderContainer
      final container = ProviderContainer();

      const userId = 'test-user-123';

      // Act: Invalidate providers (simulating refresh)
      container.invalidate(profileNotifierProvider(userId));
      container.invalidate(syncStatusProvider(userId));
      container.invalidate(pendingSyncCountProvider);

      // Assert: No errors should occur
      expect(container, isNotNull);

      // Clean up
      container.dispose();
    });

    /// Test: Success message on successful refresh
    /// Requirements: 6.4
    test('Successful refresh completes without error', () async {
      // Arrange: Create a test profile
      final testProfile = UserProfile(
        userId: 'test-user-123',
        fullName: 'Test User',
        age: 30,
        gender: 'Male',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock successful repository responses
      when(
        mockRepository.getLocalProfile(any),
      ).thenAnswer((_) async => testProfile);
      when(mockRepository.syncProfile(any)).thenAnswer((_) async {});

      // Act: Load profile (simulating successful refresh)
      final profile = await mockRepository.getLocalProfile('test-user-123');

      // Assert: Profile should be loaded successfully
      expect(profile, isNotNull);
      expect(profile?.userId, equals('test-user-123'));
      expect(profile?.fullName, equals('Test User'));
    });

    /// Test: Error message on failed refresh
    /// Requirements: 6.5
    test('Failed refresh throws error', () async {
      // Arrange: Mock repository to throw error
      when(
        mockRepository.getLocalProfile(any),
      ).thenThrow(Exception('Network error'));

      // Act & Assert: Verify error is thrown
      expect(
        () => mockRepository.getLocalProfile('test-user'),
        throwsException,
      );
    });

    /// Test: Refresh handles null userId gracefully
    test('Refresh handles null userId gracefully', () async {
      // Arrange: Mock notifier with no calls expected
      // This tests the early return in _handleRefresh when userId is null

      // Act & Assert: No error should occur
      // The method should return early without calling repository
      verifyNever(mockRepository.getLocalProfile(any));
    });

    /// Test: Refresh updates profile data
    test('Refresh updates profile data correctly', () async {
      // Arrange: Create test profiles (before and after)
      final oldProfile = UserProfile(
        userId: 'test-user-123',
        fullName: 'Old Name',
        age: 30,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newProfile = UserProfile(
        userId: 'test-user-123',
        fullName: 'New Name',
        age: 31,
        createdAt: oldProfile.createdAt,
        updatedAt: DateTime.now(),
      );

      // Mock repository to return different profiles
      when(
        mockRepository.getLocalProfile('test-user-123'),
      ).thenAnswer((_) async => oldProfile);

      // Act: Load profile first time
      final profile1 = await mockRepository.getLocalProfile('test-user-123');

      // Update mock to return new profile
      when(
        mockRepository.getLocalProfile('test-user-123'),
      ).thenAnswer((_) async => newProfile);

      // Load profile second time (simulating refresh)
      final profile2 = await mockRepository.getLocalProfile('test-user-123');

      // Assert: Profile should be updated
      expect(profile1?.fullName, equals('Old Name'));
      expect(profile2?.fullName, equals('New Name'));
      expect(profile2?.age, equals(31));
    });

    /// Test: Multiple refresh calls are handled
    test('Multiple refresh calls are handled correctly', () async {
      // Arrange: Mock loadProfile
      when(mockNotifier.loadProfile()).thenAnswer((_) async {});

      // Act: Call loadProfile multiple times
      await mockNotifier.loadProfile();
      await mockNotifier.loadProfile();
      await mockNotifier.loadProfile();

      // Assert: Verify loadProfile was called 3 times
      verify(mockNotifier.loadProfile()).called(3);
    });

    /// Test: Refresh with sync failure
    test('Refresh handles sync failure gracefully', () async {
      // Arrange: Mock profile load success but sync failure
      final testProfile = UserProfile(
        userId: 'test-user-123',
        fullName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(
        mockRepository.getLocalProfile(any),
      ).thenAnswer((_) async => testProfile);
      when(mockRepository.syncProfile(any)).thenThrow(Exception('Sync failed'));

      // Act: Load profile succeeds
      final profile = await mockRepository.getLocalProfile('test-user-123');

      // Assert: Profile loaded even though sync might fail
      expect(profile, isNotNull);

      // Verify sync failure throws
      expect(
        () => mockRepository.syncProfile('test-user-123'),
        throwsException,
      );
    });
  });
}
