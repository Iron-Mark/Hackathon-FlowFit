import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

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
                  ),
                  _buildDivider(theme),
                  _buildUnitItem(
                    context,
                    'Weight',
                    _weightUnit,
                    SolarIconsOutline.scale,
                  ),
                  _buildDivider(theme),
                  _buildUnitItem(
                    context,
                    'Height',
                    _heightUnit,
                    SolarIconsOutline.ruler,
                  ),
                  _buildDivider(theme),
                  _buildUnitItem(
                    context,
                    'Temperature',
                    _temperatureUnit,
                    SolarIconsOutline.temperature,
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
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Padding(
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
