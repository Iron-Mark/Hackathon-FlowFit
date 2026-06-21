import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/screens/profile/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('profile view avatar, edit, password, and logout actions work', (
    tester,
  ) async {
    var photoTaps = 0;
    var editTaps = 0;
    var logoutTaps = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ProfileView(
              profile: _profile(),
              userEmail: 'member@flowfit.test',
              onPhotoTap: () => photoTaps++,
              onEditTap: () => editTaps++,
              onLogout: () => logoutTaps++,
            ),
          ),
          routes: {
            '/change-password': (_) =>
                const Scaffold(body: Text('route:change-password')),
          },
        ),
      ),
    );

    expect(find.text('Test Member'), findsOneWidget);
    expect(find.text('member@flowfit.test'), findsOneWidget);
    expect(find.text('TM'), findsOneWidget);
    expect(find.text('Improve Cardio'), findsOneWidget);

    await tester.tap(find.byType(CircleAvatar));
    await tester.pump();
    expect(photoTaps, 1);

    await tester.tap(find.byTooltip('Edit Profile'));
    await tester.pump();
    expect(editTaps, 1);

    await tester.ensureVisible(find.text('Change Password'));
    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();
    expect(find.text('route:change-password'), findsOneWidget);

    Navigator.of(tester.element(find.text('route:change-password'))).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Logout'));
    await tester.tap(find.text('Logout'));
    await tester.pump();
    expect(logoutTaps, 1);
  });

  testWidgets('profile view hides optional actions when callbacks are absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ProfileView(
              profile: _profile(fullName: null, goals: const []),
              userEmail: 'member@flowfit.test',
              onPhotoTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('User'), findsOneWidget);
    expect(find.text('U'), findsOneWidget);
    expect(find.byTooltip('Edit Profile'), findsNothing);
    expect(find.text('Logout'), findsNothing);
    expect(find.text('Fitness Goals'), findsNothing);
  });

  testWidgets(
    'profile view formats stored imperial height as feet and inches',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfileView(
                profile: _profile().copyWith(height: 70.0, heightUnit: 'ft'),
                userEmail: 'member@flowfit.test',
                onPhotoTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('5 ft 10 in'), findsOneWidget);
    },
  );
}

UserProfile _profile({String? fullName = 'Test Member', List<String>? goals}) {
  return UserProfile(
    userId: 'user-1',
    fullName: fullName,
    age: 30,
    gender: 'female',
    height: 165,
    weight: 62,
    heightUnit: 'cm',
    weightUnit: 'kg',
    activityLevel: 'moderately_active',
    goals: goals ?? const ['improve_cardio'],
    dailyCalorieTarget: 1800,
    dailyStepsTarget: 10000,
    dailyActiveMinutesTarget: 45,
    dailyWaterTarget: 2.5,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}
