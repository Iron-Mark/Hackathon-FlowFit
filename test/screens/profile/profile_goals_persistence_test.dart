import 'package:flowfit/screens/profile/goals/fitness_goals_screen.dart';
import 'package:flowfit/screens/profile/goals/nutrition_goals_screen.dart';
import 'package:flowfit/screens/profile/goals/weight_goals_screen.dart';
import 'package:flowfit/services/profile_goal_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('weight goals save button persists edited values', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(const MaterialApp(home: WeightGoalsScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter current weight'),
      '155',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter goal weight'),
      '145',
    );
    await tester.ensureVisible(find.text('Save Goals'));
    await tester.tap(find.text('Save Goals'));
    await tester.pumpAndSettle();

    final loaded = await ProfileGoalPreferences(prefs).loadWeightGoals();
    expect(loaded.currentWeight, '155');
    expect(loaded.goalWeight, '145');
  });

  testWidgets('weight goal summary updates live and persists weekly target', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(const MaterialApp(home: WeightGoalsScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter current weight'),
      '155.5',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter goal weight'),
      '142',
    );
    await tester.pumpAndSettle();

    expect(find.text('155.5 lbs'), findsOneWidget);
    expect(find.text('142 lbs'), findsOneWidget);
    expect(find.text('13.5 lbs'), findsOneWidget);

    await tester.ensureVisible(find.text('2 lb/week'));
    await tester.tap(find.text('2 lb/week'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Goals'));
    await tester.tap(find.text('Save Goals'));
    await tester.pumpAndSettle();

    final loaded = await ProfileGoalPreferences(prefs).loadWeightGoals();
    expect(loaded.weeklyGoal, '2 lb/week');
  });

  testWidgets('weight goals validation blocks invalid save', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(const MaterialApp(home: WeightGoalsScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter current weight'),
      'not-a-number',
    );
    await tester.ensureVisible(find.text('Save Goals'));
    await tester.tap(find.text('Save Goals'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid current weight'), findsOneWidget);
    expect(prefs.getString(ProfileGoalPreferences.weightGoalsKey), isNull);
  });

  testWidgets('fitness goals save button persists selected plan', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(const MaterialApp(home: FitnessGoalsScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Improve Endurance'));
    await tester.tap(find.text('Improve Endurance'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Goals'));
    await tester.tap(find.text('Save Goals'));
    await tester.pumpAndSettle();

    final loaded = await ProfileGoalPreferences(prefs).loadFitnessGoals();
    expect(loaded.goals, contains('Improve Endurance'));
  });

  testWidgets('fitness goals controls persist dropdown, sliders, and toggles', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(const MaterialApp(home: FitnessGoalsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Active').last);
    await tester.pumpAndSettle();

    tester.widget<Slider>(find.byType(Slider).at(0)).onChanged!(6);
    await tester.pumpAndSettle();
    tester.widget<Slider>(find.byType(Slider).at(1)).onChanged!(60);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Weight Loss'));
    await tester.tap(find.text('Weight Loss'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Increase Flexibility'));
    await tester.tap(find.text('Increase Flexibility'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save Goals'));
    await tester.tap(find.text('Save Goals'));
    await tester.pumpAndSettle();

    final loaded = await ProfileGoalPreferences(prefs).loadFitnessGoals();
    expect(loaded.activityLevel, 'Active');
    expect(loaded.workoutsPerWeek, 6);
    expect(loaded.minutesPerWorkout, 60);
    expect(loaded.goals, isNot(contains('Weight Loss')));
    expect(loaded.goals, contains('Increase Flexibility'));
  });

  testWidgets('nutrition goals save button persists custom macros', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(const MaterialApp(home: NutritionGoalsScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter daily calories'),
      '2100',
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter protein goal'),
      '160',
    );
    await tester.ensureVisible(find.text('Save Goals'));
    await tester.tap(find.text('Save Goals'));
    await tester.pumpAndSettle();

    final loaded = await ProfileGoalPreferences(prefs).loadNutritionGoals();
    expect(loaded.calories, '2100');
    expect(loaded.protein, '160');
    expect(loaded.useCustomMacros, isTrue);
  });

  testWidgets(
    'nutrition summary updates live and validation blocks bad macros',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(const MaterialApp(home: NutritionGoalsScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter daily calories'),
        '2300',
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter protein goal'),
        'bad',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter carbs goal'),
        '250',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter fats goal'),
        '70',
      );
      await tester.pumpAndSettle();

      expect(find.text('Calories: 2300 kcal'), findsOneWidget);
      expect(
        find.text('Protein: badg | Carbs: 250g | Fats: 70g'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Save Goals'));
      await tester.tap(find.text('Save Goals'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid protein goal'), findsOneWidget);
      expect(prefs.getString(ProfileGoalPreferences.nutritionGoalsKey), isNull);
    },
  );

  testWidgets('goal editor back buttons pop to profile', (tester) async {
    await _expectBackPops(
      tester,
      route: '/weight',
      child: const WeightGoalsScreen(),
    );
    await _expectBackPops(
      tester,
      route: '/fitness',
      child: const FitnessGoalsScreen(),
    );
    await _expectBackPops(
      tester,
      route: '/nutrition',
      child: const NutritionGoalsScreen(),
    );
  });

  testWidgets('successful goal saves pop back to profile', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      _routeHarness(route: '/weight', child: const WeightGoalsScreen()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter current weight'),
      '150',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter goal weight'),
      '140',
    );
    await tester.ensureVisible(find.text('Save Goals'));
    await tester.tap(find.text('Save Goals'));
    await tester.pumpAndSettle();

    expect(find.text('route:profile'), findsOneWidget);
  });

  testWidgets('duplicate goal save callbacks only pop once', (tester) async {
    await _expectDuplicateSavePopsOnce(
      tester,
      route: '/weight',
      child: const WeightGoalsScreen(),
    );
    await _expectDuplicateSavePopsOnce(
      tester,
      route: '/fitness',
      child: const FitnessGoalsScreen(),
    );
    await _expectDuplicateSavePopsOnce(
      tester,
      route: '/nutrition',
      child: const NutritionGoalsScreen(),
    );
  });
}

Future<void> _expectBackPops(
  WidgetTester tester, {
  required String route,
  required Widget child,
}) async {
  SharedPreferences.setMockInitialValues({});

  await tester.pumpWidget(_routeHarness(route: route, child: child));
  await tester.pumpAndSettle();

  await tester.tap(find.byType(IconButton).first);
  await tester.pumpAndSettle();

  expect(find.text('route:profile'), findsOneWidget);
}

Widget _routeHarness({required String route, required Widget child}) {
  return _routeHarnessWithObservers(route: route, child: child);
}

Widget _routeHarnessWithObservers({
  required String route,
  required Widget child,
  List<NavigatorObserver> navigatorObservers = const [],
}) {
  return MaterialApp(
    key: UniqueKey(),
    initialRoute: route,
    navigatorObservers: navigatorObservers,
    routes: {
      '/': (_) => const Scaffold(body: Text('route:profile')),
      route: (_) => child,
    },
  );
}

Future<void> _expectDuplicateSavePopsOnce(
  WidgetTester tester, {
  required String route,
  required Widget child,
}) async {
  SharedPreferences.setMockInitialValues({});
  final observer = _CountingNavigatorObserver();

  await tester.pumpWidget(
    _routeHarnessWithObservers(
      route: route,
      child: child,
      navigatorObservers: [observer],
    ),
  );
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('Save Goals'));
  final button = tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, 'Save Goals'),
  );
  final onPressed = button.onPressed!;

  onPressed();
  onPressed();
  await tester.pumpAndSettle();

  expect(find.text('route:profile'), findsOneWidget);
  expect(observer.popCount, 1);
}

class _CountingNavigatorObserver extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }
}
