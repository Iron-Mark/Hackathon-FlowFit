import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/core/providers/user_profile_provider.dart';

void main() {
  group('UserProfile Entity', () {
    test('should include nickname and isKidsMode fields', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'test-user-id',
        nickname: 'TestNickname',
        isKidsMode: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(profile.nickname, 'TestNickname');
      expect(profile.isKidsMode, true);
    });

    test('should default isKidsMode to true', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'test-user-id',
        createdAt: now,
        updatedAt: now,
      );

      expect(profile.isKidsMode, true);
    });

    test('should serialize nickname and isKidsMode to JSON', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'test-user-id',
        nickname: 'TestNickname',
        isKidsMode: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = profile.toJson();

      expect(json['nickname'], 'TestNickname');
      expect(json['isKidsMode'], true);
    });

    test('should serialize nickname and isKidsMode to Supabase JSON', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'test-user-id',
        nickname: 'TestNickname',
        isKidsMode: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = profile.toSupabaseJson();

      expect(json['nickname'], 'TestNickname');
      expect(json['is_kids_mode'], true);
    });

    test('should deserialize nickname and isKidsMode from JSON', () {
      final json = {
        'user_id': 'test-user-id',
        'nickname': 'TestNickname',
        'is_kids_mode': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.nickname, 'TestNickname');
      expect(profile.isKidsMode, true);
    });

    test('should handle null nickname', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'test-user-id',
        nickname: null,
        isKidsMode: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(profile.nickname, null);
    });

    test('should update nickname via copyWith', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'test-user-id',
        nickname: 'OldNickname',
        isKidsMode: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = profile.copyWith(nickname: 'NewNickname');

      expect(updated.nickname, 'NewNickname');
      expect(updated.userId, profile.userId);
    });

    test('should update isKidsMode via copyWith', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'test-user-id',
        isKidsMode: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = profile.copyWith(isKidsMode: true);

      expect(updated.isKidsMode, true);
      expect(updated.userId, profile.userId);
    });
  });

  group('UserProfileNotifier', () {
    test('should be instantiable', () {
      final container = ProviderContainer();
      final notifier = container.read(
        userProfileNotifierProvider('test-user-id').notifier,
      );

      expect(notifier, isA<UserProfileNotifier>());

      container.dispose();
    });
  });
}
