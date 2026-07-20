import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/services/backend/sync_queue_service.dart';

class _FailingSyncRepository implements ProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #saveBackendProfile) {
      return Future<void>.error(Exception('offline'));
    }
    return super.noSuchMethod(invocation);
  }
}

UserProfile _profile(String userId) {
  final now = DateTime(2026, 7, 20, 12);
  return UserProfile(userId: userId, createdAt: now, updatedAt: now);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'enqueue keeps one item per user, replacing the previous payload',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = SyncQueueService(
        prefs: prefs,
        profileRepository: _FailingSyncRepository(),
      );
      addTearDown(service.dispose);

      await service.enqueue(_profile('user-a'));
      await service.enqueue(_profile('user-a'));
      await service.enqueue(_profile('user-b'));

      // Whether or not the opportunistic process pass ran, a failing backend
      // leaves both users queued exactly once.
      expect(await service.getPendingCount(), 2);
      expect(await service.hasPendingSync('user-a'), isTrue);
      expect(await service.hasPendingSync('user-b'), isTrue);
    },
  );

  group('retry and replay contract (source pins)', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/services/backend/sync_queue_service.dart',
      ).readAsStringSync();
    });

    test('bounded exponential backoff: 5s initial, x2, max 5 attempts', () {
      expect(source, contains('static const int _maxRetries = 5;'));
      expect(
        source,
        contains(
          'static const Duration _initialBackoff = Duration(seconds: 5);',
        ),
      );
      expect(source, contains('static const int _backoffMultiplier = 2;'));
      expect(source, contains('item.retryCount < _maxRetries'));
    });

    test(
      'replay saves to the backend before marking the local copy synced',
      () {
        expect(source, contains('saveBackendProfile(item.profile)'));
        expect(source, contains('copyWith(isSynced: true)'));
        expect(
          source.indexOf('saveBackendProfile(item.profile)'),
          lessThan(source.indexOf('copyWith(isSynced: true)')),
        );
      },
    );

    test('documents the discard-after-max-retries behavior '
        '(a future re-enqueue fix must change this deliberately)', () {
      expect(source, contains('discarding item'));
    });
  });
}
