import 'dart:async';

import 'package:flowfit/providers/wellness_state_provider.dart';
import 'package:flowfit/screens/wellness/wellness_tracker_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('redirects to onboarding when setup is incomplete', (
    tester,
  ) async {
    final prefs = await _mockPrefs();

    await tester.pumpWidget(
      _harness(
        prefs: prefs,
        page: WellnessTrackerPage(
          hasCompletedOnboarding: () async => false,
          startMonitoring: () async {},
          startStepCounting: () async {},
          stopMonitoring: () async {},
          stopStepCounting: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('wellness onboarding opened'), findsOneWidget);
  });

  testWidgets('unmount during onboarding check does not throw', (tester) async {
    final prefs = await _mockPrefs();
    final completion = Completer<bool>();

    await tester.pumpWidget(
      _harness(
        prefs: prefs,
        page: WellnessTrackerPage(
          hasCompletedOnboarding: () => completion.future,
          startMonitoring: () async {},
          startStepCounting: () async {},
          stopMonitoring: () async {},
          stopStepCounting: () async {},
        ),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    completion.complete(true);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('unmount during monitoring startup does not throw', (
    tester,
  ) async {
    final prefs = await _mockPrefs();
    final startMonitoring = Completer<void>();

    await tester.pumpWidget(
      _harness(
        prefs: prefs,
        page: WellnessTrackerPage(
          hasCompletedOnboarding: () async => true,
          startMonitoring: () => startMonitoring.future,
          startStepCounting: () async {},
          stopMonitoring: () async {},
          stopStepCounting: () async {},
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    startMonitoring.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('retry connection reruns injected startup actions', (
    tester,
  ) async {
    final prefs = await _mockPrefs();
    var startMonitoringCalls = 0;
    var startStepCountingCalls = 0;

    await tester.pumpWidget(
      _harness(
        prefs: prefs,
        page: WellnessTrackerPage(
          hasCompletedOnboarding: () async => true,
          startMonitoring: () async {
            startMonitoringCalls += 1;
            if (startMonitoringCalls == 1) {
              throw StateError('watch unavailable');
            }
          },
          startStepCounting: () async {
            startStepCountingCalls += 1;
          },
          stopMonitoring: () async {},
          stopStepCounting: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(startMonitoringCalls, 1);
    expect(startStepCountingCalls, 0);
    expect(find.text('Connection Error'), findsOneWidget);
    expect(find.textContaining('watch unavailable'), findsOneWidget);

    await tester.tap(find.text('Retry Connection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(startMonitoringCalls, 2);
    expect(startStepCountingCalls, 1);
  });

  testWidgets('dispose runs injected cleanup actions', (tester) async {
    final prefs = await _mockPrefs();
    var stopMonitoringCalls = 0;
    var stopStepCountingCalls = 0;

    await tester.pumpWidget(
      _harness(
        prefs: prefs,
        page: WellnessTrackerPage(
          hasCompletedOnboarding: () async => true,
          startMonitoring: () async {
            throw StateError('stay on error screen');
          },
          startStepCounting: () async {},
          stopMonitoring: () async {
            stopMonitoringCalls += 1;
          },
          stopStepCounting: () async {
            stopStepCountingCalls += 1;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(stopMonitoringCalls, 1);
    expect(stopStepCountingCalls, 1);
  });
}

Future<SharedPreferences> _mockPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Widget _harness({
  required SharedPreferences prefs,
  required WellnessTrackerPage page,
}) {
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      home: page,
      routes: {
        '/wellness-onboarding': (_) =>
            const Scaffold(body: Text('wellness onboarding opened')),
      },
    ),
  );
}
