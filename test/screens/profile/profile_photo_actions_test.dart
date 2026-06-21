import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flowfit/core/domain/entities/user_profile.dart' as core;
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/domain/entities/user.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/presentation/notifiers/profile_notifier.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('flowfit_profile_photo_');
  });

  tearDown(() async {
    SharedPreferences.setMockInitialValues({});
    await _deleteDirectoryBestEffort(tempDir);
  });

  testWidgets('camera action saves selected profile photo for current user', (
    tester,
  ) async {
    final image = _writeTestPng(tempDir, 'camera.png');
    ImageSource? requestedSource;

    await tester.pumpWidget(
      _harness(
        pickProfileImage: (source) async {
          requestedSource = source;
          return image.path;
        },
      ),
    );
    await tester.pumpAndSettle();

    await _openPhotoSheet(tester);
    await tester.tap(find.text('Take Photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final prefs = await SharedPreferences.getInstance();
    expect(requestedSource, ImageSource.camera);
    expect(prefs.getString(_profileImageKey), image.path);
    expect(find.text('Profile photo updated'), findsOneWidget);
  });

  testWidgets('gallery action saves selected profile photo for current user', (
    tester,
  ) async {
    final image = _writeTestPng(tempDir, 'gallery.png');
    ImageSource? requestedSource;

    await tester.pumpWidget(
      _harness(
        pickProfileImage: (source) async {
          requestedSource = source;
          return image.path;
        },
      ),
    );
    await tester.pumpAndSettle();

    await _openPhotoSheet(tester);
    await tester.tap(find.text('Choose from Gallery'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final prefs = await SharedPreferences.getInstance();
    expect(requestedSource, ImageSource.gallery);
    expect(prefs.getString(_profileImageKey), image.path);
    expect(find.text('Profile photo updated'), findsOneWidget);
  });

  testWidgets('profile photo avatar ignores duplicate sheet requests', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final avatarTapTarget = find
        .ancestor(
          of: find.byType(CircleAvatar).first,
          matching: find.byType(GestureDetector),
        )
        .first;
    final avatarGesture = tester.widget<GestureDetector>(avatarTapTarget);

    avatarGesture.onTap!();
    avatarGesture.onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Change Profile Photo'), findsOneWidget);
  });

  testWidgets(
    'gallery action ignores duplicate picker requests while pending',
    (tester) async {
      final image = _writeTestPng(tempDir, 'gallery-pending.png');
      final pickCompleter = Completer<String?>();
      var pickCalls = 0;

      await tester.pumpWidget(
        _harness(
          pickProfileImage: (source) {
            pickCalls++;
            expect(source, ImageSource.gallery);
            return pickCompleter.future;
          },
        ),
      );
      await tester.pumpAndSettle();

      await _openPhotoSheet(tester);

      final galleryTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Choose from Gallery'),
      );
      galleryTile.onTap!();
      galleryTile.onTap!();
      await tester.pump();

      expect(pickCalls, 1);

      pickCompleter.complete(image.path);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      expect(pickCalls, 1);
      expect(prefs.getString(_profileImageKey), image.path);
      expect(find.text('Profile photo updated'), findsOneWidget);
    },
  );

  testWidgets('gallery picker failure shows an error and keeps current photo', (
    tester,
  ) async {
    final existingImage = _writeTestPng(tempDir, 'existing.png');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, existingImage.path);

    await tester.pumpWidget(
      _harness(
        pickProfileImage: (_) async => throw StateError('gallery unavailable'),
      ),
    );
    await tester.pumpAndSettle();
    await _pumpProfileImageLoad(tester);

    await _openPhotoSheet(tester);
    await tester.tap(find.text('Choose from Gallery'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(prefs.getString(_profileImageKey), existingImage.path);
    expect(find.textContaining('Error selecting photo:'), findsOneWidget);
  });

  testWidgets('remove photo clears persisted profile image', (tester) async {
    final existingImage = _writeTestPng(tempDir, 'existing.png');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, existingImage.path);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await _pumpProfileImageLoad(tester);

    await _openPhotoSheet(tester);
    expect(find.text('Remove Photo'), findsOneWidget);

    await tester.tap(find.text('Remove Photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(prefs.getString(_profileImageKey), isNull);
    expect(find.text('Profile photo removed'), findsOneWidget);
  });

  testWidgets('remove photo ignores duplicate remove requests', (tester) async {
    final existingImage = _writeTestPng(tempDir, 'existing-duplicate.png');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, existingImage.path);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await _pumpProfileImageLoad(tester);

    await _openPhotoSheet(tester);

    final removeTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Remove Photo'),
    );
    removeTile.onTap!();
    removeTile.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(prefs.getString(_profileImageKey), isNull);
    expect(find.text('Profile photo removed'), findsOneWidget);
  });

  testWidgets('profile setting and goal tiles open their routes', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await _tapRouteTile(
      tester,
      tileText: 'Change Password',
      routeText: 'route:change-password',
    );
    await _tapRouteTile(
      tester,
      tileText: 'Delete Account',
      routeText: 'route:delete-account',
    );
    await _tapRouteTile(
      tester,
      tileText: 'Physical Stats',
      routeText: 'route:weight-goals',
    );
    await _tapRouteTile(
      tester,
      tileText: 'Fitness Goals',
      routeText: 'route:fitness-goals',
    );
    await _tapRouteTile(
      tester,
      tileText: 'Nutrition Goals',
      routeText: 'route:nutrition-goals',
    );
  });
}

