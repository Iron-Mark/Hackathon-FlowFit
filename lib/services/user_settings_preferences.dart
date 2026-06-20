import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UnitPreferenceSettings {
  const UnitPreferenceSettings({
    required this.measurementSystem,
    required this.distanceUnit,
    required this.weightUnit,
    required this.heightUnit,
    required this.temperatureUnit,
  });

  final String measurementSystem;
  final String distanceUnit;
  final String weightUnit;
  final String heightUnit;
  final String temperatureUnit;

  factory UnitPreferenceSettings.defaults() => const UnitPreferenceSettings(
    measurementSystem: 'Metric',
    distanceUnit: 'Kilometers',
    weightUnit: 'Kilograms',
    heightUnit: 'Centimeters',
    temperatureUnit: 'Celsius',
  );

  factory UnitPreferenceSettings.fromJson(Map<String, dynamic> json) {
    final defaults = UnitPreferenceSettings.defaults();
    return UnitPreferenceSettings(
      measurementSystem: _stringOrDefault(
        json['measurementSystem'],
        defaults.measurementSystem,
      ),
      distanceUnit: _stringOrDefault(
        json['distanceUnit'],
        defaults.distanceUnit,
      ),
      weightUnit: _stringOrDefault(json['weightUnit'], defaults.weightUnit),
      heightUnit: _stringOrDefault(json['heightUnit'], defaults.heightUnit),
      temperatureUnit: _stringOrDefault(
        json['temperatureUnit'],
        defaults.temperatureUnit,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'measurementSystem': measurementSystem,
    'distanceUnit': distanceUnit,
    'weightUnit': weightUnit,
    'heightUnit': heightUnit,
    'temperatureUnit': temperatureUnit,
  };
}

class NotificationPreferenceSettings {
  const NotificationPreferenceSettings({
    required this.workoutReminders,
    required this.mealReminders,
    required this.waterReminders,
    required this.sleepReminders,
    required this.achievementNotifications,
    required this.weeklyReports,
  });

  final bool workoutReminders;
  final bool mealReminders;
  final bool waterReminders;
  final bool sleepReminders;
  final bool achievementNotifications;
  final bool weeklyReports;

  factory NotificationPreferenceSettings.defaults() =>
      const NotificationPreferenceSettings(
        workoutReminders: true,
        mealReminders: true,
        waterReminders: false,
        sleepReminders: true,
        achievementNotifications: true,
        weeklyReports: false,
      );

  factory NotificationPreferenceSettings.fromJson(Map<String, dynamic> json) {
    final defaults = NotificationPreferenceSettings.defaults();
    return NotificationPreferenceSettings(
      workoutReminders: _boolOrDefault(
        json['workoutReminders'],
        defaults.workoutReminders,
      ),
      mealReminders: _boolOrDefault(
        json['mealReminders'],
        defaults.mealReminders,
      ),
      waterReminders: _boolOrDefault(
        json['waterReminders'],
        defaults.waterReminders,
      ),
      sleepReminders: _boolOrDefault(
        json['sleepReminders'],
        defaults.sleepReminders,
      ),
      achievementNotifications: _boolOrDefault(
        json['achievementNotifications'],
        defaults.achievementNotifications,
      ),
      weeklyReports: _boolOrDefault(
        json['weeklyReports'],
        defaults.weeklyReports,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'workoutReminders': workoutReminders,
    'mealReminders': mealReminders,
    'waterReminders': waterReminders,
    'sleepReminders': sleepReminders,
    'achievementNotifications': achievementNotifications,
    'weeklyReports': weeklyReports,
  };
}

class UserSettingsPreferences {
  UserSettingsPreferences(this._prefs);

  static const languageKey = 'profile_language_preference_v1';
  static const unitSettingsKey = 'profile_unit_settings_v1';
  static const notificationSettingsKey = 'profile_notification_settings_v1';

  final SharedPreferences _prefs;

  Future<String> loadLanguage() async {
    final value = _prefs.getString(languageKey);
    return _stringOrDefault(value, 'English');
  }

  Future<void> saveLanguage(String language) async {
    await _prefs.setString(languageKey, language);
  }

  Future<UnitPreferenceSettings> loadUnitSettings() async {
    return UnitPreferenceSettings.fromJson(_readJson(unitSettingsKey));
  }

  Future<void> saveUnitSettings(UnitPreferenceSettings settings) async {
    await _writeJson(unitSettingsKey, settings.toJson());
  }

  Future<NotificationPreferenceSettings> loadNotificationSettings() async {
    return NotificationPreferenceSettings.fromJson(
      _readJson(notificationSettingsKey),
    );
  }

  Future<void> saveNotificationSettings(
    NotificationPreferenceSettings settings,
  ) async {
    await _writeJson(notificationSettingsKey, settings.toJson());
  }

  Map<String, dynamic> _readJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  Future<void> _writeJson(String key, Map<String, dynamic> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }
}

String _stringOrDefault(Object? value, String fallback) {
  if (value is! String || value.trim().isEmpty) {
    return fallback;
  }
  return value;
}

bool _boolOrDefault(Object? value, bool fallback) {
  return value is bool ? value : fallback;
}
