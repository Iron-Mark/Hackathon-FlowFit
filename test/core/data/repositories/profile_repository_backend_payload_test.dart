import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:flowfit/core/domain/entities/user_profile.dart';

void main() {
  group('backend payload null-strip contract', () {
    test('a sparse profile produces a payload with no null-valued columns '
        'after the saveBackendProfile strip', () {
      final now = DateTime(2026, 7, 20, 12);
      final sparse = UserProfile(
        userId: 'user-123',
        createdAt: now,
        updatedAt: now,
      );

      final payload = sparse.toSupabaseJson()
        ..removeWhere((_, value) => value == null);

      expect(payload.values.any((value) => value == null), isFalse);
      expect(payload['user_id'], 'user-123');
      expect(payload.containsKey('is_kids_mode'), isTrue);
      expect(payload.containsKey('survey_completed'), isTrue);
      expect(payload.containsKey('updated_at'), isTrue);
      expect(payload.containsKey('created_at'), isFalse);
      // The clobber-prone columns must be absent, not false/empty.
      expect(payload.containsKey('nickname'), isFalse);
      expect(payload.containsKey('wellness_goals'), isFalse);
      expect(payload.containsKey('notifications_enabled'), isFalse);
    });

    test('set fields survive the strip untouched', () {
      final now = DateTime(2026, 7, 20, 12);
      final profile = UserProfile(
        userId: 'user-123',
        nickname: 'Flowy Fan',
        wellnessGoals: const ['calm'],
        notificationsEnabled: true,
        createdAt: now,
        updatedAt: now,
      );

      final payload = profile.toSupabaseJson()
        ..removeWhere((_, value) => value == null);

      expect(payload['nickname'], 'Flowy Fan');
      expect(payload['wellness_goals'], const ['calm']);
      expect(payload['notifications_enabled'], isTrue);
    });

    test(
      'saveBackendProfile strips nulls at the single upsert choke point',
      () {
        final source = File(
          'lib/core/data/repositories/profile_repository_impl.dart',
        ).readAsStringSync();

        expect(source, contains('removeWhere((_, value) => value == null)'));
        expect(source, contains(".upsert(payload, onConflict: 'user_id')"));
        expect(
          source.indexOf('removeWhere((_, value) => value == null)'),
          lessThan(source.indexOf(".upsert(payload, onConflict: 'user_id')")),
          reason: 'the strip must run before the upsert',
        );
      },
    );
  });
}
