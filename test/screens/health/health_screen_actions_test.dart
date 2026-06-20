import 'package:flowfit/screens/health/health_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthScreen actions', () {
    testWidgets('initial water action adds a serving to the hydration log', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HealthScreen(initialAction: HealthInitialAction.addWater),
        ),
      );
      await tester.pump();

      expect(find.text('1.8 / 2.0 L'), findsOneWidget);
      expect(
        find.text('Added 250 ml of water to today\'s log.'),
        findsOneWidget,
      );
    });

    testWidgets('initial meal action opens the add food dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HealthScreen(initialAction: HealthInitialAction.addMeal),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Add Food'),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Food Name'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Calories'), findsOneWidget);
    });

    testWidgets('add food dialog adds an item to the selected meal', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HealthScreen()));

      expect(find.text('1595/2000 kcal'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Food'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Food Name'),
        'Greek Yogurt',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Calories'), '120');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('Greek Yogurt'), findsOneWidget);
      expect(find.text('120 kcal'), findsOneWidget);
      expect(find.text('1715/2000 kcal'), findsOneWidget);
    });

    testWidgets('food item action menu removes an item', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HealthScreen()));

      expect(find.text('Oatmeal with Berries'), findsOneWidget);
      expect(find.text('1595/2000 kcal'), findsOneWidget);

      await tester.tap(find.byTooltip('Food actions').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.text('Oatmeal with Berries'), findsNothing);
      expect(find.text('1245/2000 kcal'), findsOneWidget);
      expect(
        find.text('Oatmeal with Berries removed from Breakfast'),
        findsOneWidget,
      );
    });

    testWidgets('date navigation keeps food and hydration logs per day', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HealthScreen()));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Food'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Food Name'),
        'Greek Yogurt',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Calories'), '120');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('+'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+'));
      await tester.pump();

      expect(find.text('Greek Yogurt'), findsOneWidget);
      expect(find.text('1715/2000 kcal'), findsOneWidget);
      expect(find.text('1.8 / 2.0 L'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_forward_ios));
      await tester.pumpAndSettle();

      expect(find.text('Greek Yogurt'), findsNothing);
      expect(find.text('0/2000 kcal'), findsOneWidget);
      expect(find.text('0.0 / 2.0 L'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios));
      await tester.pumpAndSettle();

      expect(find.text('Greek Yogurt'), findsOneWidget);
      expect(find.text('1715/2000 kcal'), findsOneWidget);
      expect(find.text('1.8 / 2.0 L'), findsOneWidget);
    });
  });
}
