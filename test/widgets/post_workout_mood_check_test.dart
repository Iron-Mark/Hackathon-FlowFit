import 'package:flowfit/providers/mood_tracking_provider.dart';
import 'package:flowfit/widgets/post_workout_mood_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('manual post-workout mood selection records mood change', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(moodTrackingProvider.notifier).selectPreMood(2);
    var completeCalls = 0;

    await tester.pumpWidget(
      _harness(
        container,
        PostWorkoutMoodCheck(
          sessionId: 'session-1',
          onComplete: () => completeCalls++,
        ),
      ),
    );

    expect(find.text('How do you feel now?'), findsOneWidget);
    expect(find.text('You started feeling: 😕'), findsOneWidget);

    await tester.tap(find.text('Energized'));
    await tester.pumpAndSettle();

    final moodState = container.read(moodTrackingProvider);

    expect(moodState.preMood?.value, 2);
    expect(moodState.postMood?.value, 5);
    expect(moodState.moodChange, 3);
    expect(completeCalls, 1);
  });

  testWidgets('post-workout mood auto-select defaults to pre-workout mood', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(moodTrackingProvider.notifier).selectPreMood(4);
    var completeCalls = 0;

    await tester.pumpWidget(
      _harness(
        container,
        PostWorkoutMoodCheck(
          sessionId: 'session-2',
          onComplete: () => completeCalls++,
        ),
      ),
    );

    expect(find.text('Auto-selecting in 15 seconds'), findsOneWidget);

    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();

    final moodState = container.read(moodTrackingProvider);

    expect(moodState.preMood?.value, 4);
    expect(moodState.postMood?.value, 4);
    expect(moodState.moodChange, 0);
    expect(completeCalls, 1);
  });
}

Widget _harness(ProviderContainer container, Widget child) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: child),
  );
}
