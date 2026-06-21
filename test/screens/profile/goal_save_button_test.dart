import 'package:flowfit/screens/profile/goals/widgets/goal_save_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GoalSaveButton invokes save action when enabled', (
    tester,
  ) async {
    var saveCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoalSaveButton(isLoading: false, onPressed: () => saveCalls++),
        ),
      ),
    );

    expect(find.text('Save Goals'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Goals'));
    await tester.pump();

    expect(saveCalls, 1);
  });

  testWidgets(
    'GoalSaveButton disables action and shows progress while saving',
    (tester) async {
      var saveCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalSaveButton(isLoading: true, onPressed: () => saveCalls++),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save Goals'), findsNothing);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      expect(saveCalls, 0);
    },
  );
}
