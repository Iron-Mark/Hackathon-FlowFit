import 'package:flowfit/main.dart' as flowfit_main;
import 'package:flowfit/models/running_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('running share route handles missing session arguments', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/workout/running/share',
        routes: {
          '/dashboard': (_) => const Scaffold(body: Text('route:dashboard')),
          '/workout/running/share': flowfit_main.buildRunningShareRoute,
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Share Achievement'), findsOneWidget);
    expect(
      find.text('No running session is available to share.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Back to Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('route:dashboard'), findsOneWidget);
  });

  testWidgets('running share route opens achievement screen with session', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/workout/running/share',
                      arguments: {'session': _runningSession()},
                    );
                  },
                  child: const Text('Open Share'),
                ),
              ),
            );
          },
        ),
        routes: const {
          '/workout/running/share': flowfit_main.buildRunningShareRoute,
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Share'));
    await tester.pumpAndSettle();

    expect(find.text('Add Background Image'), findsOneWidget);
    expect(find.text('Share Achievement'), findsWidgets);
  });
}

RunningSession _runningSession() {
  return RunningSession(
    id: 'run-share-route',
    userId: 'user-1',
    startTime: DateTime(2026),
    goalType: GoalType.distance,
    targetDistance: 5,
    durationSeconds: 600,
    currentDistance: 1.5,
    avgPace: 6.4,
    steps: 1800,
    caloriesBurned: 120,
  );
}
