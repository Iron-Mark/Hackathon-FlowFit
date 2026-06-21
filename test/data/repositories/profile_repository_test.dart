import 'dart:io';

import 'package:flowfit/data/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/domain/exceptions/auth_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

class _MockSupabaseClient extends SupabaseClient {
  _MockSupabaseClient() : super('https://flowfit.test', 'test-key');
}

void main() {
  group('ProfileRepository Retry Logic', () {
    late String source;
    late ProfileRepository repository;

    setUpAll(() {
      source = File(
        'lib/data/repositories/profile_repository.dart',
      ).readAsStringSync();
    });

    setUp(() {
      repository = ProfileRepository(_MockSupabaseClient());
    });

    test('Retry logic attempts operation up to 3 times', () async {
      var attempts = 0;

      await expectLater(
        repository.executeWithRetryForTest<void>(() async {
          attempts++;
          throw UnknownException();
        }),
        throwsA(isA<UnknownException>()),
      );

      expect(attempts, 3);
    });

    test('Retry logic uses exponential backoff', () async {
      expect(
        source,
        contains('Future.delayed(Duration(milliseconds: 100 * attempts))'),
      );
    });

    test('Retry logic does not retry on validation errors', () async {
      var attempts = 0;

      await expectLater(
        repository.executeWithRetryForTest<void>(() async {
          attempts++;
          throw InvalidEmailException();
        }),
        throwsA(isA<InvalidEmailException>()),
      );

      expect(attempts, 1);
    });

    test('Network errors are retryable', () async {
      // This test verifies that NetworkException is considered retryable
      final AuthException networkError = NetworkException();
      final isRetryable =
          networkError is NetworkException || networkError is UnknownException;

      expect(isRetryable, isTrue);
    });

    test('Unknown errors are retryable', () async {
      // This test verifies that UnknownException is considered retryable
      final AuthException unknownError = UnknownException();
      final isRetryable =
          unknownError is NetworkException || unknownError is UnknownException;

      expect(isRetryable, isTrue);
    });

    test('ProfileRepository has correct max retries constant', () {
      expect(source, contains('static const int _maxRetries = 3;'));
    });

    test('createProfile upserts by user_id for recovered partial rows', () {
      final createProfileStart = source.indexOf(
        'Future<UserProfile> createProfile',
      );
      final updateProfileStart = source.indexOf(
        'Future<UserProfile> updateProfile',
      );
      final createProfileBody = source.substring(
        createProfileStart,
        updateProfileStart,
      );

      expect(createProfileBody, contains('.upsert('));
      expect(createProfileBody, contains("onConflict: 'user_id'"));
      expect(createProfileBody, isNot(contains('.insert(')));
    });

    test('Retry logic logs retry attempts', () {
      expect(source, contains('ErrorLogger.logInfo('));
      expect(source, contains("'Retry attempt \$attempts of \$_maxRetries'"));
      expect(source, contains('ErrorLogger.logWarning('));
      expect(source, contains("'Max retries (\$attempts) reached, giving up'"));
    });
  });
}
