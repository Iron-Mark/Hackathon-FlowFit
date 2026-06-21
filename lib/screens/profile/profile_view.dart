import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../core/domain/entities/user_profile.dart';
import '../../core/utils/height_measurements.dart';

/// ProfileView Widget - Displays user profile data
///
/// This widget displays all user profile information collected during onboarding
/// including personal information, fitness goals, and daily targets.
class ProfileView extends ConsumerWidget {
  final UserProfile profile;
  final String? profileImagePath;
  final VoidCallback onPhotoTap;
  final VoidCallback? onEditTap;
  final String userEmail;
  final VoidCallback? onLogout;

  const ProfileView({
    super.key,
    required this.profile,
    this.profileImagePath,
    required this.onPhotoTap,
    this.onEditTap,
    required this.userEmail,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          _buildProfileHeader(context, theme),
          const SizedBox(height: 16),

          // Personal Information Section
          _buildSectionTitle(context, theme, 'Personal Information'),
          const SizedBox(height: 12),
          _buildInfoItem(context, 'Gender', _formatGender()),
          _buildInfoItem(context, 'Age', profile.age?.toString() ?? 'Not set'),
          _buildInfoItem(context, 'Height', _formatHeight()),
          _buildInfoItem(context, 'Weight', _formatWeight()),
          _buildInfoItem(context, 'Activity Level', _formatActivityLevel()),

          const SizedBox(height: 16),

          // Fitness Goals Section
          if (profile.goals != null && profile.goals!.isNotEmpty) ...[
            _buildSectionTitle(context, theme, 'Fitness Goals'),
            const SizedBox(height: 12),
            _buildGoalsSection(context, theme),
            const SizedBox(height: 16),
          ],

          // Daily Targets Section
          _buildSectionTitle(context, theme, 'Daily Targets'),
          const SizedBox(height: 12),
          _buildInfoItem(
            context,
            'Calories',
            profile.dailyCalorieTarget != null
                ? '${profile.dailyCalorieTarget} kcal'
                : 'Not set',
          ),
          _buildInfoItem(
            context,
            'Steps',
            profile.dailyStepsTarget != null
                ? '${profile.dailyStepsTarget} steps'
                : 'Not set',
          ),
          _buildInfoItem(
            context,
            'Active Minutes',
            profile.dailyActiveMinutesTarget != null
                ? '${profile.dailyActiveMinutesTarget} min'
                : 'Not set',
          ),
          _buildInfoItem(
            context,
            'Water',
            profile.dailyWaterTarget != null
                ? '${profile.dailyWaterTarget!.toStringAsFixed(1)} L'
                : 'Not set',
          ),

          const SizedBox(height: 16),

          // Account Section
          _buildSectionTitle(context, theme, 'Account'),
          const SizedBox(height: 12),
          _buildSettingItem(
            context,
            'Change Password',
            SolarIconsOutline.lock,
            onTap: () {
              Navigator.pushNamed(context, '/change-password');
            },
          ),
          if (onLogout != null)
            _buildSettingItem(
              context,
              'Logout',
              SolarIconsOutline.logout,
              onTap: onLogout!,
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Build profile header with avatar and basic info
  Widget _buildProfileHeader(BuildContext context, ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPhotoTap,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primary,
                  backgroundImage: profileImagePath != null
                      ? FileImage(File(profileImagePath!))
                      : null,
                  child: profileImagePath == null
                      ? Text(
                          _getInitials(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      SolarIconsOutline.camera,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName ?? 'User',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getEmail(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Edit button in header (Requirement 4.1, 4.5)
          if (onEditTap != null)
            IconButton(
              icon: Icon(
                SolarIconsOutline.pen,
                color: theme.colorScheme.primary,
              ),
              onPressed: onEditTap,
              tooltip: 'Edit Profile',
            ),
        ],
      ),
    );
  }

  /// Build section title with optional edit button
  Widget _buildSectionTitle(
    BuildContext context,
    ThemeData theme,
    String title, {
    bool showEditButton = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          // Edit button for individual sections (Requirement 4.1, 4.5)
          if (showEditButton && onEditTap != null)
            TextButton.icon(
              onPressed: onEditTap,
              icon: Icon(
                SolarIconsOutline.pen,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              label: Text(
                'Edit',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  /// Build fitness goals section with chips
  Widget _buildGoalsSection(BuildContext context, ThemeData theme) {
    // Goal definitions with icons and colors
    final goalDefinitions = {
      'lose_weight': {
        'title': 'Lose Weight',
        'icon': SolarIconsBold.fire,
        'color': Colors.orange,
      },
      'maintain_weight': {
        'title': 'Maintain Weight',
        'icon': SolarIconsBold.scale,
        'color': Colors.green,
      },
      'build_muscle': {
        'title': 'Build Muscle',
        'icon': SolarIconsBold.dumbbellSmall,
        'color': Colors.purple,
      },
      'improve_cardio': {
        'title': 'Improve Cardio',
        'icon': SolarIconsBold.heartPulse,
        'color': Colors.red,
      },
    };

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: profile.goals!.map<Widget>((goal) {
          final goalDef = goalDefinitions[goal];
          final title =
              goalDef?['title'] as String? ??
              goal
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map((word) => word[0].toUpperCase() + word.substring(1))
                  .join(' ');
          final icon = goalDef?['icon'] as IconData? ?? SolarIconsBold.target;
          final color = goalDef?['color'] as Color? ?? Colors.blue;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build info item row
  Widget _buildInfoItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build setting item with icon and navigation
  Widget _buildSettingItem(
    BuildContext context,
    String title,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      color: theme.colorScheme.surface,
      child: ListTile(
        leading: Icon(
          icon,
          color: title == 'Logout'
              ? Colors.red
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: TextStyle(color: title == 'Logout' ? Colors.red : null),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }

  // Helper methods for formatting data

  /// Get initials from user's full name
  String _getInitials() {
    if (profile.fullName != null && profile.fullName!.isNotEmpty) {
      final parts = profile.fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return profile.fullName![0].toUpperCase();
    }
    return 'U';
  }

  /// Format height with unit
  String _formatHeight() {
    if (profile.height == null) return 'Not set';
    final unit = profile.heightUnit ?? 'cm';
    if (unit == 'ft') {
      return formatHeightMeasurement(profile.height!, unit);
    }
    return '${profile.height!.toStringAsFixed(1)} $unit';
  }

  /// Format weight with unit
  String _formatWeight() {
    if (profile.weight == null) return 'Not set';
    final unit = profile.weightUnit ?? 'kg';
    return '${profile.weight!.toStringAsFixed(1)} $unit';
  }

  /// Format activity level for display
  String _formatActivityLevel() {
    if (profile.activityLevel == null) return 'Not set';
    switch (profile.activityLevel) {
      case 'sedentary':
        return 'Sedentary';
      case 'moderately_active':
        return 'Moderately Active';
      case 'very_active':
        return 'Very Active';
      default:
        return profile.activityLevel!;
    }
  }

  /// Format gender for display
  String _formatGender() {
    if (profile.gender == null) return 'Not set';
    return profile.gender![0].toUpperCase() + profile.gender!.substring(1);
  }

  /// Get email for display in header
  String _getEmail() {
    return userEmail;
  }
}
