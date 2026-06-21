import 'dart:convert';

import 'package:flowfit/screens/profile/settings/general/language_settings_screen.dart';
import 'package:flowfit/screens/profile/settings/general/notification_settings_screen.dart';
import 'package:flowfit/screens/profile/settings/general/unit_settings_screen.dart';
import 'package:flowfit/services/user_settings_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('language settings persist selected language', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(const MaterialApp(home: LanguageSettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spanish'));
    await tester.pumpAndSettle();

    expect(await UserSettingsPreferences(prefs).loadLanguage(), 'Spanish');
  });

  testWidgets('language settings load saved selection and back button pops', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await UserSettingsPreferences(prefs).saveLanguage('Japanese');

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/language',
        routes: {
          '/': (_) => const Scaffold(body: Text('route:settings')),
          '/language': (_) => const LanguageSettingsScreen(),
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Japanese'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Japanese'),
          matching: find.byType(ListTile),
        ),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('route:settings'), findsOneWidget);
  });

  testWidgets(
    'unit settings persist measurement system and unit picker changes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(const MaterialApp(home: UnitSettingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Imperial'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Distance'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(RadioListTile<String>, 'Kilometers'),
      );
      await tester.pumpAndSettle();

      final loaded = await UserSettingsPreferences(prefs).loadUnitSettings();
      expect(loaded.measurementSystem, 'Imperial');
      expect(loaded.distanceUnit, 'Kilometers');
      expect(loaded.weightUnit, 'Pounds');
    },
  );

  testWidgets('unit settings persist all individual unit picker changes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(const MaterialApp(home: UnitSettingsScreen()));
    await tester.pumpAndSettle();

    await _selectUnit(tester, label: 'Weight', option: 'Pounds');
    await _selectUnit(tester, label: 'Height', option: 'Feet/Inches');
    await _selectUnit(tester, label: 'Temperature', option: 'Fahrenheit');

    final loaded = await UserSettingsPreferences(prefs).loadUnitSettings();
    expect(loaded.weightUnit, 'Pounds');
    expect(loaded.heightUnit, 'Feet/Inches');
    expect(loaded.temperatureUnit, 'Fahrenheit');
  });

  testWidgets('unit settings sanitize unsupported saved values on load', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      UserSettingsPreferences.unitSettingsKey: jsonEncode({
        'measurementSystem': 'Customary',
        'distanceUnit': 'Parsecs',
        'weightUnit': 'Stones',
        'heightUnit': 'Hands',
        'temperatureUnit': 'Kelvin',
      }),
    });

    await tester.pumpWidget(const MaterialApp(home: UnitSettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Customary'), findsNothing);
    expect(find.text('Parsecs'), findsNothing);
    expect(find.text('Stones'), findsNothing);
    expect(find.text('Hands'), findsNothing);
    expect(find.text('Kelvin'), findsNothing);
    expect(find.text('Metric'), findsOneWidget);
    expect(find.text('Kilometers'), findsOneWidget);
    expect(find.text('Kilograms'), findsOneWidget);
    expect(find.text('Centimeters'), findsOneWidget);
    expect(find.text('Celsius'), findsOneWidget);
  });

  testWidgets('notification settings persist changed switches', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      const MaterialApp(home: NotificationSettingsScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).at(2));
    await tester.pumpAndSettle();

    final loaded = await UserSettingsPreferences(
      prefs,
    ).loadNotificationSettings();
    expect(loaded.waterReminders, isTrue);
  });

  testWidgets('notification settings persist every switch action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      const MaterialApp(home: NotificationSettingsScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).at(3));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Weekly Reports'));
    await tester.tap(find.byType(Switch).at(4));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).at(5));
    await tester.pumpAndSettle();

    final loaded = await UserSettingsPreferences(
      prefs,
    ).loadNotificationSettings();
    expect(loaded.workoutReminders, isFalse);
    expect(loaded.mealReminders, isFalse);
    expect(loaded.waterReminders, isTrue);
    expect(loaded.sleepReminders, isFalse);
    expect(loaded.achievementNotifications, isFalse);
    expect(loaded.weeklyReports, isTrue);
  });

  testWidgets('unit and notification back buttons pop to settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      _settingsBackHarness(route: '/unit', child: const UnitSettingsScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('route:settings'), findsOneWidget);

    await tester.pumpWidget(
      _settingsBackHarness(
        route: '/notification',
        child: const NotificationSettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('route:settings'), findsOneWidget);
  });
}

Widget _settingsBackHarness({required String route, required Widget child}) {
  return MaterialApp(
    key: UniqueKey(),
    initialRoute: route,
    routes: {
      '/': (_) => const Scaffold(body: Text('route:settings')),
      route: (_) => child,
    },
  );
}

Future<void> _selectUnit(
  WidgetTester tester, {
  required String label,
  required String option,
}) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(RadioListTile<String>, option));
  await tester.pumpAndSettle();
}
