import 'package:flowfit/screens/track/track_screen.dart';
import 'package:flowfit/screens/workout/running/running_setup_screen.dart';
import 'package:flowfit/screens/workout/walking/walking_options_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AI Workout opens the activity classifier route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const TrackScreen(),
          routes: {
            '/activity-classifier': (context) =>
                const Scaffold(body: Center(child: Text('Classifier Route'))),
          },
        ),
      ),
    );

    await tester.tap(find.text('AI Workout'));
    await tester.pumpAndSettle();

    expect(find.text('Classifier Route'), findsOneWidget);
  });

  testWidgets('Take a Walk opens the full walking options flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const TrackScreen(),
          routes: {
            '/workout/walking/options': (context) =>
                const WalkingOptionsScreen(),
          },
        ),
      ),
    );

    await tester.tap(find.text('Take a Walk'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Walking Mode'), findsOneWidget);
    expect(find.text('Start Free Walk'), findsOneWidget);
    expect(find.text('Create Mission'), findsOneWidget);
  });

  testWidgets('Log a Run opens the running setup screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const TrackScreen(),
          routes: {
            '/workout/running/setup': (context) => const RunningSetupScreen(),
          },
        ),
      ),
    );

    await tester.ensureVisible(find.text('Log a Run'));
    await tester.tap(find.text('Log a Run'));
    await tester.pumpAndSettle();

    expect(find.text('Running Setup'), findsOneWidget);
    expect(find.text('Start Running'), findsOneWidget);
  });
}
