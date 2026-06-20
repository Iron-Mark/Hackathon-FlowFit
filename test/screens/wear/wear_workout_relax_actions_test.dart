import 'package:flowfit/screens/wear/relax_screen.dart';
import 'package:flowfit/screens/wear/workout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wear_plus/wear_plus.dart';

void main() {
  group('Wear relax actions', () {
    testWidgets('start and pause controls run a local breathing session', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RelaxScreen(shape: WearShape.round, mode: WearMode.active),
        ),
      );

      expect(find.text('Tap to start'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);

      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Guided breathing'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('00:02'), findsOneWidget);

      await tester.tap(find.text('Pause'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Tap to start'), findsOneWidget);
      expect(find.text('00:02'), findsOneWidget);
    });
  });

  group('Wear workout actions', () {
    testWidgets('start and stop controls update workout metrics locally', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutScreen(shape: WearShape.round, mode: WearMode.active),
        ),
      );

      expect(find.text('Start'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('72'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(seconds: 11));

      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('00:11'), findsOneWidget);
      expect(find.text('99'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('Stop'));
      await tester.pump();

      expect(find.text('Start'), findsOneWidget);
      expect(find.text('72'), findsOneWidget);
      expect(find.text('00:11'), findsOneWidget);
    });
  });
}
