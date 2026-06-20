import 'package:flowfit/screens/mood_tracking_demo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pre-workout mood demo button opens and dismisses mood sheet', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Show Pre-Workout Mood Check'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('How are you feeling?'), findsOneWidget);
    expect(find.text('Auto-selecting in 10 seconds'), findsOneWidget);

    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();

    expect(find.text('How are you feeling?'), findsNothing);
  });

  testWidgets(
    'post-workout bottom sheet demo opens the post-workout mood sheet',
    (tester) async {
      await tester.pumpWidget(_harness());

      await tester.tap(
        find.widgetWithText(
          ElevatedButton,
          'Show Post-Workout Mood Check (Bottom Sheet)',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('How do you feel now?'), findsOneWidget);
      expect(find.text('Auto-selecting in 15 seconds'), findsOneWidget);

      await tester.tap(find.text('Neutral'));
      await tester.pumpAndSettle();

      expect(find.text('How do you feel now?'), findsNothing);
    },
  );

  testWidgets(
    'post-workout screen demo pushes and returns from full-screen mood check',
    (tester) async {
      await tester.pumpWidget(_harness());

      final button = find.widgetWithText(
        ElevatedButton,
        'Show Post-Workout Screen',
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('How do you feel now?'), findsOneWidget);

      await tester.tap(find.text('Neutral'));
      await tester.pumpAndSettle();

      expect(find.text('Mood Tracking Components Demo'), findsOneWidget);
    },
  );
}

Widget _harness() {
  return const ProviderScope(
    child: MaterialApp(home: MoodTrackingDemoScreen()),
  );
}
