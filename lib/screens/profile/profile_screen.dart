import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/page_header.dart';
import '../../presentation/providers/providers.dart';
import '../../core/domain/entities/user_profile.dart';
import '../../core/domain/repositories/profile_repository.dart';

// Profile Screen
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  /// Load profile image path from SharedPreferences
  ///
  /// SharedPreferences Key Format: 'profile_image_{userId}'
  /// - This ensures user-specific storage for multi-user support
  /// - Example: 'profile_image_abc123-def456-ghi789'
  /// - The key is automatically cleaned up if the file no longer exists
  ///
  /// Requirements: 3.2, 3.3, 3.4
  Future<void> _loadProfileImage() async {
    final authState = ref.read(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      // Key format: 'profile_image_{userId}' for user-specific storage
      final key = 'profile_image_$userId';
      final savedPath = prefs.getString(key);

      if (savedPath != null) {
        // Check if file still exists
        final file = File(savedPath);
        if (await file.exists()) {
          if (mounted) {
            setState(() {
              _profileImagePath = savedPath;
            });
          }
        } else {
          // File doesn't exist, cleanup invalid path
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Silently fail on load errors, use default avatar
      debugPrint('Error loading profile image: $e');
    }
  }

  /// Save profile image path to SharedPreferences
  ///
  /// SharedPreferences Key Format: 'profile_image_{userId}'
  /// - Saves the absolute file path to the locally stored image
  /// - Pass null to remove the saved path (e.g., when user removes photo)
  /// - The key is user-specific to support multiple user accounts
  ///
  /// Requirements: 3.1, 3.5
  Future<void> _saveProfileImage(String? path) async {
    final authState = ref.read(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      // Key format: 'profile_image_{userId}' for user-specific storage
      final key = 'profile_image_$userId';

      if (path != null) {
        await prefs.setString(key, path);
      } else {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error saving profile image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Watch auth state to get current user ID
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.user?.id;

    // If no user ID, show empty state
    if (userId == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Column(
          children: [
            PageHeader(
              title: 'Profile',
              subtitle: 'Manage your account',
              trailing: IconButton(
                icon: const Icon(SolarIconsOutline.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ),
            Expanded(child: _buildEmptyState(context)),
          ],
        ),
      );
    }

    // Watch profile data for the current user
    final profileAsync = ref.watch(profileNotifierProvider(userId));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          PageHeader(
            title: 'Profile',
            subtitle: 'Manage your account',
            trailing: IconButton(
              icon: const Icon(SolarIconsOutline.settings),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ),
          Expanded(
            child: profileAsync.when(
              data: (profile) {
                if (profile == null) {
                  return _buildEmptyState(context);
                }
                return _buildProfileContent(context, profile, userId);
              },
              loading: () => _buildLoadingState(context),
              error: (error, stack) => _buildErrorState(context, error, userId),
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading state
  /// Requirements: 10.5
  Widget _buildLoadingState(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }

  /// Build error state with retry button
  /// Requirements: 10.5
  Widget _buildErrorState(BuildContext context, Object error, String userId) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              SolarIconsOutline.dangerTriangle,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Retry loading profile
                ref.invalidate(profileNotifierProvider(userId));
              },
              icon: const Icon(SolarIconsOutline.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state with onboarding prompt
  /// Requirements: 10.5
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              SolarIconsOutline.userCircle,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Complete Your Profile',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get started by completing the onboarding survey to set up your profile.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/survey_intro');
              },
              child: const Text('Complete Onboarding'),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle refresh action
  /// Requirements: 6.1, 6.2, 6.3, 6.4, 6.5
  Future<void> _handleRefresh(BuildContext context, String? userId) async {
    if (userId == null) return;

    try {
      // Get profile notifier and reload profile
      final profileNotifier = ref.read(
        profileNotifierProvider(userId).notifier,
      );
      await profileNotifier.loadProfile();

      // Invalidate sync status providers to refresh them
      ref.invalidate(syncStatusProvider(userId));
      ref.invalidate(pendingSyncCountProvider);

      // Show success snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile refreshed successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error snackbar with details
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh profile: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Build profile content with actual data
  Widget _buildProfileContent(
    BuildContext context,
    UserProfile profile,
    String userId,
  ) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final userEmail = authState.user?.email ?? '';

    return RefreshIndicator(
      onRefresh: () => _handleRefresh(context, userId),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sync Status Bar
            _buildSyncStatusBar(context, userId),

            // Profile Header
            Container(
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showPhotoPickerDialog(context),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primary,
                          backgroundImage: _profileImagePath != null
                              ? FileImage(File(_profileImagePath!))
                              : null,
                          child: _profileImagePath == null
                              ? Text(
                                  _getInitials(profile.fullName ?? 'User'),
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
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Age: ${profile.age ?? 'N/A'} • ${profile.activityLevel ?? 'Not set'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('edit_profile_button'),
                    icon: Icon(
                      SolarIconsOutline.pen,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      _navigateToEditProfile(context, profile);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // My Account Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'My Account',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoItem(context, 'Sex', profile.gender ?? 'Not set'),
            _buildInfoItem(
              context,
              'Age',
              profile.age != null ? '${profile.age} years' : 'Not set',
            ),
            _buildInfoItem(context, 'Email', userEmail),
            _buildSettingItem(
              context,
              'Change Password',
              SolarIconsOutline.lock,
              onTap: () {
                Navigator.pushNamed(context, '/change-password');
              },
            ),
            _buildSettingItem(
              context,
              'Delete Account',
              SolarIconsOutline.trashBinMinimalistic,
              onTap: () {
                Navigator.pushNamed(context, '/delete-account');
              },
            ),
            _buildSettingItem(
              context,
              'Logout',
              SolarIconsOutline.logout,
              onTap: () => _handleLogout(context),
            ),

            const SizedBox(height: 24),

            // My Goals Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'My Goals',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildGoalItem(
              context,
              'Physical Stats',
              'Weight: ${profile.weight ?? 'N/A'} ${profile.weightUnit ?? 'lbs'} • Height: ${profile.height ?? 'N/A'} ${profile.heightUnit ?? 'in'}',
              onTap: () {
                Navigator.pushNamed(context, '/weight-goals');
              },
            ),
            _buildGoalItem(
              context,
              'Fitness Goals',
              'Activity Level: ${profile.activityLevel ?? 'Not set'}${profile.goals != null && profile.goals!.isNotEmpty ? ' • ${profile.goals!.join(", ")}' : ''}',
              onTap: () {
                Navigator.pushNamed(context, '/fitness-goals');
              },
            ),
            _buildGoalItem(
              context,
              'Nutrition Goals',
              'Daily Calorie Target: ${profile.dailyCalorieTarget ?? 'Not set'} calories',
              onTap: () {
                Navigator.pushNamed(context, '/nutrition-goals');
              },
            ),

            const SizedBox(height: 24),

            // Progress Timeline Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress Timeline',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTimelineButton(context, 'All', true),
                        const SizedBox(width: 8),
                        _buildTimelineButton(context, '1 Week', false),
                        const SizedBox(width: 8),
                        _buildTimelineButton(context, '1 Month', false),
                        const SizedBox(width: 8),
                        _buildTimelineButton(context, '3 Months', false),
                        const SizedBox(width: 8),
                        _buildTimelineButton(context, '6 Months', false),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Weight Progress Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${profile.weight ?? 'N/A'} ${profile.weightUnit ?? 'lbs'}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Current',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Simple chart placeholder
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Weight Chart',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Jan', style: theme.textTheme.bodySmall),
                        Text('Feb', style: theme.textTheme.bodySmall),
                        Text('Mar', style: theme.textTheme.bodySmall),
                        Text('Apr', style: theme.textTheme.bodySmall),
                        Text('May', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Extract initials from full name
  /// Requirements: 10.4
  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
        // Save to SharedPreferences
        await _saveProfileImage(image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
        // Save to SharedPreferences
        await _saveProfileImage(image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting photo: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _removePhoto() async {
    setState(() {
      _profileImagePath = null;
    });
    // Clear from SharedPreferences
    await _saveProfileImage(null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo removed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Handle logout with confirmation dialog
  /// Requirements: 8.1, 8.2, 8.3, 8.4, 8.5
  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    // If user confirmed, proceed with logout
    if (confirmed == true && context.mounted) {
      try {
        // Sign out from authentication service
        await ref.read(authNotifierProvider.notifier).signOut();

        // Navigate to welcome screen and clear navigation history
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/welcome', (route) => false);
        }
      } catch (e) {
        // Show error snackbar on failure
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// Navigate to edit profile (survey flow)
  /// Requirements: 7.1, 7.2, 7.3
  void _navigateToEditProfile(BuildContext context, UserProfile profile) {
    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Navigate to survey basic info screen with edit mode flag
    Navigator.pushNamed(
      context,
      '/survey_basic_info',
      arguments: {'userId': profile.userId, 'fromEdit': true},
    );
  }

  void _showPhotoPickerDialog(BuildContext context) {
    // Provide haptic feedback when opening photo picker
    // Requirements: 4.2
    HapticFeedback.lightImpact();

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Change Profile Photo',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      SolarIconsOutline.camera,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      SolarIconsOutline.gallery,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
                if (_profileImagePath != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        SolarIconsOutline.trashBinMinimalistic,
                        color: Colors.red,
                      ),
                    ),
                    title: const Text(
                      'Remove Photo',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _removePhoto();
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build sync status bar
  /// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6
  Widget _buildSyncStatusBar(BuildContext context, String userId) {
    final theme = Theme.of(context);
    final syncStatusAsync = ref.watch(syncStatusProvider(userId));
    final pendingSyncCountAsync = ref.watch(pendingSyncCountProvider);

    return syncStatusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (syncStatus) {
        // Determine display based on sync status
        String statusText;
        Color statusColor;
        IconData statusIcon;

        switch (syncStatus) {
          case SyncStatus.synced:
            // Hide status bar when synced
            return const SizedBox.shrink();
          case SyncStatus.syncing:
            statusText = 'Syncing...';
            statusColor = theme.colorScheme.primary;
            statusIcon = SolarIconsOutline.refresh;
            break;
          case SyncStatus.pendingSync:
            final pendingCount = pendingSyncCountAsync.valueOrNull ?? 0;
            statusText = pendingCount > 0
                ? 'Pending sync ($pendingCount)'
                : 'Pending sync';
            statusColor = Colors.orange;
            statusIcon = SolarIconsOutline.cloudUpload;
            break;
          case SyncStatus.syncFailed:
            statusText = 'Sync failed - will retry';
            statusColor = Colors.red;
            statusIcon = SolarIconsOutline.dangerTriangle;
            break;
          case SyncStatus.offline:
            statusText = 'Offline';
            statusColor = Colors.grey;
            statusIcon = SolarIconsOutline.cloudCross;
            break;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: statusColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(statusIcon, size: 20, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    IconData icon, {
    VoidCallback? onTap,
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
        onTap: onTap ?? () {},
      ),
    );
  }

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

  Widget _buildGoalItem(
    BuildContext context,
    String title,
    String description, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      color: theme.colorScheme.surface,
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          SolarIconsOutline.altArrowRight,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: onTap ?? () {},
      ),
    );
  }

  Widget _buildTimelineButton(
    BuildContext context,
    String label,
    bool isSelected,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
