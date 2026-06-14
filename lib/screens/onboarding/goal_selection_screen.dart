import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/buddy_onboarding_provider.dart';
import '../../widgets/buddy_character_widget.dart';
import '../../widgets/buddy_idle_animation.dart';
import '../../widgets/onboarding_button.dart';
import '../../theme/app_theme.dart';

/// Wellness Goal Selection Screen - Step 6 of 8
///
/// Multi-select goal cards inspired by whale companion pattern.
/// Kids select areas they want support with.
///
/// Goals:
/// - Boost focus and productivity
/// - Stay fresh and clean
/// - Be more active
/// - Manage stress and anxiety
/// - Strengthen social skills
class GoalSelectionScreen extends ConsumerWidget {
  const GoalSelectionScreen({super.key});

  static const List<WellnessGoal> predefinedGoals = [
    WellnessGoal(
      id: 'focus',
      title: 'Boost focus and productivity',
      icon: '🎯',
    ),
    WellnessGoal(id: 'hygiene', title: 'Stay fresh and clean', icon: '🪥'),
    WellnessGoal(id: 'active', title: 'Be more active', icon: '👟'),
    WellnessGoal(id: 'stress', title: 'Manage stress and anxiety', icon: '🏔️'),
    WellnessGoal(id: 'social', title: 'Strengthen social skills', icon: '☎️'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(buddyOnboardingProvider);
    final selectedGoals = state.selectedGoals;
    final buddyColor = state.selectedColor != null
        ? _getColorFromKey(state.selectedColor!)
        : const Color(0xFF4ECDC4);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress indicator: ●●●●●●○○ (step 6 of 8)
              Semantics(
                label: 'Progress: Step 6 of 8',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    8,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index <= 5
                            ? const Color(0xFF4ECDC4)
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Buddy with lightbulb (thinking pose)
              Semantics(
                label: '${state.buddyName ?? "Buddy"} thinking about goals',
                image: true,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      BuddyIdleAnimation(
                        child: BuddyCharacterWidget(
                          color: buddyColor,
                          size: 100,
                        ),
                      ),
                      Positioned(
                        top: -10,
                        right: -10,
                        child: Semantics(
                          label: 'Lightbulb idea',
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.yellow[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '💡',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Semantics(
                header: true,
                child: Text(
                  'What areas would you like support with?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Select as many as you like',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.darkGray,
                ),
              ),

              const SizedBox(height: 32),

              // Goal cards
              Expanded(
                child: Semantics(
                  label: 'Wellness goals list',
                  child: ListView.separated(
                    itemCount: predefinedGoals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final goal = predefinedGoals[index];
                      final isSelected = selectedGoals.contains(goal.id);

                      return GoalCard(
                        goal: goal,
                        isSelected: isSelected,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(buddyOnboardingProvider.notifier)
                              .toggleGoal(goal.id);
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Next button (always enabled)
              Semantics(
                label: 'Next button',
                button: true,
                hint: 'Continue to notification permissions',
                child: OnboardingButton(
                  label: 'NEXT',
                  onPressed: () {
                    Navigator.pushNamed(context, '/notification-permission');
                  },
                  customColor: const Color(0xFF66BB6A),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorFromKey(String colorKey) {
    const colorMap = {
      'blue': Color(0xFF4ECDC4),
      'teal': Color(0xFF26A69A),
      'green': Color(0xFF66BB6A),
      'purple': Color(0xFF9575CD),
      'yellow': Color(0xFFFFD54F),
      'orange': Color(0xFFFFB74D),
      'pink': Color(0xFFF06292),
      'gray': Color(0xFF90A4AE),
    };
    return colorMap[colorKey] ?? const Color(0xFF4ECDC4);
  }
}

/// Wellness Goal model
class WellnessGoal {
  final String id;
  final String title;
  final String icon;

  const WellnessGoal({
    required this.id,
    required this.title,
    required this.icon,
  });
}

/// Goal Card widget
class GoalCard extends StatelessWidget {
  final WellnessGoal goal;
  final bool isSelected;
  final VoidCallback onTap;

  const GoalCard({
    super.key,
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '${goal.title} goal',
      button: true,
      selected: isSelected,
      hint: isSelected ? 'Tap to deselect' : 'Tap to select',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          // Minimum touch target height of 56px (exceeds 48px requirement)
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xFF66BB6A) : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF66BB6A).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Emoji icon
              Semantics(
                label: _getEmojiLabel(goal.icon),
                child: Text(goal.icon, style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Text(
                  goal.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.text,
                    fontSize: 16, // Minimum 16sp for body text
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Check/Plus icon
              Icon(
                isSelected ? Icons.check_circle : Icons.add_circle_outline,
                color: isSelected ? const Color(0xFF66BB6A) : Colors.grey[400],
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEmojiLabel(String emoji) {
    const emojiLabels = {
      '🎯': 'Target',
      '🪥': 'Toothbrush',
      '👟': 'Sneaker',
      '🏔️': 'Mountain',
      '☎️': 'Phone',
    };
    return emojiLabels[emoji] ?? 'Icon';
  }
}
