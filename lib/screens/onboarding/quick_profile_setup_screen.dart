import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/buddy_character_widget.dart';
import '../../widgets/onboarding_button.dart';
import '../../providers/buddy_onboarding_provider.dart';
import '../../utils/buddy_colors.dart';

/// Quick Profile Setup Screen
///
/// Allows users to provide basic information (nickname and age)
/// in a kid-friendly way.
///
/// Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 8.2, 10.3, 11.1, 11.5
class QuickProfileSetupScreen extends ConsumerStatefulWidget {
  const QuickProfileSetupScreen({super.key});

  @override
  ConsumerState<QuickProfileSetupScreen> createState() =>
      _QuickProfileSetupScreenState();
}

class _QuickProfileSetupScreenState
    extends ConsumerState<QuickProfileSetupScreen> {
  final _nicknameController = TextEditingController();
  int? _selectedAge;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    // Save user info to state
    final nickname = _nicknameController.text.trim();
    ref
        .read(buddyOnboardingProvider.notifier)
        .setUserInfo(nickname.isEmpty ? null : nickname, _selectedAge);

    // Navigate to completion screen
    Navigator.pushNamed(context, '/buddy-completion');
  }

  void _handleSkip() {
    // Navigate to completion screen without saving info
    Navigator.pushNamed(context, '/buddy-completion');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(buddyOnboardingProvider);
    final buddyColor = BuddyColors.getColor(state.selectedColor ?? 'blue');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button
              Semantics(
                button: true,
                label: 'Back button',
                hint: 'Go back to previous screen',
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Buddy with name
              Semantics(
                label: 'Your Buddy named ${state.buddyName ?? 'Buddy'}',
                image: true,
                child: Center(
                  child: Column(
                    children: [
                      BuddyCharacterWidget(color: buddyColor, size: 120),
                      const SizedBox(height: 16),
                      Text(
                        state.buddyName ?? 'Buddy',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF314158),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Prompt
              Semantics(
                header: true,
                child: Text(
                  'Tell ${state.buddyName ?? 'Buddy'} about yourself!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF314158),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              // Nickname input
              Text(
                'Your Nickname',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF314158),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Your nickname input field, optional',
                textField: true,
                hint: 'Enter your nickname if you want',
                child: TextField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your nickname (optional)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
              ),

              const SizedBox(height: 32),

              // Age selection
              Text(
                'Your Age',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF314158),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Age selection buttons',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [7, 8, 9, 10, 11, 12].map((age) {
                    final isSelected = _selectedAge == age;
                    return Semantics(
                      button: true,
                      label: 'Age $age',
                      selected: isSelected,
                      hint: isSelected ? 'Selected' : 'Tap to select age $age',
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAge = age;
                          });
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF3B82F6)
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              age.toString(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 48),

              // Continue button
              Semantics(
                button: true,
                label: 'Continue button',
                hint: 'Tap to continue with your profile information',
                child: OnboardingButton(
                  label: 'CONTINUE',
                  onPressed: _handleContinue,
                  isPrimary: true,
                ),
              ),

              const SizedBox(height: 12),

              // Skip button
              Semantics(
                button: true,
                label: 'Skip button',
                hint: 'Tap to skip profile setup',
                child: OnboardingButton(
                  label: 'SKIP',
                  onPressed: _handleSkip,
                  isPrimary: false,
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
