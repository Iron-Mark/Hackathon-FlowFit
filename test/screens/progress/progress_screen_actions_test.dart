import 'package:flowfit/screens/progress/progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProgressScreen actions', () {
    testWidgets('week and month toggle updates the selected segment', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ProgressScreen()));

      expect(_toggleColor(tester, 'Week'), isNot(Colors.transparent));
      expect(_toggleColor(tester, 'Month'), Colors.transparent);

      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      expect(_toggleColor(tester, 'Week'), Colors.transparent);
      expect(_toggleColor(tester, 'Month'), isNot(Colors.transparent));

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      expect(_toggleColor(tester, 'Week'), isNot(Colors.transparent));
      expect(_toggleColor(tester, 'Month'), Colors.transparent);
    });

    testWidgets('sleep details button opens the details sheet', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProgressScreen()));

      await tester.scrollUntilVisible(find.text('View Details'), 300);
      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();

      expect(find.text('Sleep Details'), findsOneWidget);
      expect(find.text('Average duration: 7h 32m'), findsOneWidget);
      expect(find.text('Deep sleep'), findsOneWidget);
      expect(find.text('REM sleep'), findsOneWidget);
    });
  });
}

Color? _toggleColor(WidgetTester tester, String label) {
  final text = find.text(label);
  final container = find.ancestor(of: text, matching: find.byType(Container));
  return tester.widget<Container>(container.first).decoration is BoxDecoration
      ? (tester.widget<Container>(container.first).decoration! as BoxDecoration)
            .color
      : null;
}
