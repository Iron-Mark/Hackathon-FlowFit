import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/models/daily_stats.dart';
import 'package:flowfit/screens/dashboard/home_tab.dart' as ds;
import 'package:flowfit/models/daily_mood.dart';
import 'package:flowfit/core/providers/providers.dart' as core_providers;
import 'package:flowfit/providers/dashboard_providers.dart'
    as dashboard_providers;

void main() {
  testWidgets('AI Activity shows connect message when watch disconnected', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          core_providers.watchConnectionStateProvider.overrideWith(
            (ref) => Stream<bool>.value(false),
          ),
          // Override dailyMoodProvider
          // Using a FutureProvider that resolves quickly to a simple DailyMood
          // NOTE: Use provider override to avoid Supabase instance requirement
          // by bypassing the default implementation
          dashboard_providers.dailyMoodProvider.overrideWith(
            (ref) =>
                Future.value(DailyMood(stressMinutes: 0, calmMinutes: 24 * 60)),
          ),
          dashboard_providers.dailyStatsProvider.overrideWith(
            (ref) => Future.value(
              DailyStats(
                steps: 0,
                stepsGoal: 10000,
                calories: 0,
                activeMinutes: 0,
              ),
            ),
          ),
          // Override heart rate stream provider so it's deterministic
          core_providers.currentHeartRateProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
        ],
        child: const MaterialApp(home: ds.HomeTab()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Watch not connected'), findsOneWidget);
    expect(find.text('Connect'), findsWidgets);
  });
}
