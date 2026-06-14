import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../providers/mood_tracking_provider.dart';
import '../providers/workout_flow_provider.dart';
import '../models/mood_rating.dart';

/// Quick mood check bottom sheet for pre-workout mood tracking
///
/// Displays 5 emoji buttons for mood selection with auto-dismiss timer.
/// Requirements: 2.1, 2.2, 2.3, 2.4, 2.5
class QuickMoodCheckBottomSheet extends ConsumerStatefulWidget {
  final bool isPostWorkout;
  final VoidCallback? onMoodSelected;

  const QuickMoodCheckBottomSheet({
    super.key,
    this.isPostWorkout = false,
    this.onMoodSelected,
  });

  @override
  ConsumerState<QuickMoodCheckBottomSheet> createState() =>
      _QuickMoodCheckBottomSheetState();
}

class _QuickMoodCheckBottomSheetState
    extends ConsumerState<QuickMoodCheckBottomSheet> {
  Timer? _autoSelectTimer;
  int _remainingSeconds = 10;

  @override
  void initState() {
    super.initState();
    _startAutoSelectTimer();
  }

  void _startAutoSelectTimer() {
    final duration = widget.isPostWorkout ? 15 : 10;
    _remainingSeconds = duration;

    _autoSelectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _handleAutoSelect();
      }
    });
  }

  void _handleAutoSelect() {
    if (!mounted) return;

    if (widget.isPostWorkout) {
      // Default to pre-workout mood
      final preMood = ref.read(moodTrackingProvider).preMood;
      if (preMood != null) {
        _selectMood(preMood.value);
      } else {
        _selectMood(3); // Neutral
      }
    } else {
      // Default to neutral
      _selectMood(3);
    }
  }

  void _selectMood(int moodValue) {
    _autoSelectTimer?.cancel();

    if (widget.isPostWorkout) {
      ref.read(moodTrackingProvider.notifier).selectPostMood(moodValue);
    } else {
      ref.read(moodTrackingProvider.notifier).selectPreMood(moodValue);
      final mood = MoodRating.fromValue(moodValue);
      ref.read(workoutFlowProvider.notifier).setPreMood(mood);
    }

    // Dismiss bottom sheet
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();

      // Call the callback if provided
      widget.onMoodSelected?.call();
    }
  }

  @override
  void dispose() {
    _autoSelectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Heading
          Text(
            widget.isPostWorkout
                ? 'How do you feel now?'
                : 'How are you feeling?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Timer text
          Text(
            'Auto-selecting in $_remainingSeconds seconds',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Mood icon buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMoodButton(
                context,
                1,
                SolarIconsBold.sadCircle,
                'Very Bad',
                Colors.red,
              ),
              _buildMoodButton(
                context,
                2,
                SolarIconsBold.confoundedCircle,
                'Bad',
                Colors.orange,
              ),
              _buildMoodButton(
                context,
                3,
                SolarIconsBold.expressionlessCircle,
                'Neutral',
                Colors.grey,
              ),
              _buildMoodButton(
                context,
                4,
                SolarIconsBold.smileCircle,
                'Good',
                Colors.green,
              ),
              _buildMoodButton(
                context,
                5,
                SolarIconsBold.fire,
                'Energized',
                const Color(0xFF3B82F6),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMoodButton(
    BuildContext context,
    int value,
    IconData icon,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);

    return _MoodButtonWithAnimation(
      icon: icon,
      label: label,
      color: color,
      onTap: () => _selectMood(value),
      theme: theme,
    );
  }
}

/// Mood button with scale animation on tap
class _MoodButtonWithAnimation extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final ThemeData theme;

  const _MoodButtonWithAnimation({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.theme,
  });

  @override
  State<_MoodButtonWithAnimation> createState() =>
      _MoodButtonWithAnimationState();
}

class _MoodButtonWithAnimationState extends State<_MoodButtonWithAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse().then((_) {
        widget.onTap();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(widget.icon, size: 32, color: widget.color),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.label,
            style: widget.theme.textTheme.bodySmall?.copyWith(
              color: widget.theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
