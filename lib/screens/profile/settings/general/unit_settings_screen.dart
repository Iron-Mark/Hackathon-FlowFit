import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../../services/user_settings_preferences.dart';

class UnitSettingsScreen extends StatefulWidget {
  const UnitSettingsScreen({super.key});

  @override
  State<UnitSettingsScreen> createState() => _UnitSettingsScreenState();
}

class _UnitSettingsScreenState extends State<UnitSettingsScreen> {
  String _measurementSystem = 'Metric';
  String _distanceUnit = 'Kilometers';
  String _weightUnit = 'Kilograms';
  String _heightUnit = 'Centimeters';
  String _temperatureUnit = 'Celsius';

  @override
  void initState() {
    super.initState();
    _loadSavedUnits();
  }

  Future<void> _loadSavedUnits() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = await UserSettingsPreferences(prefs).loadUnitSettings();
    if (!mounted) return;

    setState(() {
      _measurementSystem = _validMeasurementSystem(settings.measurementSystem);
      _distanceUnit = _validUnit(settings.distanceUnit, const [
        'Kilometers',
        'Miles',
      ], 'Kilometers');
      _weightUnit = _validUnit(settings.weightUnit, const [
        'Kilograms',
        'Pounds',
      ], 'Kilograms');
      _heightUnit = _validUnit(settings.heightUnit, const [
        'Centimeters',
        'Feet/Inches',
      ], 'Centimeters');
      _temperatureUnit = _validUnit(settings.temperatureUnit, const [
        'Celsius',
        'Fahrenheit',
      ], 'Celsius');
    });
  }

  Future<void> _saveUnits() async {
    final prefs = await SharedPreferences.getInstance();
    await UserSettingsPreferences(prefs).saveUnitSettings(
      UnitPreferenceSettings(
        measurementSystem: _measurementSystem,
        distanceUnit: _distanceUnit,
        weightUnit: _weightUnit,
        heightUnit: _heightUnit,
        temperatureUnit: _temperatureUnit,
      ),
    );
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
          'Units',
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
                    SolarIconsBold.ruler,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Choose your preferred measurement units',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Measurement System
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Measurement System',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: RadioGroup<String>(
                groupValue: _measurementSystem,
                onChanged: (value) {
                  if (value != null) {
                    _updateMeasurementSystem(value);
                  }
                },
                child: Column(
                  children: [
                    _buildRadioItem(
                      context,
                      'Metric',
                      'Kilometers, Kilograms, Celsius',
                      _updateMeasurementSystem,
                    ),
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.3,
                      ),
                      indent: 16,
                      endIndent: 16,
                    ),
                    _buildRadioItem(
                      context,
                      'Imperial',
                      'Miles, Pounds, Fahrenheit',
                      _updateMeasurementSystem,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Individual Units
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Individual Units',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildUnitItem(
                    context,
                    'Distance',
                    _distanceUnit,
                    SolarIconsOutline.mapPointWave,
                    options: const ['Kilometers', 'Miles'],
                    onSelected: (value) {
                      setState(() => _distanceUnit = value);
                      unawaited(_saveUnits());
                    },
                  ),
                  _buildDivider(theme),
                  _buildUnitItem(
                    context,
                    'Weight',
                    _weightUnit,
                    SolarIconsOutline.scale,
                    options: const ['Kilograms', 'Pounds'],
                    onSelected: (value) {
                      setState(() => _weightUnit = value);
                      unawaited(_saveUnits());
                    },
                  ),
                  _buildDivider(theme),
                  _buildUnitItem(
                    context,
                    'Height',
                    _heightUnit,
                    SolarIconsOutline.ruler,
                    options: const ['Centimeters', 'Feet/Inches'],
                    onSelected: (value) {
                      setState(() => _heightUnit = value);
                      unawaited(_saveUnits());
                    },
                  ),
                  _buildDivider(theme),
                  _buildUnitItem(
                    context,
                    'Temperature',
                    _temperatureUnit,
                    SolarIconsOutline.temperature,
                    options: const ['Celsius', 'Fahrenheit'],
                    onSelected: (value) {
                      setState(() => _temperatureUnit = value);
                      unawaited(_saveUnits());
                    },
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

  void _updateMeasurementSystem(String value) {
    setState(() {
      _measurementSystem = value;
      if (value == 'Metric') {
        _distanceUnit = 'Kilometers';
        _weightUnit = 'Kilograms';
        _heightUnit = 'Centimeters';
        _temperatureUnit = 'Celsius';
      } else {
        _distanceUnit = 'Miles';
        _weightUnit = 'Pounds';
        _heightUnit = 'Feet/Inches';
        _temperatureUnit = 'Fahrenheit';
      }
    });
    unawaited(_saveUnits());
  }

  Widget _buildRadioItem(
    BuildContext context,
    String title,
    String subtitle,
    ValueChanged<String> onChanged,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => onChanged(title),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(value: title, activeColor: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _showUnitPicker(
        context,
        title: label,
        currentValue: value,
        options: options,
        onSelected: onSelected,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUnitPicker(
    BuildContext context, {
    required String title,
    required String currentValue,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: currentValue,
                  onChanged: (value) {
                    if (value != null) {
                      Navigator.pop(context, value);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final option in options)
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: option,
                          title: Text(option),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && selected != currentValue) {
      onSelected(selected);
    }
  }

  String _validMeasurementSystem(String value) {
    return value == 'Imperial' ? 'Imperial' : 'Metric';
  }

  String _validUnit(String value, List<String> allowed, String fallback) {
    return allowed.contains(value) ? value : fallback;
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