const String _userId = 'test-user-123';
const String _profileImageKey = 'profile_image_$_userId';

Widget _harness({ProfileImagePicker? pickProfileImage}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      profileNotifierProvider.overrideWith((ref, userId) {
        return ProfileNotifier(_FakeProfileRepository(), userId);
      }),
      syncStatusProvider.overrideWith(
        (ref, userId) => Stream.value(SyncStatus.synced),
      ),
      pendingSyncCountProvider.overrideWith((ref) async => 0),
    ],
    child: MaterialApp(
      home: ProfileScreen(pickProfileImage: pickProfileImage),
      routes: {
        '/settings': (_) => const Scaffold(body: Text('route:settings')),
        '/change-password': (_) =>
            const Scaffold(body: Text('route:change-password')),
        '/delete-account': (_) =>
            const Scaffold(body: Text('route:delete-account')),
        '/weight-goals': (_) =>
            const Scaffold(body: Text('route:weight-goals')),
        '/fitness-goals': (_) =>
            const Scaffold(body: Text('route:fitness-goals')),
        '/nutrition-goals': (_) =>
            const Scaffold(body: Text('route:nutrition-goals')),
      },
    ),
  );
}

Future<void> _openPhotoSheet(WidgetTester tester) async {
  await tester.tap(find.byType(CircleAvatar).first);
  await tester.pumpAndSettle();
  expect(find.text('Change Profile Photo'), findsOneWidget);
}

Future<void> _tapRouteTile(
  WidgetTester tester, {
  required String tileText,
  required String routeText,
}) async {
  await tester.ensureVisible(find.text(tileText));
  await tester.tap(find.text(tileText));
  await tester.pumpAndSettle();

  expect(find.text(routeText), findsOneWidget);

  Navigator.of(tester.element(find.text(routeText))).pop();
  await tester.pumpAndSettle();
}

Future<void> _pumpProfileImageLoad(WidgetTester tester) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));

    final avatars = find.byType(CircleAvatar).evaluate();
    if (avatars.isEmpty) {
      continue;
    }

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
    if (avatar.backgroundImage != null) {
      return;
    }
  }

  final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
  expect(avatar.backgroundImage, isNotNull);
}

File _writeTestPng(Directory directory, String name) {
  final file = File('${directory.path}${Platform.pathSeparator}$name');
  file.writeAsBytesSync(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
    ),
  );
  return file;
}

Future<void> _deleteDirectoryBestEffort(Directory directory) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
      return;
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
}

class _FakeAuthRepository implements IAuthRepository {
  @override
  Stream<User?> authStateChanges() {
    return Stream.value(_user());
  }

  @override
  Future<User?> getCurrentUser() async => _user();

  @override
  Future<User> signIn({required String email, required String password}) async {
    return _user();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    return _user();
  }

  User _user() {
    return User(
      id: _userId,
      email: 'test@example.com',
      fullName: 'Test User',
      createdAt: DateTime(2026),
    );
  }
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<void> deleteLocalProfile(String userId) async {}

  @override
  Future<core.UserProfile?> getBackendProfile(String userId) async {
    return getLocalProfile(userId);
  }

  @override
  Future<core.UserProfile?> getLocalProfile(String userId) async {
    return core.UserProfile(
      userId: userId,
      fullName: 'Test User',
      age: 30,
      gender: 'Male',
      weight: 70,
      weightUnit: 'kg',
      height: 175,
      heightUnit: 'cm',
      activityLevel: 'Moderate',
      goals: const ['Fitness'],
      dailyCalorieTarget: 2000,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isSynced: true,
    );
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async => true;

  @override
  Future<bool> hasPendingSync(String userId) async => false;

  @override
  Future<void> saveBackendProfile(core.UserProfile profile) async {}

  @override
  Future<void> saveLocalProfile(core.UserProfile profile) async {}

  @override
  Future<void> syncProfile(String userId) async {}

  @override
  Stream<SyncStatus> watchSyncStatus(String userId) {
    return Stream.value(SyncStatus.synced);
  }
}
