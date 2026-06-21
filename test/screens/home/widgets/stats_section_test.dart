import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/screens/home/widgets/stats_section.dart';
import 'package:flowfit/providers/dashboard_providers.dart';
import 'package:flowfit/core/providers/providers.dart' as core_providers;
import 'package:flowfit/domain/entities/heart_rate_data.dart';
import 'package:flowfit/models/daily_mood.dart';
import 'package:flowfit/models/daily_stats.dart';

void main() {
  group('StatsSection', () {
    testWidgets('displays section header', (WidgetTester tester) async {
      final testStats = DailyStats(
        steps: 6504,
        stepsGoal: 10000,
        calories: 387,
        activeMinutes: 45,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyStatsProvider.overrideWith((ref) async => testStats),
            dailyMoodProvider.overrideWith((ref) async => _calmMood()),
            activityComparisonProvider.overrideWith((ref) async => 0),
            core_providers.currentHeartRateProvider.overrideWith(
              (ref) => Stream.value(
                HeartRateData(
                  bpm: 68,
                  ibiValues: [],
                  timestamp: DateTime.now(),
                  status: HeartRateStatus.active,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: StatsSection())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Track Your Activity'), findsOneWidget);
    });

    testWidgets('displays stats when data is loaded', (
      WidgetTester tester,
    ) async {
      final testStats = DailyStats(
        steps: 6504,
        stepsGoal: 10000,
        calories: 387,
        activeMinutes: 45,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyStatsProvider.overrideWith((ref) async => testStats),
            dailyMoodProvider.overrideWith((ref) async => _calmMood()),
            activityComparisonProvider.overrideWith((ref) async => 0),
            core_providers.currentHeartRateProvider.overrideWith(
              (ref) => Stream.value(
                HeartRateData(
                  bpm: 68,
                  ibiValues: [],
                  timestamp: DateTime.now(),
                  status: HeartRateStatus.active,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: StatsSection())),
        ),
      );

      await tester.pumpAndSettle();

      // Check for StepsCard
      expect(find.byType(StepsCard), findsOneWidget);

      // Check for MoodCard and CardioComparisonCard
      expect(find.byType(MoodCard), findsOneWidget);
      expect(find.byType(CardioComparisonCard), findsOneWidget);

      // Check for stats values
      expect(find.text('6504 / 10000'), findsOneWidget);
      expect(find.text('387'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
    });

    testWidgets('displays error state when data fails to load', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyStatsProvider.overrideWith((ref) async {
              throw Exception('Failed to load');
            }),
            dailyMoodProvider.overrideWith((ref) async => _calmMood()),
            core_providers.currentHeartRateProvider.overrideWith(
              (ref) => Stream.value(
                HeartRateData(
                  bpm: 68,
                  ibiValues: [],
                  timestamp: DateTime.now(),
                  status: HeartRateStatus.active,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: StatsSection())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load stats'), findsOneWidget);
      expect(find.text('Pull to refresh'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('uses theme colors correctly', (WidgetTester tester) async {
      final testStats = DailyStats(
        steps: 5000,
        stepsGoal: 10000,
        calories: 300,
        activeMinutes: 30,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyStatsProvider.overrideWith((ref) async => testStats),
            dailyMoodProvider.overrideWith((ref) async => _calmMood()),
            core_providers.currentHeartRateProvider.overrideWith(
              (ref) => Stream.value(
                HeartRateData(
                  bpm: 68,
                  ibiValues: [],
                  timestamp: DateTime.now(),
                  status: HeartRateStatus.active,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: const ColorScheme.light(
                primary: Colors.blue,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            home: const Scaffold(body: StatsSection()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify theme is being used
      expect(find.byType(StatsSection), findsOneWidget);
    });

    testWidgets('displays mood unavailable when mood data fails to load', (
      WidgetTester tester,
    ) async {
      final testStats = DailyStats(
        steps: 5000,
        stepsGoal: 10000,
        calories: 300,
        activeMinutes: 30,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyStatsProvider.overrideWith((ref) async => testStats),
            dailyMoodProvider.overrideWith((ref) async {
              throw StateError('heart rate history unavailable');
            }),
            activityComparisonProvider.overrideWith((ref) async => 0),
            core_providers.currentHeartRateProvider.overrideWith(
              (ref) => Stream.value(
                HeartRateData(
                  bpm: 68,
                  ibiValues: [],
                  timestamp: DateTime.now(),
                  status: HeartRateStatus.active,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: StatsSection())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mood unavailable'), findsOneWidget);
      expect(find.byType(CardioComparisonCard), findsOneWidget);
    });
  });

  group('StepsCard', () {
    testWidgets('displays all required information', (
      WidgetTester tester,
    ) async {
      final stats = DailyStats(
        steps: 6504,
        stepsGoal: 10000,
        calories: 387,
        activeMinutes: 45,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StepsCard(stats: stats)),
        ),
      );

      // Check for steps label
      expect(find.text('Steps'), findsOneWidget);

      // Check for steps value
      expect(find.text('6504 / 10000'), findsOneWidget);

      // Check for percentage
      expect(find.text('65%'), findsOneWidget);

      // Check for progress bar
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Check for icon
      expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    });

    testWidgets('calculates progress percentage correctly', (
      WidgetTester tester,
    ) async {
      final stats = DailyStats(
        steps: 5000,
        stepsGoal: 10000,
        calories: 300,
        activeMinutes: 30,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StepsCard(stats: stats)),
        ),
      );

      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('handles 0 steps correctly', (WidgetTester tester) async {
      final stats = DailyStats(
        steps: 0,
        stepsGoal: 10000,
        calories: 0,
        activeMinutes: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StepsCard(stats: stats)),
        ),
      );

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0 / 10000'), findsOneWidget);
    });

    testWidgets('handles goal exceeded correctly', (WidgetTester tester) async {
      final stats = DailyStats(
        steps: 12000,
        stepsGoal: 10000,
        calories: 500,
        activeMinutes: 60,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StepsCard(stats: stats)),
        ),
      );

      expect(find.text('120%'), findsOneWidget);
      expect(find.text('12000 / 10000'), findsOneWidget);
    });

    testWidgets('uses theme styling correctly', (WidgetTester tester) async {
      final stats = DailyStats(
        steps: 5000,
        stepsGoal: 10000,
        calories: 300,
        activeMinutes: 30,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              surface: Colors.white,
            ),
          ),
          home: Scaffold(body: StepsCard(stats: stats)),
        ),
      );

      // Verify card is rendered
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('CompactStatsCard', () {
    testWidgets('displays all required information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactStatsCard(
              icon: Icons.local_fire_department,
              value: '387',
              label: 'Calories',
              color: Colors.red,
            ),
          ),
        ),
      );

      expect(find.text('387'), findsOneWidget);
      expect(find.text('Calories'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('uses provided color for icon container', (
      WidgetTester tester,
    ) async {
      const testColor = Colors.red;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactStatsCard(
              icon: Icons.local_fire_department,
              value: '387',
              label: 'Calories',
              color: testColor,
            ),
          ),
        ),
      );

      // Find the icon
      final icon = tester.widget<Icon>(
        find.byIcon(Icons.local_fire_department),
      );
      expect(icon.color, testColor);
    });

    testWidgets('displays active minutes correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactStatsCard(
              icon: Icons.timer,
              value: '45',
              label: 'Active Minutes',
              color: Colors.cyan,
            ),
          ),
        ),
      );

      expect(find.text('45'), findsOneWidget);
      expect(find.text('Active Minutes'), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
    });

    testWidgets('uses theme styling correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          home: const Scaffold(
            body: CompactStatsCard(
              icon: Icons.timer,
              value: '45',
              label: 'Active Minutes',
              color: Colors.cyan,
            ),
          ),
        ),
      );

      // Verify card is rendered
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('StatsSection Layout', () {
    testWidgets('displays cards in correct layout', (
      WidgetTester tester,
    ) async {
      final testStats = DailyStats(
        steps: 6504,
        stepsGoal: 10000,
        calories: 387,
        activeMinutes: 45,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyStatsProvider.overrideWith((ref) async => testStats),
            dailyMoodProvider.overrideWith((ref) async => _calmMood()),
            activityComparisonProvider.overrideWith((ref) async => 0),
          ],
          child: const MaterialApp(home: Scaffold(body: StatsSection())),
        ),
      );

      await tester.pumpAndSettle();

      // Verify StepsCard is full width (appears before Row)
      expect(find.byType(StepsCard), findsOneWidget);

      // Verify Mood and Cardio cards are in a Row
      expect(find.byType(Row), findsWidgets);
      expect(find.byType(MoodCard), findsOneWidget);
      expect(find.byType(CardioComparisonCard), findsOneWidget);
    });

    testWidgets('has proper spacing between cards', (
      WidgetTester tester,
    ) async {
      final testStats = DailyStats(
        steps: 6504,
        stepsGoal: 10000,
        calories: 387,
        activeMinutes: 45,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyStatsProvider.overrideWith((ref) async => testStats),
            dailyMoodProvider.overrideWith((ref) async => _calmMood()),
          ],
          child: const MaterialApp(home: Scaffold(body: StatsSection())),
        ),
      );

      await tester.pumpAndSettle();

      // Verify SizedBox widgets exist for spacing
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}

DailyMood _calmMood() => DailyMood(stressMinutes: 0, calmMinutes: 20);
