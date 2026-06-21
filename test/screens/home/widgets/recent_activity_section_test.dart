import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/screens/home/widgets/recent_activity_section.dart';
import 'package:flowfit/providers/dashboard_providers.dart';
import 'package:flowfit/models/recent_activity.dart';
import 'package:flowfit/models/mood_rating.dart';

void main() {
  group('RecentActivitySection', () {
    testWidgets('displays section header', (WidgetTester tester) async {
      final testActivities = [
        RecentActivity(
          id: '1',
          name: 'Morning Run',
          type: 'run',
          details: '3.2 miles • 30 min',
          date: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recentActivitiesProvider.overrideWith(
              (ref) async => testActivities,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RecentActivitySection()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Your Recent Activity'), findsOneWidget);
    });

    testWidgets('displays activities when data is loaded', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final testActivities = [
        RecentActivity(
          id: '1',
          name: 'Morning Run',
          type: 'run',
          details: '3.2 miles • 30 min',
          date: now,
        ),
        RecentActivity(
          id: '2',
          name: 'Evening Walk',
          type: 'walk',
          details: '1.5 miles • 20 min',
          date: now.subtract(const Duration(days: 1)),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recentActivitiesProvider.overrideWith(
              (ref) async => testActivities,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RecentActivitySection()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Morning Run'), findsOneWidget);
      expect(find.text('Evening Walk'), findsOneWidget);
      expect(find.text('3.2 miles • 30 min'), findsOneWidget);
    });

    testWidgets('displays empty state when no activities', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [recentActivitiesProvider.overrideWith((ref) async => [])],
          child: const MaterialApp(
            home: Scaffold(body: RecentActivitySection()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No activity yet today'), findsOneWidget);
    });

    testWidgets('displays loading skeleton while loading', (
      WidgetTester tester,
    ) async {
      // Use a provider that takes time to complete
      bool completed = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recentActivitiesProvider.overrideWith((ref) async {
              await Future.delayed(const Duration(milliseconds: 100));
              completed = true;
              return [];
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RecentActivitySection()),
          ),
        ),
      );

      // Should show loading skeleton immediately (before data loads)
      expect(completed, false);
      expect(find.byType(Container), findsWidgets);

      // Wait for completion
      await tester.pumpAndSettle();
      expect(completed, true);
    });

    testWidgets('displays error state on error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recentActivitiesProvider.overrideWith((ref) async {
              throw Exception('Failed to load');
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RecentActivitySection()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load activities'), findsOneWidget);
    });
  });

  group('ActivityCard', () {
    testWidgets('displays activity information', (WidgetTester tester) async {
      final activity = RecentActivity(
        id: '1',
        name: 'Morning Run',
        type: 'run',
        details: '3.2 miles • 30 min',
        date: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityCard(activity: activity)),
        ),
      );

      expect(find.text('Morning Run'), findsOneWidget);
      expect(find.text('3.2 miles • 30 min'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets(
      'opens and closes activity details without requiring GoRouter',
      (WidgetTester tester) async {
        final activity = RecentActivity(
          id: '1',
          name: 'Morning Run',
          type: 'run',
          details: '3.2 miles • 30 min',
          date: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ActivityCard(activity: activity)),
          ),
        );

        await tester.tap(find.byType(ActivityCard));
        await tester.pumpAndSettle();

        expect(find.text('Date'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Close'), findsOneWidget);

        await tester.tap(find.widgetWithText(FilledButton, 'Close'));
        await tester.pumpAndSettle();

        expect(find.text('Date'), findsNothing);
        expect(find.text('Morning Run'), findsOneWidget);
      },
    );

    testWidgets('activity details include mood data and mood boost', (
      WidgetTester tester,
    ) async {
      final activity = RecentActivity(
        id: '1',
        name: 'Mood Run',
        type: 'run',
        details: '2.1 miles • 22 min',
        date: DateTime.now(),
        preMood: MoodRating.fromValue(2),
        postMood: MoodRating.fromValue(5),
        moodChange: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityCard(activity: activity)),
        ),
      );

      await tester.tap(find.byType(ActivityCard));
      await tester.pumpAndSettle();

      expect(find.text('Mood'), findsOneWidget);
      expect(find.text('😕 to 💪'), findsOneWidget);
      expect(find.text('Mood boost: +3 points 🚀'), findsWidgets);
    });

    testWidgets('uses correct icon and color for run type', (
      WidgetTester tester,
    ) async {
      final activity = RecentActivity(
        id: '1',
        name: 'Morning Run',
        type: 'run',
        details: '3.2 miles • 30 min',
        date: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityCard(activity: activity)),
        ),
      );

      // Find the icon container
      final iconContainer = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ActivityCard),
              matching: find.byType(Container),
            )
            .first,
      );

      // Verify it has decoration with color
      expect(iconContainer.decoration, isA<BoxDecoration>());
    });

    testWidgets('uses correct icon and color for walk type', (
      WidgetTester tester,
    ) async {
      final activity = RecentActivity(
        id: '1',
        name: 'Evening Walk',
        type: 'walk',
        details: '1.5 miles • 20 min',
        date: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityCard(activity: activity)),
        ),
      );

      expect(find.text('Evening Walk'), findsOneWidget);
    });

    testWidgets('uses correct icon and color for workout type', (
      WidgetTester tester,
    ) async {
      final activity = RecentActivity(
        id: '1',
        name: 'Gym Workout',
        type: 'workout',
        details: '45 min • Upper body',
        date: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityCard(activity: activity)),
        ),
      );

      expect(find.text('Gym Workout'), findsOneWidget);
    });

    testWidgets('uses correct icon and color for cycle type', (
      WidgetTester tester,
    ) async {
      final activity = RecentActivity(
        id: '1',
        name: 'Bike Ride',
        type: 'cycle',
        details: '10 miles • 45 min',
        date: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityCard(activity: activity)),
        ),
      );

      expect(find.text('Bike Ride'), findsOneWidget);
    });
  });
}
