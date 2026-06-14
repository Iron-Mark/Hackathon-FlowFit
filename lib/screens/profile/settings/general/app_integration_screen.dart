import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class AppIntegrationScreen extends StatelessWidget {
  const AppIntegrationScreen({super.key});

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
          'App Integration',
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
                    SolarIconsBold.widget,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Connect your favorite apps to sync your data',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Health & Fitness Apps Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Health & Fitness Apps',
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
                  _buildIntegrationItem(
                    context,
                    'Google Fit',
                    'Sync your activity and health data',
                    SolarIconsOutline.heartPulse,
                    false,
                    Colors.red,
                  ),
                  _buildDivider(theme),
                  _buildIntegrationItem(
                    context,
                    'Apple Health',
                    'Connect with Apple Health app',
                    SolarIconsOutline.heartPulse,
                    false,
                    Colors.pink,
                  ),
                  _buildDivider(theme),
                  _buildIntegrationItem(
                    context,
                    'Strava',
                    'Import your runs and rides',
                    SolarIconsOutline.running,
                    false,
                    Colors.orange,
                  ),
                  _buildDivider(theme),
                  _buildIntegrationItem(
                    context,
                    'MyFitnessPal',
                    'Sync nutrition and calorie data',
                    SolarIconsOutline.hamburgerMenu,
                    false,
                    Colors.blue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Wearables Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Wearables',
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
                  _buildIntegrationItem(
                    context,
                    'Fitbit',
                    'Connect your Fitbit device',
                    SolarIconsOutline.clockCircle,
                    false,
                    Colors.teal,
                  ),
                  _buildDivider(theme),
                  _buildIntegrationItem(
                    context,
                    'Garmin',
                    'Sync with Garmin devices',
                    SolarIconsOutline.clockCircle,
                    false,
                    Colors.blue,
                  ),
                  _buildDivider(theme),
                  _buildIntegrationItem(
                    context,
                    'Samsung Health',
                    'Connect Samsung wearables',
                    SolarIconsOutline.clockCircle,
                    false,
                    Colors.purple,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Social & Productivity Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Social & Productivity',
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
                  _buildIntegrationItem(
                    context,
                    'Google Calendar',
                    'Schedule workouts in your calendar',
                    SolarIconsOutline.calendar,
                    false,
                    Colors.blue,
                  ),
                  _buildDivider(theme),
                  _buildIntegrationItem(
                    context,
                    'Spotify',
                    'Play music during workouts',
                    SolarIconsOutline.musicNote,
                    false,
                    Colors.green,
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

  Widget _buildIntegrationItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool isConnected,
    Color iconColor,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title integration coming soon'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: iconColor),
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
            if (isConnected)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Connected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title integration coming soon'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Connect'),
              ),
          ],
        ),
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
