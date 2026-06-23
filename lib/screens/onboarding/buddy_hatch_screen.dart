import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/buddy_character_widget.dart';
import '../../widgets/buddy_celebration_animation.dart';

/// Buddy Hatch Screen - Step 3 of 8
///
/// Delightful micro-interaction showing "You found a baby whale!"
/// Auto-advances to color selection after 2 seconds.
///
/// Whale-themed onboarding flow implementation.
class BuddyHatchScreen extends ConsumerStatefulWidget {
  const BuddyHatchScreen({super.key});

  @override
  ConsumerState<BuddyHatchScreen> createState() => _BuddyHatchScreenState();
}

class _BuddyHatchScreenState extends ConsumerState<BuddyHatchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5),
      ),
    );

    _animationController.forward();

    // Auto-advance after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/buddy-color-selection');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    assert(() {
      debugPrint('BuddyHatchScreen: rendered');
      return true;
    }());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Buddy
              Semantics(
                label: 'Baby whale appearing with celebration animation',
                image: true,
                liveRegion: true,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: const BuddyCelebrationAnimation(
                    child: BuddyCharacterWidget(
                      color: Color(0xFF4ECDC4), // Ocean Blue
                      size: 180,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // "You found a baby whale!" text
              Semantics(
                label: 'You found a baby whale!',
                liveRegion: true,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'You found a baby whale!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFF314158),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('🐋', style: TextStyle(fontSize: 48)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
