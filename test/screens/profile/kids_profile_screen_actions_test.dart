import 'dart:async';

import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/domain/entities/user.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/presentation/notifiers/profile_notifier.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/screens/profile/kids_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KidsProfileScreen actions', () {
    testWidgets('empty state starts Buddy onboarding', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              const _FakeAuthRepository(),
            ),
          ],
          child: MaterialApp(
            home: const KidsProfileScreen(),
            routes: {
              '/buddy-welcome': (context) => const Scaffold(
                body: Center(child: Text('Buddy Welcome Route')),
              ),
            },
          ),
        ),
      );

      await tester.tap(find.text('Meet Your Whale Buddy!'));
      await tester.pumpAndSettle();

      expect(find.text('Buddy Welcome Route'), findsOneWidget);
    });

    testWidgets('error retry invalidates the profile provider', (tester) async {
      var providerBuilds = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _FakeAuthRepository(user: _testUser),
            ),
            profileNotifierProvider.overrideWith((ref, userId) {
              providerBuilds++;
              return ProfileNotifier(_ThrowingProfileRepository(), userId);
            }),
          ],
          child: const MaterialApp(home: KidsProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Oops! Something went wrong'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(providerBuilds, 1);

      await tester.tap(find.text('Try Again'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(providerBuilds, greaterThan(1));
    });
  });
}

final _testUser = User(
  id: 'kids-user-1',
  email: 'kid@example.com',
  fullName: 'Test Kid',
  createdAt: DateTime(2026),
);

class _FakeAuthRepository implements IAuthRepository {
  final User? user;

  const _FakeAuthRepository({this.user});

  @override
  Stream<User?> authStateChanges() => Stream.value(user);

  @override
  Future<User?> getCurrentUser() async => user;

  @override
  Future<void> signOut() async {}

  @override
  Future<User> signIn({required String email, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    throw UnimplementedError();
  }
}

class _ThrowingProfileRepository implements ProfileRepository {
  @override
  Future<void> deleteLocalProfile(String userId) async {}

  @override
  Future<UserProfile?> getBackendProfile(String userId) async {
    throw StateError('backend unavailable');
  }

  @override
  Future<UserProfile?> getLocalProfile(String userId) async {
    throw StateError('local unavailable');
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async => false;

  @override
  Future<bool> hasPendingSync(String userId) async => false;

  @override
  Future<void> saveBackendProfile(UserProfile profile) async {}

  @override
  Future<void> saveLocalProfile(UserProfile profile) async {}

  @override
  Future<void> syncProfile(String userId) async {}

  @override
  Stream<SyncStatus> watchSyncStatus(String userId) {
    return Stream.value(SyncStatus.syncFailed);
  }
}
