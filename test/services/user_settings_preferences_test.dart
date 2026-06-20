import 'package:flowfit/services/user_settings_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('UserSettingsPreferences', () {
    test('saves and loads selected language', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = UserSettingsPreferences(prefs);

      await store.saveLanguage('Spanish');

      expect(await store.loadLanguage(), 'Spanish');
    });

    test('saves and loads unit settings', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = UserSettingsPreferences(prefs);

      await store.saveUnitSettings(
        const UnitPreferenceSettings(
          measurementSystem: 'Imperial',
          distanceUnit: 'Miles',
          weightUnit: 'Pounds',
          heightUnit: 'Feet/Inches',
          temperatureUnit: 'Fahrenheit',
        ),
      );

      final loaded = await store.loadUnitSettings();
      expect(loaded.measurementSystem, 'Imperial');
      expect(loaded.distanceUnit, 'Miles');
      expect(loaded.weightUnit, 'Pounds');
      expect(loaded.heightUnit, 'Feet/Inches');
      expect(loaded.temperatureUnit, 'Fahrenheit');
    });

    test('saves and loads notification settings', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = UserSettingsPreferences(prefs);

      await store.saveNotificationSettings(
        const NotificationPreferenceSettings(
          workoutReminders: false,
          mealReminders: false,
          waterReminders: true,
          sleepReminders: false,
          achievementNotifications: false,
          weeklyReports: true,
        ),
      );

      final loaded = await store.loadNotificationSettings();
      expect(loaded.workoutReminders, isFalse);
      expect(loaded.mealReminders, isFalse);
      expect(loaded.waterReminders, isTrue);
      expect(loaded.sleepReminders, isFalse);
      expect(loaded.achievementNotifications, isFalse);
      expect(loaded.weeklyReports, isTrue);
    });

    test(
      'falls back to defaults for missing or corrupt saved values',
      () async {
        SharedPreferences.setMockInitialValues({
          UserSettingsPreferences.languageKey: '',
          UserSettingsPreferences.unitSettingsKey: '{bad json',
          UserSettingsPreferences.notificationSettingsKey: '[]',
        });
        final prefs = await SharedPreferences.getInstance();
        final store = UserSettingsPreferences(prefs);

        final units = await store.loadUnitSettings();
        final notifications = await store.loadNotificationSettings();

        expect(await store.loadLanguage(), 'English');
        expect(units.measurementSystem, 'Metric');
        expect(units.distanceUnit, 'Kilometers');
        expect(notifications.workoutReminders, isTrue);
        expect(notifications.waterReminders, isFalse);
      },
    );
  });
}
