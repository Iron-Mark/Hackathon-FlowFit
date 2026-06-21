import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/screens/home/home_screen.dart';

void main() {
  group('HomeScreen actions', () {
    testWidgets('Start AI Workout opens the activity classifier route', (
      tester,
    ) async {
      final visitedRoutes = <String>[];

      await tester.pumpWidget(
        _homeHarness(
          visitedRoutes: visitedRoutes,
          routes: {
            '/activity-classifier': (_) =>
                const Scaffold(body: Text('route:activity-classifier')),
          },
        ),
      );

      await _scrollHomeUntilVisible(tester, 'Start AI Workout');
      await tester.tap(find.text('Start AI Workout'));
      await tester.pumpAndSettle();

      expect(visitedRoutes, contains('/activity-classifier'));
      expect(find.text('route:activity-classifier'), findsOneWidget);
    });

    testWidgets('Drink Water and Log Meal use injected callbacks', (
      tester,
    ) async {
      var waterLogs = 0;
      var mealLogs = 0;

      await tester.pumpWidget(
        _homeHarness(
          onLogWater: () => waterLogs++,
          onLogMeal: () => mealLogs++,
        ),
      );

      await _scrollHomeUntilVisible(tester, 'Drink Water');
      await tester.tap(find.text('Drink Water'));
      await tester.tap(find.text('Log Meal'));
      await tester.pump();

      expect(waterLogs, 1);
      expect(mealLogs, 1);
    });

    testWidgets('Track Steps opens map missions', (tester) async {
      final visitedRoutes = <String>[];

      await tester.pumpWidget(
        _homeHarness(
          visitedRoutes: visitedRoutes,
          routes: {
            '/mission': (_) => const Scaffold(body: Text('route:mission')),
          },
        ),
      );

      await _scrollHomeUntilVisible(tester, 'Track Steps');
      await tester.tap(find.text('Track Steps'));
      await tester.pumpAndSettle();

      expect(visitedRoutes, contains('/mission'));
      expect(find.text('route:mission'), findsOneWidget);
    });

    testWidgets('Heart Check opens phone heart-rate route', (tester) async {
      final visitedRoutes = <String>[];

      await tester.pumpWidget(
        _homeHarness(
          visitedRoutes: visitedRoutes,
          routes: {
            '/phone_heart_rate': (_) =>
                const Scaffold(body: Text('route:phone-heart-rate')),
          },
        ),
      );

      await _scrollHomeUntilVisible(tester, 'Heart Check');
      await tester.tap(find.text('Heart Check'));
      await tester.pumpAndSettle();

      expect(visitedRoutes, contains('/phone_heart_rate'));
      expect(find.text('route:phone-heart-rate'), findsOneWidget);
    });
  });

  testWidgets('Home shows Galaxy Watch waiting state when watch disconnected', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Heart Rate'), findsOneWidget);
    expect(find.text('— BPM'), findsOneWidget);
    expect(find.text('Waiting for Galaxy Watch...'), findsOneWidget);
  });
}

Widget _homeHarness({
  VoidCallback? onLogWater,
  VoidCallback? onLogMeal,
  List<String>? visitedRoutes,
  Map<String, WidgetBuilder> routes = const {},
}) {
  return MaterialApp(
    home: HomeScreen(onLogWater: onLogWater, onLogMeal: onLogMeal),
    routes: routes.map(
      (name, builder) => MapEntry(name, (context) {
        visitedRoutes?.add(name);
        return builder(context);
      }),
    ),
  );
}

Future<void> _scrollHomeUntilVisible(WidgetTester tester, String label) {
  return tester.scrollUntilVisible(
    find.text(label),
    300,
    scrollable: find
        .descendant(
          of: find.byType(HomeScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
}
