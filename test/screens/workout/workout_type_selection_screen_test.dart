import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/screens/workout/workout_type_selection_screen.dart';
import 'package:flowfit/models/workout_session.dart';

void main() {
  group('WorkoutTypeSelectionScreen', () {
    Widget buildNavigationHarness() {
      return ProviderScope(
        child: MaterialApp(
          home: const WorkoutTypeSelectionScreen(),
          routes: {
            '/workout/running/setup': (_) =>
                const Scaffold(body: Text('route:running')),
            '/workout/walking/options': (_) =>
                const Scaffold(body: Text('route:walking')),
            '/workout/resistance/select-split': (_) =>
                const Scaffold(body: Text('route:resistance')),
          },
        ),
      );
    }

    testWidgets('displays header with correct text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: WorkoutTypeSelectionScreen()),
        ),
      );

      expect(find.text('Choose Your Workout'), findsOneWidget);
    });

    testWidgets('displays all three workout type cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: WorkoutTypeSelectionScreen()),
        ),
      );

      // Verify all three workout types are displayed
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('Resistance Training'), findsOneWidget);
    });

    testWidgets('displays estimated duration and calories for each card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: WorkoutTypeSelectionScreen()),
        ),
      );

      // Verify metrics are displayed
      expect(find.textContaining('min'), findsAtLeastNWidgets(3));
      expect(find.textContaining('cal'), findsAtLeastNWidgets(3));
    });

    testWidgets('displays benefits text for each card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: WorkoutTypeSelectionScreen()),
        ),
      );

      // Verify benefits are displayed
      expect(
        find.text('Improve cardiovascular health and endurance'),
        findsOneWidget,
      );
      expect(
        find.text('Low-impact exercise for daily movement'),
        findsOneWidget,
      );
      expect(find.text('Build strength and muscle definition'), findsOneWidget);
    });

    testWidgets('WorkoutTypeCard has correct styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutTypeCard(
              type: WorkoutType.running,
              icon: Icons.directions_run,
              gradient: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
              estimatedDuration: '45-60 min',
              estimatedCalories: '400 cal',
              benefits: 'Test benefits',
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the container with gradient
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(WorkoutTypeCard),
              matching: find.byType(Container),
            )
            .first,
      );

      // Verify border radius is 16px
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(16));

      // Verify gradient is applied
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('Running card opens running setup route', (tester) async {
      await tester.pumpWidget(buildNavigationHarness());

      await tester.tap(find.text('Running'));
      await tester.pumpAndSettle();

      expect(find.text('route:running'), findsOneWidget);
    });

    testWidgets('Walking card opens walking options route', (tester) async {
      await tester.pumpWidget(buildNavigationHarness());

      await tester.tap(find.text('Walking'));
      await tester.pumpAndSettle();

      expect(find.text('route:walking'), findsOneWidget);
    });

    testWidgets('Resistance card opens split selection route', (tester) async {
      await tester.pumpWidget(buildNavigationHarness());

      await tester.ensureVisible(find.text('Resistance Training'));
      await tester.tap(find.text('Resistance Training'));
      await tester.pumpAndSettle();

      expect(find.text('route:resistance'), findsOneWidget);
    });
  });
}
