import 'package:flutter/material.dart';
import 'package:flowfit/core/config/flowfit_runtime_config.dart';
import 'package:flowfit/services/support_request_service.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:url_launcher/url_launcher.dart';

typedef SupportEmailLauncher = Future<bool> Function(Uri uri);
typedef SupportRequestSubmitter =
    Future<String> Function(SupportRequestDraft draft);

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({
    super.key,
    this.launchSupportEmail,
    this.submitSupportRequest,
  });

  final SupportEmailLauncher? launchSupportEmail;
  final SupportRequestSubmitter? submitSupportRequest;

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  bool _isLaunchingSupportEmail = false;
  bool _isSubmittingSupportRequest = false;

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

  Future<void> _openSupportRequestForm(
    BuildContext context, {
    required String category,
    required String subject,
    String message = '',
  }) async {
    if (_isSubmittingSupportRequest) return;

    final draft = await showDialog<SupportRequestDraft>(
      context: context,
      builder: (_) => _SupportRequestDialog(
        category: category,
        subject: subject,
        message: message,
      ),
    );
    if (draft == null) return;

    setState(() {
      _isSubmittingSupportRequest = true;
    });

    try {
      final submitter =
          widget.submitSupportRequest ?? SupportRequestService().submit;
      await submitter(draft);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support request sent.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      final message = error is SupportRequestException
          ? error.message
          : 'Unable to send support request. Try Email Support.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingSupportRequest = false;
        });
      }
    }
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
                    'Send an in-app request',
                    SolarIconsOutline.chatRound,
                    Colors.green,
                    () => _openSupportRequestForm(
                      context,
                      category: 'support',
                      subject: 'FlowFit support request',
                    ),
                  ),
                  _buildDivider(theme),
                  _buildActionItem(
                    context,
                    'Report a Bug',
                    'Help us improve FlowFit',
                    SolarIconsOutline.bug,
                    Colors.orange,
                    () => _openSupportRequestForm(
                      context,
                      category: 'bug',
                      subject: 'FlowFit bug report',
                      message:
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
                    'In-app requests',
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
      onTap: (_isLaunchingSupportEmail || _isSubmittingSupportRequest)
          ? null
          : onTap,
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

class _SupportRequestDialog extends StatefulWidget {
  const _SupportRequestDialog({
    required this.category,
    required this.subject,
    required this.message,
  });

  final String category;
  final String subject;
  final String message;

  @override
  State<_SupportRequestDialog> createState() => _SupportRequestDialogState();
}

class _SupportRequestDialogState extends State<_SupportRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedCategory;
  late final TextEditingController _subjectController;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
    _subjectController = TextEditingController(text: widget.subject);
    _messageController = TextEditingController(text: widget.message);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      SupportRequestDraft(
        category: _selectedCategory,
        subject: _subjectController.text,
        message: _messageController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send support request'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Request type'),
                items: const [
                  DropdownMenuItem(
                    value: 'support',
                    child: Text('General support'),
                  ),
                  DropdownMenuItem(value: 'bug', child: Text('Bug report')),
                  DropdownMenuItem(
                    value: 'account',
                    child: Text('Account help'),
                  ),
                  DropdownMenuItem(
                    value: 'privacy',
                    child: Text('Privacy request'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectController,
                maxLength: 160,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  if (length < 3) {
                    return 'Subject must be at least 3 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                minLines: 4,
                maxLines: 7,
                maxLength: 4000,
                decoration: const InputDecoration(labelText: 'Message'),
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  if (length < 10) {
                    return 'Message must be at least 10 characters.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Send')),
      ],
    );
  }
}
