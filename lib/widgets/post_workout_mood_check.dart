import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/mood_tracking_provider.dart';

/// Post-workout mood check screen
///
/// Displays 5 emoji buttons for mood selection with auto-dismiss timer.
/// Defaults to pre-workout mood if no selection within 15 seconds.
/// Requirements: 10.1, 10.2, 10.4
class PostWorkoutMoodCheck extends ConsumerStatefulWidget {
  final String sessionId;

  const PostWorkoutMoodCheck({super.key, required this.sessionId});

  @override
  ConsumerState<PostWorkoutMoodCheck> createState() =>
      _PostWorkoutMoodCheckState();
}

class _PostWorkoutMoodCheckState extends ConsumerState<PostWorkoutMoodCheck> {
  Timer? _autoSelectTimer;
  int _remainingSeconds = 15;

  @override
  void initState() {
    super.initState();
    _startAutoSelectTimer();
  }

  void _startAutoSelectTimer() {
    _autoSelectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

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

    // Default to pre-workout mood
    final preMood = ref.read(moodTrackingProvider).preMood;
    if (preMood != null) {
      _selectMood(preMood.value);
    } else {
      _selectMood(3); // Neutral fallback
    }
  }

  void _selectMood(int moodValue) {
    _autoSelectTimer?.cancel();

    ref.read(moodTrackingProvider.notifier).selectPostMood(moodValue);

    // Navigate to workout summary
    if (mounted) {
      // The navigation path will depend on workout type
      // For now, we'll use a generic summary route
      context.go('/workout/summary/${widget.sessionId}');
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
    final preMood = ref.watch(moodTrackingProvider).preMood;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Heading
              Text(
                'How do you feel now?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Pre-mood reminder
              if (preMood != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'You started feeling: ${preMood.emoji}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Timer text
              Text(
                'Auto-selecting in $_remainingSeconds seconds',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),

              // Emoji buttons
              Wrap(
                spacing: 16,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _buildMoodButton(context, 1, '😢', 'Very Bad'),
                  _buildMoodButton(context, 2, '😕', 'Bad'),
                  _buildMoodButton(context, 3, '😐', 'Neutral'),
                  _buildMoodButton(context, 4, '🙂', 'Good'),
                  _buildMoodButton(context, 5, '💪', 'Energized'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodButton(
    BuildContext context,
    int value,
    String emoji,
    String label,
  ) {
    final theme = Theme.of(context);

    return _MoodButtonWithAnimation(
      emoji: emoji,
      label: label,
      onTap: () => _selectMood(value),
      theme: theme,
    );
  }
}

/// Mood button with scale animation on tap
class _MoodButtonWithAnimation extends StatefulWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;

  const _MoodButtonWithAnimation({
    required this.emoji,
    required this.label,
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
                color: widget.theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(widget.emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.label,
            style: widget.theme.textTheme.bodySmall?.copyWith(
              color: widget.theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
