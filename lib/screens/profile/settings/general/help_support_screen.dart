import 'package:flutter/material.dart';
import 'package:flowfit/core/config/flowfit_runtime_config.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:url_launcher/url_launcher.dart';

typedef SupportEmailLauncher = Future<bool> Function(Uri uri);

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key, this.launchSupportEmail});

  final SupportEmailLauncher? launchSupportEmail;

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  bool _isLaunchingSupportEmail = false;

  Future<void> _openSupportEmail(
    BuildContext context, {
    required String subject,
    String body = '',
  }) async {
    if (_isLaunchingSupportEmail) return;

    final uri = Uri(
      scheme: 'mailto',
      path: FlowFitRuntimeConfig.supportEmail,
      queryParameters: {'subject': subject, if (body.isNotEmpty) 'body': body},
    );

    setState(() {
      _isLaunchingSupportEmail = true;
    });

    try {
      final launched = await (widget.launchSupportEmail ?? _launchSupportEmail)(
        uri,
      );
      if (launched) return;
    } catch (_) {
      // Fall through to the in-app fallback below.
    } finally {
      if (mounted) {
        setState(() {
          _isLaunchingSupportEmail = false;
        });
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Email app unavailable. Contact ${FlowFitRuntimeConfig.supportEmail}.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<bool> _launchSupportEmail(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
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
          'Help & Support',
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

            // Contact Support Banner
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    SolarIconsBold.chatRound,
                    size: 48,
                    color: theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'How can we help you?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'re here to assist you with any questions',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Quick Actions',
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
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildActionItem(
                    context,
                    'Email Support',
                    'Get help via email',
                    SolarIconsOutline.letter,
                    Colors.blue,
                    () => _openSupportEmail(
                      context,
                      subject: 'FlowFit support request',
                    ),
                  ),
                  _buildDivider(theme),
                  _buildActionItem(
                    context,
                    'Message Support',
                    'Send a support request',
                    SolarIconsOutline.chatRound,
                    Colors.green,
                    () => _openSupportEmail(
                      context,
                      subject: 'FlowFit support request',
                      body: 'Hi FlowFit support,\n\n',
                    ),
                  ),
                  _buildDivider(theme),
                  _buildActionItem(
                    context,
                    'Report a Bug',
                    'Help us improve FlowFit',
                    SolarIconsOutline.bug,
                    Colors.orange,
                    () => _openSupportEmail(
                      context,
                      subject: 'FlowFit bug report',
                      body:
                          'What happened?\n\nSteps to reproduce:\n1. \n2. \n3. \n\nDevice/app details:\n',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FAQ Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Frequently Asked Questions',
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
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildFAQItem(
                    context,
                    'How do I track my workouts?',
                    'Navigate to the Track tab and select the activity you want to track. FlowFit will automatically record your workout data.',
                  ),
                  _buildDivider(theme),
                  _buildFAQItem(
                    context,
                    'How do I sync with other apps?',
                    'Go to Settings > App Integration to set up Samsung Health Sensor API support for Galaxy Watch. Other providers are marked Not supported until they are implemented.',
                  ),
                  _buildDivider(theme),
                  _buildFAQItem(
                    context,
                    'Can I change my goals?',
                    'Yes! Go to your Profile and tap on "My Goals" to update your fitness targets anytime.',
                  ),
                  _buildDivider(theme),
                  _buildFAQItem(
                    context,
                    'How do I reset my password?',
                    'Go to Profile > Settings > Change Password to update your account password.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Contact Information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Contact Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContactRow(
                    context,
                    SolarIconsOutline.letter,
                    'Email',
                    FlowFitRuntimeConfig.supportEmail,
                  ),
                  const SizedBox(height: 16),
                  _buildContactRow(
                    context,
                    SolarIconsOutline.globus,
                    'Website',
                    FlowFitRuntimeConfig.publicWebBaseUrl,
                  ),
                  const SizedBox(height: 16),
                  _buildContactRow(
                    context,
                    SolarIconsOutline.clockCircle,
                    'Support Channel',
                    'Email support',
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

  Widget _buildActionItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: _isLaunchingSupportEmail ? null : onTap,
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
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        question,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
