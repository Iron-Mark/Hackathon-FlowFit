import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/screens/home/widgets/cta_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('CTASection', () {
    String? lastNavigatedRoute;

    setUp(() {
      lastNavigatedRoute = null;
    });

    Widget buildHarness({ThemeData? theme}) {
      return ProviderScope(
        child: MaterialApp(
          theme: theme,
          home: const Scaffold(body: CTASection()),
          routes: {
            '/workout/select-type': (context) {
              lastNavigatedRoute = '/workout/select-type';
              return const Scaffold(body: Text('Workout Type Selection'));
            },
            '/wellness-tracker': (context) {
              lastNavigatedRoute = '/wellness-tracker';
              return const Scaffold(body: Text('Wellness Tracker Screen'));
            },
            '/mission': (context) {
              lastNavigatedRoute = '/mission';
              return const Scaffold(body: Text('Mission Screen'));
            },
          },
        ),
      );
    }

    testWidgets('displays section header', (WidgetTester tester) async {
      await tester.pumpWidget(buildHarness());

      expect(find.text('Ready to move?'), findsOneWidget);
    });

    testWidgets('displays all three buttons without test copy', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHarness());

      expect(find.text('START WORKOUT'), findsOneWidget);
      expect(find.text('Wellness Tracker'), findsOneWidget);
      expect(find.text('Map Missions'), findsOneWidget);
      expect(find.textContaining('OLD'), findsNothing);
      expect(find.textContaining('Test'), findsNothing);
    });

    testWidgets('START WORKOUT button is ElevatedButton', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHarness());

      final startWorkoutButton = find.ancestor(
        of: find.text('START WORKOUT'),
        matching: find.byType(ElevatedButton),
      );
      expect(startWorkoutButton, findsOneWidget);
    });

    testWidgets('Wellness Tracker button is OutlinedButton', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHarness());

      final wellnessTrackerButton = find.ancestor(
        of: find.text('Wellness Tracker'),
        matching: find.byType(OutlinedButton),
      );
      expect(wellnessTrackerButton, findsOneWidget);
    });

    testWidgets('Map Missions button is OutlinedButton', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHarness());

      final missionButton = find.ancestor(
        of: find.text('Map Missions'),
        matching: find.byType(OutlinedButton),
      );
      expect(missionButton, findsOneWidget);
    });

    testWidgets('buttons use configured heights', (WidgetTester tester) async {
      await tester.pumpWidget(buildHarness());

      // Find all SizedBox widgets that wrap the buttons
      final sizedBoxes = tester.widgetList<SizedBox>(
        find.descendant(
          of: find.byType(CTASection),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBoxes.where((box) => box.height == 56).length, 1);
      expect(sizedBoxes.where((box) => box.height == 48).length, 2);
    });

    testWidgets('START WORKOUT opens mood check before workout selection', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHarness());

      await tester.tap(find.text('START WORKOUT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('How are you feeling?'), findsOneWidget);
      expect(lastNavigatedRoute, isNull);
    });

    testWidgets('mood selection navigates to workout type selection', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHarness());

      await tester.tap(find.text('START WORKOUT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Good'));
      await tester.pumpAndSettle();

      expect(lastNavigatedRoute, '/workout/select-type');
    });

    testWidgets('Wellness Tracker navigates to /wellness-tracker', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHarness());

      await tester.tap(find.text('Wellness Tracker'));
      await tester.pumpAndSettle();

      expect(lastNavigatedRoute, '/wellness-tracker');
    });

    testWidgets('Map Missions navigates to /mission', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHarness());

      await tester.tap(find.text('Map Missions'));
      await tester.pumpAndSettle();

      expect(lastNavigatedRoute, '/mission');
    });

    testWidgets('uses theme colors correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildHarness(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          ),
        ),
      );

      // Find the ElevatedButton
      final elevatedButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('START WORKOUT'),
          matching: find.byType(ElevatedButton),
        ),
      );

      final buttonStyle = elevatedButton.style;
      expect(
        buttonStyle?.backgroundColor?.resolve({}),
        const Color(0xFF3B82F6),
      );
      expect(buttonStyle?.foregroundColor?.resolve({}), Colors.white);
    });

    testWidgets('buttons have configured border radius', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHarness());

      // Check ElevatedButton border radius
      final elevatedButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('START WORKOUT'),
          matching: find.byType(ElevatedButton),
        ),
      );
      final elevatedShape =
          elevatedButton.style?.shape?.resolve({}) as RoundedRectangleBorder;
      expect(elevatedShape.borderRadius, BorderRadius.circular(16));

      // Check OutlinedButton border radius
      final outlinedButton = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Wellness Tracker'),
          matching: find.byType(OutlinedButton),
        ),
      );
      final outlinedShape =
          outlinedButton.style?.shape?.resolve({}) as RoundedRectangleBorder;
      expect(outlinedShape.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('section header uses titleLarge with bold weight', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(
          theme: ThemeData(
            textTheme: const TextTheme(titleLarge: TextStyle(fontSize: 22)),
          ),
        ),
      );

      final headerText = tester.widget<Text>(find.text('Ready to move?'));
      expect(headerText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('buttons are full width', (WidgetTester tester) async {
      await tester.pumpWidget(buildHarness());

      // Find all SizedBox widgets that wrap the buttons
      final sizedBoxes = tester.widgetList<SizedBox>(
        find.descendant(
          of: find.byType(CTASection),
          matching: find.byType(SizedBox),
        ),
      );

      // Filter for the full-width button containers.
      final buttonContainers = sizedBoxes.where(
        (box) =>
            box.width == double.infinity &&
            (box.height == 56 || box.height == 48),
      );
      expect(buttonContainers.length, 3);
    });
  });
}
