import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/buddy_onboarding_provider.dart';
import '../../utils/buddy_colors.dart';
import '../../widgets/buddy_character_widget.dart';
import '../../widgets/buddy_idle_animation.dart';
import '../../widgets/onboarding_button.dart';
import '../../theme/app_theme.dart';

/// Screen for quick profile setup during Buddy onboarding
class BuddyProfileSetupScreen extends ConsumerStatefulWidget {
  const BuddyProfileSetupScreen({super.key});

  @override
  ConsumerState<BuddyProfileSetupScreen> createState() =>
      _BuddyProfileSetupScreenState();
}

class _BuddyProfileSetupScreenState
    extends ConsumerState<BuddyProfileSetupScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final FocusNode _nicknameFocusNode = FocusNode();
  int? _selectedAge;

  static const List<int> ageOptions = [7, 8, 9, 10, 11, 12];

  @override
  void dispose() {
    _nicknameController.dispose();
    _nicknameFocusNode.dispose();
    super.dispose();
  }

  void _onAgeSelected(int age) {
    setState(() {
      _selectedAge = age;
    });
    HapticFeedback.lightImpact();
  }

  void _onSkip() {
    Navigator.of(context).pushNamed('/goal-selection');
  }

  void _onContinue() {
    final nickname = _nicknameController.text.trim();
    ref
        .read(buddyOnboardingProvider.notifier)
        .setUserInfo(nickname.isEmpty ? null : nickname, _selectedAge);
    Navigator.of(context).pushNamed('/goal-selection');
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(buddyOnboardingProvider);
    final selectedColorKey = onboardingState.selectedColor ?? 'blue';
    final selectedColor = BuddyColors.getColor(selectedColorKey);
    final buddyName = onboardingState.buddyName ?? 'Buddy';
    assert(() {
      debugPrint('BuddyProfileSetupScreen: rendered buddy=$buddyName');
      return true;
    }());

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildBuddyDisplay(selectedColor, buddyName),
                      const SizedBox(height: 32),
                      _buildPrompt(buddyName),
                      const SizedBox(height: 32),
                      _buildNicknameInput(),
                      const SizedBox(height: 32),
                      _buildAgeSelection(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuddyDisplay(Color selectedColor, String buddyName) {
    return Column(
      children: [
        Center(
          child: BuddyIdleAnimation(
            child: BuddyCharacterWidget(
              color: selectedColor,
              size: 140.0,
              showFace: true,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          buddyName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPrompt(String buddyName) {
    return Text(
      'Tell $buddyName about yourself!',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: AppTheme.text,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildNicknameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Your Nickname (optional)',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.darkGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Semantics(
          label: 'Nickname input field',
          textField: true,
          child: TextField(
            controller: _nicknameController,
            focusNode: _nicknameFocusNode,
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.text,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'What should we call you?',
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.darkGray.withValues(alpha: 0.4),
                fontWeight: FontWeight.normal,
              ),
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
                borderSide: const BorderSide(
                  color: AppTheme.primaryBlue,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            maxLength: 20,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textCapitalization: TextCapitalization.words,
          ),
        ),
      ],
    );
  }

  Widget _buildAgeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Your Age (optional)',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.darkGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: ageOptions.map((age) {
            final isSelected = _selectedAge == age;
            return Semantics(
              label: 'Age $age',
              button: true,
              selected: isSelected,
              child: InkWell(
                onTap: () => _onAgeSelected(age),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.darkGray.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      age.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isSelected ? Colors.white : AppTheme.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: 'Skip profile setup button',
            button: true,
            child: OnboardingButton(
              label: 'SKIP',
              onPressed: _onSkip,
              isPrimary: false,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Semantics(
            label: 'Continue to completion button',
            button: true,
            child: OnboardingButton(
              label: 'CONTINUE',
              onPressed: _onContinue,
              isPrimary: true,
              customColor: const Color(0xFF4CAF50),
            ),
          ),
        ),
      ],
    );
  }
}
