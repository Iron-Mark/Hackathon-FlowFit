import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/buddy_onboarding_provider.dart';
import '../../widgets/buddy_character_widget.dart';
import '../../widgets/buddy_idle_animation.dart';
import '../../widgets/onboarding_button.dart';

/// Buddy Intro Screen - Step 2 of 8
///
/// Whale companion asks for user's name in conversational style.
/// Speech bubble: "Splash splash, thanks for finding me.
/// If my name is Bubbles, what's your name?"
///
/// Whale-themed onboarding flow implementation.
class BuddyIntroScreen extends ConsumerStatefulWidget {
  const BuddyIntroScreen({super.key});

  @override
  ConsumerState<BuddyIntroScreen> createState() => _BuddyIntroScreenState();
}

class _BuddyIntroScreenState extends ConsumerState<BuddyIntroScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _handleNext() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      ref.read(buddyOnboardingProvider.notifier).setUserName(name);
      Navigator.pushNamed(context, '/buddy-hatch');
    }
  }

  void _handleSkip() {
    Navigator.pushNamed(context, '/buddy-hatch');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNameEmpty = _nameController.text.trim().isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    48, // Account for padding
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Skip button
                    Semantics(
                      button: true,
                      label: 'Skip button',
                      hint: 'Tap to skip entering your name',
                      child: Align(
                        alignment: Alignment.topRight,
                        child: TextButton(
                          onPressed: _handleSkip,
                          child: Text(
                            'Skip',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF7F8C8D),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Speech bubble from Buddy
                    Semantics(
                      label:
                          'Bubbles says: Splash splash, thanks for finding me. If my name is Bubbles, what\'s your name?',
                      child: Container(
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
                              'Splash splash, thanks for finding me.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: const Color(0xFF314158),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'If my name is Bubbles, what\'s your name?',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: const Color(0xFF7F8C8D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Buddy character in Ocean Blue
                    Semantics(
                      label: 'Bubbles the whale, gently bobbing',
                      image: true,
                      child: const BuddyIdleAnimation(
                        child: BuddyCharacterWidget(
                          color: Color(0xFF4ECDC4), // Ocean Blue
                          size: 160,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Name input field
                    Semantics(
                      label: 'Your name input field',
                      textField: true,
                      hint: 'Enter your name',
                      child: TextField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        autofocus: true,
                        style: const TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Name for Bubbles\' friend...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) {
                          if (!isNameEmpty) _handleNext();
                        },
                      ),
                    ),

                    const Spacer(),

                    // Next button (disabled until input)
                    Semantics(
                      button: true,
                      label: 'Next button',
                      hint: isNameEmpty
                          ? 'Enter your name to continue'
                          : 'Tap to continue',
                      enabled: !isNameEmpty,
                      child: OnboardingButton(
                        label: 'NEXT',
                        onPressed: isNameEmpty ? null : _handleNext,
                        customColor: const Color(0xFF4ECDC4),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
