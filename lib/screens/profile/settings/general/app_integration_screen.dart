import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

enum _IntegrationAction { unsupported, wellnessSetup }

class AppIntegrationScreen extends StatelessWidget {
  const AppIntegrationScreen({super.key});

  void _showIntegrationDetails(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isConnected,
    required _IntegrationAction action,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                const SizedBox(height: 8),
                Text(subtitle, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      isConnected
                          ? SolarIconsBold.checkCircle
                          : SolarIconsOutline.infoCircle,
                      color: isConnected ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isConnected
                            ? 'Connected and ready to sync.'
                            : 'FlowFit uses the Samsung Health Sensor API through the watch wellness setup flow.',
                      ),
                    ),
                  ],
                ),
                if (action == _IntegrationAction.wellnessSetup) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/wellness-onboarding');
                      },
                      child: const Text('Open Wellness Setup'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
                      'Set up Galaxy Watch sensors and review provider support',
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
                    'Not supported in this build',
                    SolarIconsOutline.heartPulse,
                    false,
                    Colors.red,
                  ),
                  _buildDivider(theme),
                  _buildIntegrationItem(
                    context,
                    'Apple Health',
                    'Not supported in this Android build',
                    SolarIconsOutline.heartPulse,
                    false,
                    Colors.pink,
                  ),
                  _buildDivider(theme),
                  _buildIntegrationItem(
                    context,
                    'Strava',
                    'Not supported in this build',
                    SolarIconsOutline.running,
                    false,
                    Colors.orange,
                  ),
                  _buildDivider(theme),
                  _buildIntegrationItem(
                    context,
                    'MyFitnessPal',
                    'Not supported in this build',
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
                    'Not supported in this build',
                    SolarIconsOutline.clockCircle,
                    false,
                    Colors.teal,
                  ),
                  _buildDivider(theme),
                  _buildIntegrationItem(
                    context,
                    'Garmin',
                    'Not supported in this build',
                    SolarIconsOutline.clockCircle,
                    false,
                    Colors.blue,
                  ),
                  _buildDivider(theme),
                  _buildIntegrationItem(
                    context,
                    'Samsung Health',
                    'Set up Galaxy Watch sensor access',
                    SolarIconsOutline.clockCircle,
                    false,
                    Colors.purple,
                    action: _IntegrationAction.wellnessSetup,
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
                    'Not supported in this build',
                    SolarIconsOutline.calendar,
                    false,
                    Colors.blue,
                  ),
                  _buildDivider(theme),
                  _buildIntegrationItem(
                    context,
                    'Spotify',
                    'Not supported in this build',
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
    Color iconColor, {
    _IntegrationAction action = _IntegrationAction.unsupported,
  }) {
    final theme = Theme.of(context);
    final isActionable =
        isConnected || action == _IntegrationAction.wellnessSetup;

    return InkWell(
      onTap: isActionable
          ? () => _showIntegrationDetails(
              context,
              title: title,
              subtitle: subtitle,
              isConnected: isConnected,
              action: action,
            )
          : null,
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
            else if (action == _IntegrationAction.wellnessSetup)
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/wellness-onboarding'),
                child: const Text('Set Up'),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Not supported',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
