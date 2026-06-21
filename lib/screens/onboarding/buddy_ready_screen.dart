import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/buddy_onboarding_provider.dart';
import '../../widgets/buddy_character_widget.dart';
import '../../widgets/buddy_celebration_animation.dart';
import '../../widgets/onboarding_button.dart';
import '../../utils/buddy_colors.dart';
import '../../core/exceptions/buddy_exceptions.dart';

typedef BuddyReadyCompletionAction =
    Future<void> Function({
      required WidgetRef ref,
      required BuildContext context,
    });

/// Buddy Ready Screen - Step 9 of 9 (Final)
///
/// Celebration & first stat gain screen.
/// Speech bubble: "Wow! When you take care of yourself,
/// you take care of me too! Let's swim together!"
///
/// Shows stat gain: "😍 Bubbles gained +5.9 Compassion"
///
/// Whale-themed onboarding completion.
class BuddyReadyScreen extends ConsumerStatefulWidget {
  const BuddyReadyScreen({super.key, this.completeOnboarding});

  final BuddyReadyCompletionAction? completeOnboarding;

  @override
  ConsumerState<BuddyReadyScreen> createState() => _BuddyReadyScreenState();
}

class _BuddyReadyScreenState extends ConsumerState<BuddyReadyScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _showStatGain = false;
  late AnimationController _statGainController;
  late Animation<double> _statGainAnimation;

  @override
  void initState() {
    super.initState();

    _statGainController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _statGainAnimation = CurvedAnimation(
      parent: _statGainController,
      curve: Curves.elasticOut,
    );

    // Show stat gain after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _showStatGain = true);
        _statGainController.forward();
      }
    });
  }

  @override
  void dispose() {
    _statGainController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final completeOnboarding =
          widget.completeOnboarding ?? _completeSupabaseOnboarding;
      await completeOnboarding(ref: ref, context: context);

      if (mounted) {
        // Navigate to dashboard
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
        );
      }
    } on BuddySaveException catch (e) {
      // Handle offline save gracefully
      if (e.savedLocally) {
        // Saved offline successfully - show success message and continue
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.userFriendlyMessage ??
                    'Saved offline! We\'ll sync when you\'re back online.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );

          // Navigate to dashboard anyway
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          );
        }
      } else {
        // Complete failure - show error and stay on screen
        if (mounted) {
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.userFriendlyMessage ??
                    'Failed to save your Buddy. Please try again!',
              ),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _handleNext,
              ),
            ),
          );
        }
      }
    } on BuddyException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.friendlyMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _handleNext,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Oops! Something went wrong. Please try again!',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _handleNext,
            ),
          ),
        );
      }
    }
  }

  Future<void> _completeSupabaseOnboarding({
    required WidgetRef ref,
    required BuildContext context,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      throw BuddyAuthException(
        'User not authenticated',
        userFriendlyMessage:
            'Oops! You need to be logged in to create your Buddy.',
      );
    }

    await ref.read(buddyOnboardingProvider.notifier).completeOnboarding(userId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(buddyOnboardingProvider);
    final buddyName = state.buddyName ?? 'Bubbles';
    final buddyColor = BuddyColors.getColor(state.selectedColor ?? 'blue');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Buddy holding heart
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    BuddyCelebrationAnimation(
                      child: BuddyCharacterWidget(color: buddyColor, size: 140),
                    ),
                    // Heart emoji
                    Positioned(
                      bottom: -10,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.pink[50],
                          shape: BoxShape.circle,
                        ),
                        child: const Text('❤️', style: TextStyle(fontSize: 32)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Speech bubble
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Wow! When you take care of yourself,',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF314158),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'you take care of me too!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF314158),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Let\'s swim together! 🌊',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF7F8C8D),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stat gain notification
              if (_showStatGain)
                ScaleTransition(
                  scale: _statGainAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4ECDC4).withValues(alpha: 0.2),
                          const Color(0xFF66BB6A).withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF4ECDC4).withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('😍', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Text(
                          '$buddyName gained +5.9 Compassion',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF314158),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // Next button → Dashboard
              OnboardingButton(
                label: _isLoading ? 'LOADING...' : 'START ADVENTURE!',
                onPressed: _isLoading ? null : _handleNext,
                customColor: const Color(0xFF66BB6A),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
