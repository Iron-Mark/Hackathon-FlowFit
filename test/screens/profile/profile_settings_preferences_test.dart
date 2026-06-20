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
}
