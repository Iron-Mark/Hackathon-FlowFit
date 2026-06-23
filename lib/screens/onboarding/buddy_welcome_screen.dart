import 'package:flutter/material.dart';
import '../../widgets/buddy_character_widget.dart';
import '../../widgets/buddy_idle_animation.dart';
import '../../widgets/onboarding_button.dart';

/// Buddy Welcome Screen - Step 1 of 8
///
/// First screen in the whale-themed Buddy onboarding flow that introduces
/// the user to their new fitness whale companion.
///
/// "Meet Your Fitness Buddy!" with animated whale bouncing.
///
/// Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 10.3, 10.4
class BuddyWelcomeScreen extends StatelessWidget {
  const BuddyWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    assert(() {
      debugPrint('BuddyWelcomeScreen: rendered');
      return true;
    }());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD), // FlowFit light gray
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // FlowFit logo in header (subtle)
              Semantics(
                header: true,
                label: 'FlowFit',
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'FlowFit',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF3B82F6), // Primary Blue
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Animated Buddy character in Ocean Blue
              Semantics(
                label:
                    'Animated Buddy character in ocean blue color, gently bobbing',
                image: true,
                child: const BuddyIdleAnimation(
                  child: BuddyCharacterWidget(
                    color: Color(0xFF4ECDC4), // Ocean Blue
                    size: 200,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Large heading "Meet Your Fitness Buddy!"
              Semantics(
                header: true,
                child: Text(
                  'Meet Your\nFitness Buddy!',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF314158), // FlowFit text color
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Friendly whale tagline
              Semantics(
                label:
                    'Your new whale companion will help you stay active and have fun!',
                child: Text(
                  'Your new whale companion will help you\nstay active and have fun! 🐋',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // Primary button "LET'S GO!"
              Semantics(
                button: true,
                label: 'Let\'s go button. Tap to start meeting your Buddy',
                child: OnboardingButton(
                  label: 'LET\'S GO!',
                  onPressed: () {
                    Navigator.pushNamed(context, '/buddy-intro');
                  },
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
