import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/local_account_data_cleanup.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/deep_link_handler.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _confirmationController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _confirmDelete = false;

  @override
  void dispose() {
    _confirmationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteAccount() async {
    if (!_confirmDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm that you want to delete your account'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Show final confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Account?'),
          content: const Text(
            'FlowFit will delete app-owned server records, clear local account data on this device, and request deletion of your sign-in account. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        setState(() => _isLoading = true);

        try {
          final client = Supabase.instance.client;
          final user = client.auth.currentUser;
          if (user == null) {
            throw const AuthException(
              'You must be signed in to delete your account.',
            );
          }

          DeepLinkHandler.beginInternalAuthFlow();
          try {
            await _reauthenticateForDeletion(client, user);
            await client.rpc('request_account_deletion');
            await _clearLocalAccountData(user.id);
            await client.auth.signOut();
          } finally {
            DeepLinkHandler.endInternalAuthFlow();
          }

          if (mounted) {
            setState(() => _isLoading = false);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account deletion request submitted'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );

            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/welcome', (route) => false);
          }
        } catch (error) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_deletionErrorMessage(error)),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _reauthenticateForDeletion(
    SupabaseClient client,
    User user,
  ) async {
    final email = user.email;
    if (email == null || email.trim().isEmpty) {
      throw const AuthException(
        'Email/password reauthentication is required before account deletion.',
      );
    }

    final response = await client.auth.signInWithPassword(
      email: email,
      password: _passwordController.text,
    );

    if (response.user?.id != user.id) {
      throw const AuthException(
        'Reauthentication did not match the current account.',
      );
    }
  }

  String _deletionErrorMessage(Object error) {
    if (error is AuthException) {
      return 'Please confirm your account password and try again.';
    }

    if (error is PostgrestException) {
      return 'Could not submit the deletion request. Please try again.';
    }

    return 'Could not submit the deletion request. Check your connection and try again.';
  }

  Future<void> _clearLocalAccountData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = <String>{
      'user_profile_$userId',
      'sync_queue_$userId',
      'profile_image_$userId',
      'survey_data',
      'sync_queue',
      'buddy_onboarding_state',
      'buddy_onboarding_timestamp',
      'pending_buddy_profile',
      'wellness_history',
      'wellness_transitions',
      'wellness_onboarding_complete',
      'wellness_monitoring_enabled',
      'wellness_last_monitoring_state',
    };

    for (final key in keys) {
      await prefs.remove(key);
    }

    try {
      await clearLocalDatabaseAccountData();
    } catch (_) {
      // Local database cleanup is best effort across mobile/web platforms.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            SolarIconsOutline.altArrowLeft,
            color: AppTheme.text,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Center(
                  child: SvgPicture.asset(
                    'assets/flowfit_logo_header.svg',
                    height: 32,
                  ),
                ),

                const SizedBox(height: 40),

                // Warning Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      SolarIconsBold.dangerTriangle,
                      size: 64,
                      color: Colors.red,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'Delete Account',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Warning Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            SolarIconsBold.infoCircle,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Warning',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Submitting this request will:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildWarningItem(
                        '• Delete app-owned profile, workout, Buddy, and heart-rate records from FlowFit servers',
                      ),
                      _buildWarningItem(
                        '• Clear local FlowFit account data on this device',
                      ),
                      _buildWarningItem(
                        '• Request deletion of your sign-in account',
                      ),
                      _buildWarningItem('• Sign you out on this device'),
                      _buildWarningItem(
                        '• Retain only records required for security, fraud prevention, or legal obligations',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'If you no longer have the app, use the public account deletion page linked from the app store listing.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Type DELETE to confirm',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _confirmationController,
                  style: const TextStyle(color: AppTheme.text),
                  decoration: InputDecoration(
                    hintText: 'DELETE',
                    hintStyle: TextStyle(
                      color: AppTheme.text.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      SolarIconsOutline.trashBinMinimalistic,
                      color: Colors.red,
                    ),
                  ),
                  validator: (value) {
                    if (value?.trim() != 'DELETE') {
                      return 'Type DELETE to confirm account deletion';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                Text(
                  'Confirm your password',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  style: const TextStyle(color: AppTheme.text),
                  decoration: InputDecoration(
                    hintText: 'Account password',
                    hintStyle: TextStyle(
                      color: AppTheme.text.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      SolarIconsOutline.lock,
                      color: Colors.red,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your account password';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Confirmation Checkbox
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _confirmDelete,
                        onChanged: (value) {
                          setState(() {
                            _confirmDelete = value ?? false;
                          });
                        },
                        activeColor: Colors.red,
                      ),
                      Expanded(
                        child: Text(
                          'I understand that this action is permanent and cannot be undone',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.text),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Delete Account Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleDeleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Delete My Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Cancel Button
                OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.text,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: AppTheme.text.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.text.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
