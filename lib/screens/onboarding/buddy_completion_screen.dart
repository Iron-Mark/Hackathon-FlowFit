import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/buddy_character_widget.dart';
import '../../widgets/buddy_celebration_animation.dart';
import '../../widgets/onboarding_button.dart';
import '../../providers/buddy_onboarding_provider.dart';
import '../../utils/buddy_colors.dart';
import '../../core/exceptions/buddy_exceptions.dart';

typedef BuddyOnboardingCompletionAction =
    Future<void> Function({
      required WidgetRef ref,
      required BuildContext context,
    });

/// Buddy Completion Screen
///
/// Celebrates the completion of Buddy onboarding with an
/// animated Buddy and motivational message.
///
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 8.3
class BuddyCompletionScreen extends ConsumerStatefulWidget {
  const BuddyCompletionScreen({super.key, this.completeOnboarding});

  final BuddyOnboardingCompletionAction? completeOnboarding;

  @override
  ConsumerState<BuddyCompletionScreen> createState() =>
      _BuddyCompletionScreenState();
}

class _BuddyCompletionScreenState extends ConsumerState<BuddyCompletionScreen> {
  bool _isLoading = false;
  bool _isErrorDialogShowing = false;

  Future<void> _handleStartMission() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // If saved locally, show success message and navigate
        if (e.savedLocally) {
          _showSuccessSnackBar(e.friendlyMessage);
          // Navigate anyway since data is saved locally
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          );
        } else {
          _showErrorDialog(e.friendlyMessage, canRetry: true);
        }
      }
    } on BuddyAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(e.friendlyMessage, canRetry: false);
      }
    } on BuddyNetworkException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(e.friendlyMessage, canRetry: e.canRetry);
      }
    } on BuddyException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(e.friendlyMessage, canRetry: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(
          'Oops! Something unexpected happened. Please try again!',
          canRetry: true,
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

  Future<void> _showErrorDialog(
    String message, {
    required bool canRetry,
  }) async {
    if (_isErrorDialogShowing || !mounted) return;

    _isErrorDialogShowing = true;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oops!'),
        content: Text(message),
        actions: [
          if (canRetry)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _isErrorDialogShowing = false;
                _handleStartMission();
              },
              child: const Text('Try Again'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(canRetry ? 'Cancel' : 'OK'),
          ),
        ],
      ),
    );
    _isErrorDialogShowing = false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(buddyOnboardingProvider);
    final buddyColor = BuddyColors.getColor(state.selectedColor ?? 'blue');
    final buddyName = state.buddyName ?? 'Buddy';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Celebration emoji
              Semantics(
                label: 'Celebration',
                child: const Text('🎉', style: TextStyle(fontSize: 64)),
              ),

              const SizedBox(height: 24),

              // Animated Buddy with celebration
              Semantics(
                label: '$buddyName celebrating with a jumping animation',
                image: true,
                child: BuddyCelebrationAnimation(
                  child: BuddyCharacterWidget(color: buddyColor, size: 160),
                ),
              ),

              const SizedBox(height: 32),

              // Personalized message
              Semantics(
                header: true,
                child: Text(
                  '$buddyName is Ready!',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF314158),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Motivational text
              Semantics(
                label:
                    '$buddyName wants to play! Let\'s do your first challenge!',
                child: Text(
                  '$buddyName wants to play!\nLet\'s do your first challenge!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // Start mission button
              _isLoading
                  ? Semantics(
                      label: 'Loading, please wait',
                      child: const CircularProgressIndicator(),
                    )
                  : Semantics(
                      button: true,
                      label: 'Start first mission button',
                      hint: 'Tap to begin your first challenge with $buddyName',
                      child: OnboardingButton(
                        label: 'START FIRST MISSION',
                        onPressed: _handleStartMission,
                        isPrimary: true,
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
