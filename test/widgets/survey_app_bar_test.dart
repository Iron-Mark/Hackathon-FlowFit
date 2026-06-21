import 'package:flowfit/widgets/survey_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('survey app bar wires custom back action and progress text', (
    tester,
  ) async {
    var backCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: SurveyAppBar(
            currentStep: 2,
            totalSteps: 4,
            title: 'Profile Setup',
            onBack: () => backCalls++,
          ),
          body: const Text('Survey body'),
        ),
      ),
    );

    expect(find.text('Profile Setup'), findsOneWidget);
    expect(find.text('2/4'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    expect(backCalls, 1);
  });

  testWidgets('survey app bar hides back and progress when configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: SurveyAppBar(
            currentStep: 0,
            totalSteps: 4,
            showProgressText: false,
          ),
          body: Text('First step'),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.text('0/4'), findsNothing);
  });

  testWidgets('survey progress indicator renders one segment per step', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SurveyProgressIndicator(currentStep: 2, totalSteps: 4),
        ),
      ),
    );

    expect(find.byType(SurveyProgressIndicator), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SurveyProgressIndicator),
        matching: find.byType(Expanded),
      ),
      findsNWidgets(8),
    );
  });
}
