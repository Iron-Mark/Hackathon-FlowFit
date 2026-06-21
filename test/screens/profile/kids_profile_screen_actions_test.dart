import 'dart:async';

import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/domain/entities/user.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/models/buddy_profile.dart';
import 'package:flowfit/presentation/notifiers/profile_notifier.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/providers/buddy_profile_provider.dart';
import 'package:flowfit/screens/profile/kids_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_icons/solar_icons.dart';

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

    testWidgets('loaded profile actions open kids profile routes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _loadedHarness(buddyProfile: _testBuddyProfile()),
      );
      await _pumpAnimatedProfile(tester);

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Splash'), findsOneWidget);
      expect(find.text('🎯 Focus Better'), findsOneWidget);

      await _invokeRouteAction(
        tester,
        open: () => tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, SolarIconsOutline.settings),
            )
            .onPressed!(),
        routeText: 'route:settings',
      );
      await _invokeRouteAction(
        tester,
        open: () => tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Customize Buddy'),
            )
            .onPressed!(),
        routeText: 'route:buddy-customization',
      );
      await _invokeRouteAction(
        tester,
        open: () => _listTile(tester, 'Customize Splash').onTap!(),
        routeText: 'route:buddy-customization',
      );
      await _invokeRouteAction(
        tester,
        open: () => _listTile(tester, 'Notifications').onTap!(),
        routeText: 'route:notification-settings',
      );
      await _invokeRouteAction(
        tester,
        open: () => _listTile(tester, 'Privacy & Safety').onTap!(),
        routeText: 'route:privacy-policy',
      );
      await _invokeRouteAction(
        tester,
        open: () => _listTile(tester, 'Help & Support').onTap!(),
        routeText: 'route:help-support',
      );
    });

    testWidgets('loaded profile without Buddy row keeps setup actions routed', (
      tester,
    ) async {
      await tester.pumpWidget(_loadedHarness());
      await _pumpAnimatedProfile(tester);

      expect(find.text('Captain'), findsWidgets);
      expect(find.text('Finish Buddy Setup'), findsOneWidget);
      expect(find.text('Set Up Buddy'), findsOneWidget);

      await _invokeRouteAction(
        tester,
        open: () => tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Customize Buddy'),
            )
            .onPressed!(),
        routeText: 'route:buddy-welcome',
      );
      await _invokeRouteAction(
        tester,
        open: () => tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Finish Buddy Setup'),
            )
            .onPressed!(),
        routeText: 'route:buddy-welcome',
      );
      await _invokeRouteAction(
        tester,
        open: () => _listTile(tester, 'Set Up Buddy').onTap!(),
        routeText: 'route:buddy-welcome',
      );
    });

    testWidgets('loaded profile logout can be cancelled or confirmed', (
      tester,
    ) async {
      var signOutCalls = 0;

      await tester.pumpWidget(
        _loadedHarness(
          buddyProfile: _testBuddyProfile(),
          authRepository: _FakeAuthRepository(
            user: _testUser,
            onSignOut: () async {
              signOutCalls++;
            },
          ),
        ),
      );
      await _pumpAnimatedProfile(tester);

      _listTile(tester, 'Logout').onTap!();
      await tester.pump();

      expect(find.text('Are you sure you want to logout?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pump();

      expect(signOutCalls, 0);
      expect(find.text('My Profile'), findsOneWidget);

      _listTile(tester, 'Logout').onTap!();
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Logout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(signOutCalls, 1);
      expect(find.text('route:welcome'), findsOneWidget);
    });
  });
}

final _testUser = User(
  id: 'kids-user-1',
  email: 'kid@example.com',
  fullName: 'Test Kid',
  createdAt: DateTime(2026),
);

Widget _loadedHarness({
  BuddyProfile? buddyProfile,
  IAuthRepository? authRepository,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        authRepository ?? _FakeAuthRepository(user: _testUser),
      ),
      profileNotifierProvider.overrideWith((ref, userId) {
        return ProfileNotifier(_LoadedProfileRepository(), userId);
      }),
      buddyProfileNotifierProvider.overrideWith((ref, userId) {
        return _LoadedBuddyProfileNotifier(userId, buddyProfile);
      }),
    ],
    child: MaterialApp(
      home: const KidsProfileScreen(),
      routes: {
        '/settings': (_) => const Scaffold(body: Text('route:settings')),
        '/buddy-customization': (_) =>
            const Scaffold(body: Text('route:buddy-customization')),
        '/buddy-welcome': (_) =>
            const Scaffold(body: Text('route:buddy-welcome')),
        '/notification-settings': (_) =>
            const Scaffold(body: Text('route:notification-settings')),
        '/privacy-policy': (_) =>
            const Scaffold(body: Text('route:privacy-policy')),
        '/help-support': (_) =>
            const Scaffold(body: Text('route:help-support')),
        '/welcome': (_) => const Scaffold(body: Text('route:welcome')),
      },
    ),
  );
}

Future<void> _invokeRouteAction(
  WidgetTester tester, {
  required VoidCallback open,
  required String routeText,
}) async {
  open();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));

  expect(find.text(routeText), findsOneWidget);

  Navigator.of(tester.element(find.text(routeText))).pop();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

ListTile _listTile(WidgetTester tester, String title) {
  return tester.widget<ListTile>(
    find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
  );
}

Future<void> _pumpAnimatedProfile(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

UserProfile _testProfile() {
  return UserProfile(
    userId: _testUser.id,
    fullName: 'Test Kid',
    age: 9,
    nickname: 'Captain',
    wellnessGoals: const ['focus', 'active'],
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    isSynced: true,
  );
}

BuddyProfile _testBuddyProfile() {
  return BuddyProfile(
    id: 'buddy-1',
    userId: _testUser.id,
    name: 'Splash',
    color: 'purple',
    level: 7,
    xp: 450,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

class _FakeAuthRepository implements IAuthRepository {
  final User? user;
  final Future<void> Function()? onSignOut;

  const _FakeAuthRepository({this.user, this.onSignOut});

  @override
  Stream<User?> authStateChanges() => Stream.value(user);

  @override
  Future<User?> getCurrentUser() async => user;

  @override
  Future<void> signOut() async {
    await onSignOut?.call();
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    return _testUser.copyWith(email: email);
  }

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    return _testUser.copyWith(email: email, fullName: fullName);
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

class _LoadedProfileRepository implements ProfileRepository {
  @override
  Future<void> deleteLocalProfile(String userId) async {}

  @override
  Future<UserProfile?> getBackendProfile(String userId) async {
    return getLocalProfile(userId);
  }

  @override
  Future<UserProfile?> getLocalProfile(String userId) async {
    return _testProfile();
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async => true;

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
    return Stream.value(SyncStatus.synced);
  }
}

class _LoadedBuddyProfileNotifier extends BuddyProfileNotifier {
  _LoadedBuddyProfileNotifier(super.userId, this.profile);

  final BuddyProfile? profile;

  @override
  Future<void> loadProfile() async {
    state = AsyncValue.data(profile);
  }
}
