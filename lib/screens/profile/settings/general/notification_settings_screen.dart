import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../../services/user_settings_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _workoutReminders = true;
  bool _mealReminders = true;
  bool _waterReminders = false;
  bool _sleepReminders = true;
  bool _achievementNotifications = true;
  bool _weeklyReports = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = await UserSettingsPreferences(
      prefs,
    ).loadNotificationSettings();
    if (!mounted) return;

    setState(() {
      _workoutReminders = settings.workoutReminders;
      _mealReminders = settings.mealReminders;
      _waterReminders = settings.waterReminders;
      _sleepReminders = settings.sleepReminders;
      _achievementNotifications = settings.achievementNotifications;
      _weeklyReports = settings.weeklyReports;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await UserSettingsPreferences(prefs).saveNotificationSettings(
      NotificationPreferenceSettings(
        workoutReminders: _workoutReminders,
        mealReminders: _mealReminders,
        waterReminders: _waterReminders,
        sleepReminders: _sleepReminders,
        achievementNotifications: _achievementNotifications,
        weeklyReports: _weeklyReports,
      ),
    );
  }

  void _updateSetting(ValueChanged<bool> update, bool value) {
    setState(() => update(value));
    unawaited(_saveSettings());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Reminder',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Info Banner
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    SolarIconsBold.bell,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Stay on track with personalized reminders',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Activity Reminders Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Activity Reminders',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSwitchItem(
                    context,
                    'Workout Reminders',
                    'Get reminded to exercise',
                    SolarIconsOutline.running,
                    _workoutReminders,
                    (value) => _updateSetting(
                      (next) => _workoutReminders = next,
                      value,
                    ),
                  ),
                  _buildDivider(theme),
                  _buildSwitchItem(
                    context,
                    'Meal Reminders',
                    'Track your meals on time',
                    SolarIconsOutline.hamburgerMenu,
                    _mealReminders,
                    (value) =>
                        _updateSetting((next) => _mealReminders = next, value),
                  ),
                  _buildDivider(theme),
                  _buildSwitchItem(
                    context,
                    'Water Reminders',
                    'Stay hydrated throughout the day',
                    SolarIconsOutline.cup,
                    _waterReminders,
                    (value) =>
                        _updateSetting((next) => _waterReminders = next, value),
                  ),
                  _buildDivider(theme),
                  _buildSwitchItem(
                    context,
                    'Sleep Reminders',
                    'Get reminded to sleep on time',
                    SolarIconsOutline.moon,
                    _sleepReminders,
                    (value) =>
                        _updateSetting((next) => _sleepReminders = next, value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Progress & Updates Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Progress & Updates',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSwitchItem(
                    context,
                    'Achievement Notifications',
                    'Celebrate your milestones',
                    SolarIconsOutline.cupStar,
                    _achievementNotifications,
                    (value) => _updateSetting(
                      (next) => _achievementNotifications = next,
                      value,
                    ),
                  ),
                  _buildDivider(theme),
                  _buildSwitchItem(
                    context,
                    'Weekly Reports',
                    'Get weekly progress summaries',
                    SolarIconsOutline.chartSquare,
                    _weeklyReports,
                    (value) =>
                        _updateSetting((next) => _weeklyReports = next, value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
      indent: 16,
      endIndent: 16,
    );
  }
}
