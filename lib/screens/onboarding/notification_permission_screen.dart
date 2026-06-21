import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/buddy_onboarding_provider.dart';
import '../../widgets/buddy_character_widget.dart';
import '../../widgets/buddy_idle_animation.dart';
import '../../widgets/onboarding_button.dart';

/// Notification Permission Screen - Step 8 of 9
///
/// Request notification permission with preview card showing example.
/// Kids can opt-in or skip.
///
/// Whale companion pattern implementation.
class NotificationPermissionScreen extends ConsumerStatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  ConsumerState<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends ConsumerState<NotificationPermissionScreen> {
  bool _isRequestingPermission = false;

  Future<void> _handleTurnOn() async {
    if (_isRequestingPermission) return;

    setState(() {
      _isRequestingPermission = true;
    });

    try {
      final status = await Permission.notification.request();
      if (!mounted) return;

      ref
          .read(buddyOnboardingProvider.notifier)
          .setNotificationPermission(status.isGranted);

      Navigator.pushNamed(context, '/buddy-ready');
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isRequestingPermission = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not request notifications. You can try again or continue without reminders.',
          ),
        ),
      );
    }
  }

  void _handleMaybeLater() {
    ref.read(buddyOnboardingProvider.notifier).setNotificationPermission(false);

    Navigator.pushNamed(context, '/buddy-ready');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(buddyOnboardingProvider);
    final buddyName = state.buddyName ?? 'Bubbles';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Buddy animation (thinking)
              const Center(
                child: BuddyIdleAnimation(
                  child: BuddyCharacterWidget(
                    color: Color(0xFF4ECDC4),
                    size: 120,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Get reminders from $buddyName',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF314158),
                ),
              ),

              const SizedBox(height: 24),

              // Preview notification card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ECDC4),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('🐋', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'From $buddyName • now',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF314158),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Remember to drink water!',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF314158),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stay hydrated to keep your energy up! 💧',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF7F8C8D),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Turn on notifications button
              OnboardingButton(
                label: _isRequestingPermission
                    ? 'REQUESTING...'
                    : 'TURN ON NOTIFICATIONS',
                onPressed: _isRequestingPermission ? null : _handleTurnOn,
                customColor: const Color(0xFF66BB6A),
              ),

              const SizedBox(height: 12),

              // Maybe later button
              OutlinedButton(
                onPressed: _isRequestingPermission ? null : _handleMaybeLater,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  side: BorderSide(color: Colors.grey[300]!, width: 2),
                ),
                child: Text(
                  'Maybe later',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF7F8C8D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
