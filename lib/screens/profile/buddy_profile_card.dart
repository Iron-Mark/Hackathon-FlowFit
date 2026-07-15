import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:flowfit/models/buddy_profile.dart';
import 'package:flowfit/widgets/buddy_character_widget.dart';
import 'package:flowfit/widgets/buddy_idle_animation.dart';

/// Buddy Profile Card Widget
///
/// Displays the user's whale Buddy companion with:
/// - Animated whale Buddy character in current color
/// - Buddy name and level
/// - XP progress bar
/// - Quick access to customization
///
/// Requirements: MAIN-FEATURES.MD - Kids Dashboard
class BuddyProfileCard extends StatelessWidget {
  final BuddyProfile buddyProfile;
  final VoidCallback? onCustomizeTap;

  const BuddyProfileCard({
    super.key,
    required this.buddyProfile,
    this.onCustomizeTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xpProgress = _calculateXPProgress();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getBuddyColor().withValues(alpha: 0.1),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getBuddyColor().withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Buddy Character with Animation
          SizedBox(
            height: 120,
            child: BuddyIdleAnimation(
              child: BuddyCharacterWidget(color: _getBuddyColor(), size: 100),
            ),
          ),

          const SizedBox(height: 16),

          // Buddy Name and Level
          Text(
            buddyProfile.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF314158),
            ),
          ),

          const SizedBox(height: 4),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getBuddyColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Level ${buddyProfile.level} • ${_getStageName()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _getBuddyColor(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // XP Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'XP Progress',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${buddyProfile.xp} / ${_getXPForNextLevel()} XP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: xpProgress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(_getBuddyColor()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Customize Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCustomizeTap,
              icon: Icon(SolarIconsOutline.palette, color: _getBuddyColor()),
              label: const Text('Customize Buddy'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _getBuddyColor(),
                side: BorderSide(color: _getBuddyColor()),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get Buddy color from hex string
  Color _getBuddyColor() {
    // Map color names to hex values (from MAIN-FEATURES.MD)
    final colorMap = {
      'blue': const Color(0xFF4ECDC4),
      'teal': const Color(0xFF26A69A),
      'green': const Color(0xFF66BB6A),
      'purple': const Color(0xFF9575CD),
      'yellow': const Color(0xFFFFD54F),
      'orange': const Color(0xFFFFB74D),
      'pink': const Color(0xFFF06292),
      'navy': const Color(0xFF5C6BC0),
    };

    return colorMap[buddyProfile.color] ?? const Color(0xFF4ECDC4);
  }

  /// Get stage name based on level
  String _getStageName() {
    if (buddyProfile.level <= 5) return 'Baby';
    if (buddyProfile.level <= 10) return 'Kid';
    if (buddyProfile.level <= 20) return 'Teen';
    if (buddyProfile.level <= 30) return 'Super';
    return 'Mega';
  }

  /// Calculate XP needed for next level
  int _getXPForNextLevel() {
    return (buddyProfile.level + 1) * 100;
  }

  /// Calculate XP progress (0.0 to 1.0)
  double _calculateXPProgress() {
    final xpForNext = _getXPForNextLevel();
    return (buddyProfile.xp % xpForNext) / xpForNext;
  }
}
