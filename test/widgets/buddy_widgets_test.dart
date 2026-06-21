import 'package:flowfit/models/buddy_profile.dart';
import 'package:flowfit/screens/profile/buddy_profile_card.dart';
import 'package:flowfit/widgets/buddy_egg_widget.dart';
import 'package:flowfit/widgets/buddy_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('buddy error widget shows retry action when provided', (
    tester,
  ) async {
    var retryCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuddyErrorWidget(
            message: 'Buddy could not load.',
            onRetry: () => retryCalls++,
          ),
        ),
      ),
    );

    expect(find.text('Buddy could not load.'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);

    await tester.tap(find.text('Try Again'));
    await tester.pump();

    expect(retryCalls, 1);
  });

  testWidgets('buddy error widget can hide retry action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BuddyErrorWidget(
            message: 'Buddy is resting.',
            showRetry: false,
          ),
        ),
      ),
    );

    expect(find.text('Buddy is resting.'), findsOneWidget);
    expect(find.text('Try Again'), findsNothing);
  });

  testWidgets('buddy loading widget displays optional message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BuddyLoadingWidget(message: 'Waking up Buddy...')),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Waking up Buddy...'), findsOneWidget);
  });

  testWidgets('buddy egg exposes color semantics and handles taps', (
    tester,
  ) async {
    var tapCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: BuddyEggWidget(
              baseColor: const Color(0xFF4ECDC4),
              isSelected: true,
              onTap: () => tapCalls++,
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Ocean blue color egg'), findsOneWidget);

    await tester.tap(find.byType(BuddyEggWidget));
    await tester.pump();

    expect(tapCalls, 1);
  });

  testWidgets('buddy profile card renders progress and customization action', (
    tester,
  ) async {
    var customizeCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuddyProfileCard(
            buddyProfile: _profile(level: 12, xp: 450, color: 'purple'),
            onCustomizeTap: () => customizeCalls++,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Splashy'), findsOneWidget);
    expect(find.text('Level 12 • Teen'), findsOneWidget);
    expect(find.text('450 / 1300 XP'), findsOneWidget);
    expect(find.text('Customize Buddy'), findsOneWidget);

    await tester.tap(find.text('Customize Buddy'));
    await tester.pump();

    expect(customizeCalls, 1);
  });
}

BuddyProfile _profile({int level = 1, int xp = 0, String color = 'blue'}) {
  return BuddyProfile(
    id: 'buddy-1',
    userId: 'user-1',
    name: 'Splashy',
    color: color,
    level: level,
    xp: xp,
    unlockedColors: const ['blue', 'purple'],
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}
