import 'package:flutter/material.dart';
import 'package:flowfit/core/config/flowfit_runtime_config.dart';
import 'package:solar_icons/solar_icons.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
                    SolarIconsBold.documentText,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Please read these terms carefully',
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
              'Acceptance of Terms',
              'By accessing and using FlowFit, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to these terms, please do not use our service.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Use License',
              'Permission is granted to temporarily download one copy of FlowFit for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'User Account',
              'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Health Information',
              'FlowFit provides fitness and health tracking features. The information provided is for general informational purposes only and should not be considered medical advice. Always consult with a healthcare professional before starting any fitness program.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Data Collection',
              'We collect and process your personal data in accordance with our Privacy Policy. By using FlowFit, you consent to such processing and you warrant that all data provided by you is accurate.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Prohibited Uses',
              'You may not use FlowFit for any illegal or unauthorized purpose. You must not transmit any worms, viruses, or any code of a destructive nature.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Limitation of Liability',
              'FlowFit shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the service.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Modifications',
              'FlowFit reserves the right to modify or replace these Terms at any time. We will provide notice of any significant changes by posting the new Terms on this page.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Termination',
              'We may terminate or suspend your account and access to the service immediately, without prior notice or liability, for any reason, including breach of these Terms.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
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
                        'Contact Us',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'If you have any questions about these Terms, please contact us at:',
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
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Last updated: November 27, 2025',
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
