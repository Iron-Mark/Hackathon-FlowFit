import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/buddy_onboarding_provider.dart';
import '../../utils/buddy_colors.dart';
import '../../widgets/buddy_character_widget.dart';
import '../../widgets/buddy_idle_animation.dart';
import '../../widgets/onboarding_button.dart';
import '../../theme/app_theme.dart';

/// Screen for naming the Buddy companion - Step 5 of 8
///
/// This screen allows users to give their whale Buddy a unique name with
/// validation and helpful whale-themed suggestions. The Buddy is displayed in the
/// color selected in the previous screen.
///
/// Whale theme: "What do you want to name your baby whale?"
class BuddyNamingScreen extends ConsumerStatefulWidget {
  const BuddyNamingScreen({super.key});

  @override
  ConsumerState<BuddyNamingScreen> createState() => _BuddyNamingScreenState();
}

class _BuddyNamingScreenState extends ConsumerState<BuddyNamingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  String? _errorMessage;

  // Whale-themed name suggestions
  static const List<String> nameSuggestions = [
    'Bubbles',
    'Splash',
    'Wave',
    'Marina',
    'Ocean',
    'Finn',
    'Luna',
    'Neptune',
    'Coral',
    'Pearl',
    'Moby',
    'Tide',
    'Azure',
    'Blue',
    'Aqua',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  // Subtask 7.4: Validate name on input
  void _validateAndUpdateName(String name) {
    setState(() {
      _errorMessage = ref
          .read(buddyOnboardingProvider.notifier)
          .validateBuddyName(name);
    });
  }

  // Subtask 7.3: Handle suggestion tap to auto-fill
  void _onSuggestionTap(String suggestion) {
    _nameController.text = suggestion;
    _validateAndUpdateName(suggestion);
    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  // Subtask 7.4: Save name and navigate to profile setup
  void _onConfirm() {
    final name = _nameController.text.trim();
    final validationError = ref
        .read(buddyOnboardingProvider.notifier)
        .validateBuddyName(name);

    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    // Save name to provider
    ref.read(buddyOnboardingProvider.notifier).setBuddyName(name);

    Navigator.of(context).pushNamed('/buddy_profile_setup');
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(buddyOnboardingProvider);
    final selectedColorKey = onboardingState.selectedColor ?? 'blue';
    final selectedColor = BuddyColors.getColor(selectedColorKey);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              // Subtask 7.1: Display Buddy in selected color
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Subtask 7.1: Buddy character widget
                      _buildBuddyDisplay(selectedColor),

                      const SizedBox(height: 48),

                      // Subtask 7.1: Prompt text
                      _buildPrompt(),

                      const SizedBox(height: 24),

                      // Subtask 7.2: Name input field
                      _buildNameInput(),

                      const SizedBox(height: 32),

                      // Subtask 7.3: Name suggestions
                      _buildNameSuggestions(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Subtask 7.4: Confirmation button
              _buildConfirmationButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Subtask 7.1: Display BuddyCharacterWidget in selected color
  Widget _buildBuddyDisplay(Color selectedColor) {
    return Semantics(
      label: 'Your Buddy character in the color you selected',
      image: true,
      child: Center(
        child: BuddyIdleAnimation(
          child: BuddyCharacterWidget(
            color: selectedColor,
            size: 160.0,
            showFace: true,
          ),
        ),
      ),
    );
  }

  /// Whale-themed prompt
  Widget _buildPrompt() {
    return Semantics(
      header: true,
      child: Column(
        children: [
          Text(
            'What do you want to name your baby whale?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.text,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You can change this later.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.darkGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Subtask 7.2: Create large, friendly text input field
  /// - Set max length to 20 characters
  /// - Add placeholder text
  /// - Style with rounded border and padding
  Widget _buildNameInput() {
    return Semantics(
      label: 'Buddy name input field. Enter a name between 1 and 20 characters',
      textField: true,
      hint: 'Type a name for your Buddy',
      child: TextField(
        controller: _nameController,
        focusNode: _nameFocusNode,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: AppTheme.text,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Enter a name...',
          hintStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.darkGray.withValues(alpha: 0.4),
            fontWeight: FontWeight.normal,
          ),
          errorText: _errorMessage,
          errorStyle: const TextStyle(fontSize: 14, color: Colors.red),
          filled: true,
          fillColor: AppTheme.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.darkGray.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.darkGray.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
        ),
        maxLength: 20,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        textCapitalization: TextCapitalization.words,
        onChanged: _validateAndUpdateName,
        onSubmitted: (_) {
          final name = _nameController.text.trim();
          if (name.isNotEmpty && name.length <= 20) {
            _onConfirm();
          }
        },
      ),
    );
  }

  /// Subtask 7.3: Display name suggestions
  /// - Show suggestions: "Sparky", "Flash", "Star", "Buddy", "Ace"
  /// - Make suggestions tappable to auto-fill
  /// - Style as chips or small buttons
  Widget _buildNameSuggestions() {
    return Semantics(
      label: 'Name suggestions',
      child: Column(
        children: [
          Text(
            'Or pick a suggestion:',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.darkGray),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: nameSuggestions.map((suggestion) {
              return Semantics(
                label: 'Name suggestion: $suggestion',
                button: true,
                hint: 'Tap to use this name',
                child: InkWell(
                  onTap: () => _onSuggestionTap(suggestion),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.darkGray.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        suggestion,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Subtask 7.4: Add "THAT'S PERFECT!" button
  /// - Validate name on input (1-20 characters, not empty)
  /// - Show validation errors in friendly language
  /// - Save name to buddyOnboardingProvider
  /// - Navigate to profile setup screen
  Widget _buildConfirmationButton() {
    // Subtask 7.4: Enable button only when name is valid (no validation errors)
    final trimmedName = _nameController.text.trim();
    final isNameValid =
        trimmedName.isNotEmpty &&
        trimmedName.length <= 20 &&
        _errorMessage == null;

    return SizedBox(
      width: double.infinity,
      child: Semantics(
        label: 'Confirm buddy name button',
        button: true,
        enabled: isNameValid,
        child: OnboardingButton(
          label: 'THAT\'S PERFECT!',
          onPressed: isNameValid ? _onConfirm : null,
          isPrimary: true,
          customColor: const Color(0xFF4CAF50), // Green color
        ),
      ),
    );
  }
}
