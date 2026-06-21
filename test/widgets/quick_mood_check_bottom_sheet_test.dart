import 'package:flowfit/providers/mood_tracking_provider.dart';
import 'package:flowfit/providers/workout_flow_provider.dart';
import 'package:flowfit/widgets/quick_mood_check_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pre-workout mood selection updates mood and workout flow', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var selectedCallbacks = 0;

    await tester.pumpWidget(
      _harness(
        container,
        QuickMoodCheckBottomSheet(onMoodSelected: () => selectedCallbacks++),
      ),
    );

    await tester.tap(find.text('Open mood sheet'));
    await _pumpFrames(tester);

    expect(find.text('How are you feeling?'), findsOneWidget);
    expect(find.text('Auto-selecting in 10 seconds'), findsOneWidget);

    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();

    final moodState = container.read(moodTrackingProvider);
    final workoutFlowState = container.read(workoutFlowProvider);

    expect(moodState.preMood?.value, 4);
    expect(workoutFlowState.preMood?.value, 4);
    expect(workoutFlowState.currentStep, WorkoutFlowStep.workoutTypeSelection);
    expect(selectedCallbacks, 1);
    expect(find.text('How are you feeling?'), findsNothing);
  });

  testWidgets('post-workout mood selection records mood change from pre mood', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(moodTrackingProvider.notifier).selectPreMood(2);
    var selectedCallbacks = 0;

    await tester.pumpWidget(
      _harness(
        container,
        QuickMoodCheckBottomSheet(
          isPostWorkout: true,
          onMoodSelected: () => selectedCallbacks++,
        ),
      ),
    );

    await tester.tap(find.text('Open mood sheet'));
    await _pumpFrames(tester);

    expect(find.text('How do you feel now?'), findsOneWidget);
    expect(find.text('Auto-selecting in 15 seconds'), findsOneWidget);

    await tester.tap(find.text('Energized'));
    await tester.pumpAndSettle();

    final moodState = container.read(moodTrackingProvider);

    expect(moodState.preMood?.value, 2);
    expect(moodState.postMood?.value, 5);
    expect(moodState.moodChange, 3);
    expect(selectedCallbacks, 1);
    expect(find.text('How do you feel now?'), findsNothing);
  });

  testWidgets('pre-workout mood auto-select defaults to neutral mood', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var selectedCallbacks = 0;

    await tester.pumpWidget(
      _harness(
        container,
        QuickMoodCheckBottomSheet(onMoodSelected: () => selectedCallbacks++),
      ),
    );

    await tester.tap(find.text('Open mood sheet'));
    await _pumpFrames(tester);

    expect(find.text('Auto-selecting in 10 seconds'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    final moodState = container.read(moodTrackingProvider);
    final workoutFlowState = container.read(workoutFlowProvider);

    expect(moodState.preMood?.value, 3);
    expect(workoutFlowState.preMood?.value, 3);
    expect(workoutFlowState.currentStep, WorkoutFlowStep.workoutTypeSelection);
    expect(selectedCallbacks, 1);
    expect(find.text('How are you feeling?'), findsNothing);
  });

  testWidgets('post-workout mood auto-select defaults to pre-workout mood', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(moodTrackingProvider.notifier).selectPreMood(4);
    var selectedCallbacks = 0;

    await tester.pumpWidget(
      _harness(
        container,
        QuickMoodCheckBottomSheet(
          isPostWorkout: true,
          onMoodSelected: () => selectedCallbacks++,
        ),
      ),
    );

    await tester.tap(find.text('Open mood sheet'));
    await _pumpFrames(tester);

    expect(find.text('Auto-selecting in 15 seconds'), findsOneWidget);

    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();

    final moodState = container.read(moodTrackingProvider);

    expect(moodState.preMood?.value, 4);
    expect(moodState.postMood?.value, 4);
    expect(moodState.moodChange, 0);
    expect(selectedCallbacks, 1);
    expect(find.text('How do you feel now?'), findsNothing);
  });
}

Widget _harness(ProviderContainer container, Widget sheet) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => sheet,
                );
              },
              child: const Text('Open mood sheet'),
            );
          },
        ),
      ),
    ),
  );
}

Future<void> _pumpFrames(WidgetTester tester, [int frameCount = 4]) async {
  for (var i = 0; i < frameCount; i++) {
    await tester.pump(const Duration(milliseconds: 75));
  }
}
