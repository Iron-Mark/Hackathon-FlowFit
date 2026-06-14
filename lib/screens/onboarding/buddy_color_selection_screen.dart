import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/buddy_onboarding_provider.dart';
import '../../widgets/buddy_character_widget.dart';
import '../../widgets/buddy_egg_widget.dart';
import '../../widgets/buddy_idle_animation.dart';
import '../../widgets/onboarding_button.dart';
import '../../theme/app_theme.dart';

/// Screen for selecting Buddy's starting color via egg selection - Step 4 of 8
///
/// This screen allows users to choose from 6 whale color options displayed as eggs
/// in a circular pattern around a central Buddy preview. The preview updates
/// in real-time as colors are selected.
///
/// Whale-themed: "Choose your Whale Color!"
/// Subtitle: "Whales are gentle, playful, and smart..."
class BuddyColorSelectionScreen extends ConsumerStatefulWidget {
  const BuddyColorSelectionScreen({super.key});

  @override
  ConsumerState<BuddyColorSelectionScreen> createState() =>
      _BuddyColorSelectionScreenState();
}

class _BuddyColorSelectionScreenState
    extends ConsumerState<BuddyColorSelectionScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller for color transition
  late AnimationController _colorTransitionController;
  late Animation<double> _colorTransitionAnimation;

  // Color palette for Buddy options
  static const Map<String, Color> colorOptions = {
    'blue': Color(0xFF4ECDC4), // Ocean Blue (default)
    'teal': Color(0xFF26A69A), // Calm Teal
    'green': Color(0xFF66BB6A), // Fresh Green
    'purple': Color(0xFF9575CD), // Soft Purple
    'yellow': Color(0xFFFFD54F), // Gentle Yellow
    'orange': Color(0xFFFFB74D), // Warm Orange
    'pink': Color(0xFFF06292), // Happy Pink
    'gray': Color(0xFF90A4AE), // Cool Gray
  };

  @override
  void initState() {
    super.initState();
    _colorTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _colorTransitionAnimation = CurvedAnimation(
      parent: _colorTransitionController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _colorTransitionController.dispose();
    super.dispose();
  }

  void _onColorSelected(String colorKey) {
    // Update state
    ref.read(buddyOnboardingProvider.notifier).selectColor(colorKey);

    // Trigger color transition animation
    _colorTransitionController.forward(from: 0.0);
  }

  void _onHatchEgg() {
    // Navigate to naming screen
    Navigator.of(context).pushNamed('/buddy-naming');
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(buddyOnboardingProvider);
    final selectedColorKey = onboardingState.selectedColor;
    final selectedColor = selectedColorKey != null
        ? colorOptions[selectedColorKey] ?? colorOptions['gray']!
        : colorOptions['gray']!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              // Subtask 6.1: Heading and subtitle
              _buildHeader(),

              const SizedBox(height: 48),

              // Subtask 6.3: Central Buddy preview with color transition
              Expanded(child: Center(child: _buildBuddyPreview(selectedColor))),

              const SizedBox(height: 32),

              // Subtask 6.2: Color options layout
              _buildColorOptions(selectedColorKey),

              const SizedBox(height: 32),

              // Subtask 6.5: Confirmation button
              _buildConfirmationButton(selectedColorKey),
            ],
          ),
        ),
      ),
    );
  }

  /// Whale-themed header
  Widget _buildHeader() {
    return Semantics(
      header: true,
      child: Column(
        children: [
          // Heading
          Text(
            'Choose your Whale Color!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.text,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Whale personality subtitle
          Semantics(
            label:
                'Whales are gentle, playful, and smart. Pick a color that makes you smile!',
            child: Text(
              'Whales are gentle, playful, and smart...\nPick a color that makes you smile! 🐋',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.darkGray),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Subtask 6.3: Add central Buddy preview with smooth color transition
  Widget _buildBuddyPreview(Color selectedColor) {
    return Semantics(
      label: 'Buddy preview showing selected color',
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _colorTransitionAnimation,
        builder: (context, child) {
          return BuddyIdleAnimation(
            child: BuddyCharacterWidget(
              color: selectedColor,
              size: 180.0,
              showFace: true,
            ),
          );
        },
      ),
    );
  }

  /// Subtask 6.2: Implement color options layout
  /// Arranges 8 eggs in a circular pattern with 16px minimum spacing
  Widget _buildColorOptions(String? selectedColorKey) {
    return SizedBox(
      height: 280,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final centerX = constraints.maxWidth / 2;
          const centerY = 140.0; // Half of height
          const radius = 100.0; // Radius of the circular arrangement

          return Stack(
            children: colorOptions.entries.map((entry) {
              final index = colorOptions.keys.toList().indexOf(entry.key);
              final angle = (index * 2 * math.pi) / colorOptions.length;

              // Calculate position in circular pattern
              final x =
                  centerX + radius * math.cos(angle) - 40; // 40 = half egg size
              final y =
                  centerY +
                  radius * math.sin(angle) -
                  48; // 48 = half egg height

              return Positioned(
                left: x,
                top: y,
                child: Semantics(
                  label: '${entry.key} color egg',
                  button: true,
                  selected: selectedColorKey == entry.key,
                  child: BuddyEggWidget(
                    baseColor: entry.value,
                    isSelected: selectedColorKey == entry.key,
                    onTap: () => _onColorSelected(entry.key),
                    size: 80.0,
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  /// Subtask 6.5: Add confirmation button
  /// Enabled only when a color is selected
  Widget _buildConfirmationButton(String? selectedColorKey) {
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        label: 'Hatch egg button',
        button: true,
        enabled: selectedColorKey != null,
        child: OnboardingButton(
          label: 'Hatch egg',
          onPressed: selectedColorKey != null ? _onHatchEgg : null,
          isPrimary: true,
          customColor: const Color(0xFF4CAF50), // Green color
        ),
      ),
    );
  }
}
