import 'dart:convert';
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

/// Backend saves always fail; getBackendProfile returns a canned profile so
/// the dead-letter restore pass can run its stale guard.
class _DeadLetterRestoreRepository implements ProfileRepository {
  _DeadLetterRestoreRepository({this.backendProfile});

  final UserProfile? backendProfile;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getBackendProfile) {
      return Future<UserProfile?>.value(backendProfile);
    }
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

    test('parks exhausted items in the dead-letter store instead of '
        'silently dropping them', () {
      expect(source, contains('_deadLetterKey'));
      expect(source, contains('parking item in dead-letter store'));
      expect(source, isNot(contains('discarding item')));
    });

    test('exposes a static dead-letter purge for account deletion', () {
      expect(source, contains('clearDeadLetterForUser'));
    });

    test('bounds dead-letter resurrection and tombstones deleted users', () {
      expect(source, contains('_maxDeadLetterAttempts'));
      expect(source, contains('_deletedUsersKey'));
      expect(source, contains('parked.parkCount >= _maxDeadLetterAttempts'));
    });
  });

  group('dead-letter restore', () {
    SyncQueueItem parkedItem() {
      return SyncQueueItem(
        userId: 'user-a',
        profile: _profile('user-a'),
        queuedAt: DateTime(2026, 7, 20, 12),
        retryCount: 5,
        nextRetryAt: DateTime(2026, 7, 20, 12, 30),
      );
    }

    test('re-enqueues a parked item with a fresh retry budget when the backend '
        'has nothing newer', () async {
      SharedPreferences.setMockInitialValues({
        'sync_queue_dead_letter': jsonEncode([parkedItem().toJson()]),
      });
      final prefs = await SharedPreferences.getInstance();
      final service = SyncQueueService(
        prefs: prefs,
        profileRepository: _DeadLetterRestoreRepository(backendProfile: null),
      );
      addTearDown(service.dispose);

      // Constructor kicks off the restore pass; let it settle.
      await pumpEventQueue();

      expect(await service.getPendingCount(), 1);
      expect(await service.hasPendingSync('user-a'), isTrue);
      expect(prefs.getString('sync_queue_dead_letter'), isNull);

      // Restored item starts over: retryCount reset, no pending backoff.
      final queueJson =
          jsonDecode(prefs.getString('sync_queue')!) as List<dynamic>;
      final restored = SyncQueueItem.fromJson(
        queueJson.single as Map<String, dynamic>,
      );
      expect(restored.userId, 'user-a');
      expect(restored.retryCount, 0);
      expect(restored.nextRetryAt, isNull);
    });

    test('drops a parked item permanently when the backend copy is newer than '
        'the parked payload', () async {
      SharedPreferences.setMockInitialValues({
        'sync_queue_dead_letter': jsonEncode([parkedItem().toJson()]),
      });
      final prefs = await SharedPreferences.getInstance();
      final newerBackendProfile = UserProfile(
        userId: 'user-a',
        createdAt: DateTime(2026, 7, 20, 11),
        updatedAt: DateTime(2026, 7, 20, 14),
      );
      final service = SyncQueueService(
        prefs: prefs,
        profileRepository: _DeadLetterRestoreRepository(
          backendProfile: newerBackendProfile,
        ),
      );
      addTearDown(service.dispose);

      await pumpEventQueue();

      expect(await service.getPendingCount(), 0);
      expect(await service.hasPendingSync('user-a'), isFalse);
      expect(prefs.getString('sync_queue_dead_letter'), isNull);
    });

    test('drops a payload that has been parked the maximum number of times '
        'instead of resurrecting it forever', () async {
      // parkCount at the give-up bound: a write the backend keeps rejecting.
      final exhausted = SyncQueueItem(
        userId: 'user-a',
        profile: _profile('user-a'),
        queuedAt: DateTime(2026, 7, 20, 12),
        retryCount: 5,
        parkCount: 2,
      );
      SharedPreferences.setMockInitialValues({
        'sync_queue_dead_letter': jsonEncode([exhausted.toJson()]),
      });
      final prefs = await SharedPreferences.getInstance();
      final service = SyncQueueService(
        prefs: prefs,
        profileRepository: _DeadLetterRestoreRepository(backendProfile: null),
      );
      addTearDown(service.dispose);

      await pumpEventQueue();

      // Not re-enqueued, and cleared from the dead-letter store for good.
      expect(await service.getPendingCount(), 0);
      expect(await service.hasPendingSync('user-a'), isFalse);
      expect(prefs.getString('sync_queue_dead_letter'), isNull);
    });

    test('does not re-persist a user tombstoned by account deletion, even if '
        'the restore pass held their payload', () async {
      // user-a is parked AND already tombstoned (account deletion raced the
      // live restore pass). Restore must not re-enqueue or re-park them.
      SharedPreferences.setMockInitialValues({
        'sync_queue_dead_letter': jsonEncode([parkedItem().toJson()]),
        'sync_queue_deleted_users': <String>['user-a'],
      });
      final prefs = await SharedPreferences.getInstance();
      final service = SyncQueueService(
        prefs: prefs,
        profileRepository: _DeadLetterRestoreRepository(backendProfile: null),
      );
      addTearDown(service.dispose);

      await pumpEventQueue();

      expect(await service.getPendingCount(), 0);
      expect(await service.hasPendingSync('user-a'), isFalse);
      expect(prefs.getString('sync_queue_dead_letter'), isNull);
      expect(prefs.getString('sync_queue'), anyOf(isNull, equals('[]')));
    });
  });

  group('clearDeadLetterForUser', () {
    SyncQueueItem deadLetter(String userId) {
      return SyncQueueItem(
        userId: userId,
        profile: _profile(userId),
        queuedAt: DateTime(2026, 7, 20, 12),
        retryCount: 5,
      );
    }

    test(
      'purges only the target user, leaving other parked payloads',
      () async {
        SharedPreferences.setMockInitialValues({
          'sync_queue_dead_letter': jsonEncode([
            deadLetter('user-a').toJson(),
            deadLetter('user-b').toJson(),
          ]),
        });
        final prefs = await SharedPreferences.getInstance();

        await SyncQueueService.clearDeadLetterForUser(prefs, 'user-a');

        final remaining =
            (jsonDecode(prefs.getString('sync_queue_dead_letter')!)
                    as List<dynamic>)
                .map(
                  (json) =>
                      SyncQueueItem.fromJson(json as Map<String, dynamic>),
                )
                .toList();
        expect(remaining.map((item) => item.userId), ['user-b']);

        // Purging the last parked user drops the key entirely.
        await SyncQueueService.clearDeadLetterForUser(prefs, 'user-b');
        expect(prefs.getString('sync_queue_dead_letter'), isNull);
      },
    );

    test('tombstones the purged user so a live instance cannot re-persist '
        'them', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await SyncQueueService.clearDeadLetterForUser(prefs, 'user-a');

      // The tombstone is written even when nothing was parked (the payload may
      // still be in the main queue or arrive via a racing restore).
      expect(
        prefs.getStringList('sync_queue_deleted_users'),
        contains('user-a'),
      );
    });
  });
}
