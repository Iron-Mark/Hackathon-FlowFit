import 'package:flowfit/widgets/wellness/cardio_detection_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cardio banner exposes only implemented workout quick starts', (
    tester,
  ) async {
    final started = <String>[];
    var dismissCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              CardioDetectionBanner(
                heartRate: 132,
                onStartWorkout: started.add,
                onDismiss: () => dismissCalls++,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Run'), findsOneWidget);
    expect(find.text('Walk'), findsOneWidget);
    expect(find.text('Cycle'), findsNothing);

    await tester.tap(find.text('Run'));
    await tester.pump();
    await tester.tap(find.text('Walk'));
    await tester.pump();

    expect(started, ['running', 'walking']);

    await tester.tap(find.text('No Thanks'));
    await tester.pump();

    expect(dismissCalls, 1);
  });

  testWidgets('cardio banner close button dismisses the prompt', (
    tester,
  ) async {
    var dismissCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              CardioDetectionBanner(
                heartRate: 128,
                onStartWorkout: (_) {},
                onDismiss: () => dismissCalls++,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(dismissCalls, 1);
  });
}
