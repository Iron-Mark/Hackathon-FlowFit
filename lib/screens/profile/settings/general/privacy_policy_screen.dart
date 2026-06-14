import 'package:flutter/material.dart';
import 'package:flowfit/core/config/flowfit_runtime_config.dart';
import 'package:solar_icons/solar_icons.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    SolarIconsBold.shieldCheck,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Your privacy matters to us',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Our Commitment',
              'FlowFit is built for fitness, wellness, and companion tracking. This Privacy Policy explains the data the app may collect or process when you choose to use those features.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Data You Provide',
              'You may provide account information, profile details, age, body measurements, goals, units, Buddy companion settings, workout entries, mood or wellness notes, and other information you enter in the app.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Sensor and Device Data',
              'With your permission, FlowFit may use heart-rate, motion, activity, location, camera, photo library, and notification permissions. These are used for workout tracking, wellness missions, geofences, activity classification, optional camera/image features, and local reminders.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'How We Use Data',
              'We use data to authenticate your account, sync your profile, personalize goals, show workout history, power Buddy progression, classify activity, support wellness features, and keep the app reliable.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Service Providers',
              'FlowFit uses Supabase for authentication and database sync. Device APIs and SDKs such as Samsung Health Sensor API, geolocation, camera, image picker, local notifications, and on-device ML packages may process data needed for the features you choose to use.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Security and Retention',
              'Data sent to Supabase is transmitted over HTTPS and protected by database access controls. Local data may remain on your device until you remove it, clear app storage, or uninstall the app. The in-app deletion flow also attempts to clear local FlowFit account data on the current device.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Your Rights',
              'You can review or update profile data in the app. You can initiate account deletion from Profile > Settings > Delete Account. FlowFit deletes app-owned records, attempts to clear local account data on the current device, and requests deletion of the sign-in account, except where records must be retained for security, fraud prevention, or legal obligations.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Policy Updates',
              'We may update this Privacy Policy when features, service providers, or legal requirements change. Review this screen and the public store privacy policy for the latest version.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        SolarIconsOutline.letter,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Questions?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'If you have any questions about our Privacy Policy, please contact us at:',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    FlowFitRuntimeConfig.supportEmail,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Text(
                'Last updated: June 14, 2026',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
