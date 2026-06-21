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

    testWidgets('add food action ignores duplicate dialog requests', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HealthScreen()));

      final addFoodButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Add Food'),
      );

      addFoodButton.onPressed!();
      addFoodButton.onPressed!();
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Add Food'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('add food dialog ignores duplicate submits', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HealthScreen()));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Food'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Food Name'),
        'Greek Yogurt',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Calories'), '120');

      final addButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Add'),
      );

      addButton.onPressed!();
      addButton.onPressed!();
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Greek Yogurt'), findsOneWidget);
      expect(find.text('120 kcal'), findsOneWidget);
      expect(find.text('1715/2000 kcal'), findsOneWidget);
    });

    testWidgets('meal tabs switch the active meal before adding food', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HealthScreen()));

      expect(find.text('Oatmeal with Berries'), findsOneWidget);
      expect(find.text('Grilled Chicken Salad'), findsNothing);

      await tester.tap(find.text('Lunch'));
      await tester.pumpAndSettle();

      expect(find.text('Oatmeal with Berries'), findsNothing);
      expect(find.text('Grilled Chicken Salad'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Food'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Food Name'),
        'Lentil Soup',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Calories'), '300');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('Lentil Soup'), findsOneWidget);
      expect(find.text('1895/2000 kcal'), findsOneWidget);

      await tester.tap(find.text('Breakfast'));
      await tester.pumpAndSettle();

      expect(find.text('Lentil Soup'), findsNothing);
      expect(find.text('Oatmeal with Berries'), findsOneWidget);
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

    testWidgets('hydration controls decrement, increment, and clamp values', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HealthScreen()));

      expect(find.text('1.5 / 2.0 L'), findsOneWidget);

      await tester.ensureVisible(find.text('-'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.text('-'));
        await tester.pump();
      }
      expect(find.text('0.0 / 2.0 L'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);

      for (var i = 0; i < 20; i++) {
        await tester.tap(find.text('+'));
        await tester.pump();
      }
      expect(find.text('4.0 / 2.0 L'), findsOneWidget);
      expect(find.text('200%'), findsOneWidget);
    });

    testWidgets('add food dialog ignores empty submit and supports cancel', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HealthScreen()));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Food'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Add Food'), findsWidgets);
      expect(find.text('1595/2000 kcal'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('1595/2000 kcal'), findsOneWidget);
    });

    testWidgets('sleep edit action opens and closes the sleep dialog', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HealthScreen()));

      final editButton = find.widgetWithText(TextButton, 'Edit');
      await tester.ensureVisible(editButton);
      await tester.pumpAndSettle();

      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Edit Sleep Schedule'), findsOneWidget);
      expect(find.text('Bed Time'), findsOneWidget);
      expect(find.text('Wake Up Time'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Sleep Schedule'), findsNothing);
    });

    testWidgets('sleep edit action ignores duplicate dialog requests', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HealthScreen()));

      final editButtonFinder = find.widgetWithText(TextButton, 'Edit');
      await tester.ensureVisible(editButtonFinder);
      await tester.pumpAndSettle();

      final editButton = tester.widget<TextButton>(editButtonFinder);

      editButton.onPressed!();
      editButton.onPressed!();
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Edit Sleep Schedule'), findsOneWidget);
    });

    testWidgets('sleep edit action saves selected bed and wake times', (
      tester,
    ) async {
      final pickedTimes = <TimeOfDay>[
        const TimeOfDay(hour: 23, minute: 0),
        const TimeOfDay(hour: 7, minute: 15),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: HealthScreen(
            pickTime: (_, __) async => pickedTimes.removeAt(0),
          ),
        ),
      );

      expect(find.text('Total sleep: 7h 30m'), findsOneWidget);

      final editButton = find.widgetWithText(TextButton, 'Edit');
      await tester.ensureVisible(editButton);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bed Time'));
      await tester.pumpAndSettle();
      expect(find.text('11:00 PM'), findsOneWidget);

      await tester.tap(find.text('Wake Up Time'));
      await tester.pumpAndSettle();
      expect(find.text('7:15 AM'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Sleep Schedule'), findsNothing);
      expect(find.text('Total sleep: 8h 15m'), findsOneWidget);
      expect(find.text('11:00 PM'), findsOneWidget);
      expect(find.text('7:15 AM'), findsOneWidget);
    });
  });
}
