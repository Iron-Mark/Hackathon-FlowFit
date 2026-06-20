import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/buddy_character_widget.dart';
import '../../widgets/buddy_idle_animation.dart';
import '../../widgets/buddy_error_widget.dart';
import '../../models/buddy_profile.dart';
import '../../utils/buddy_colors.dart';
import '../../utils/buddy_customization.dart';
import '../../providers/buddy_profile_provider.dart';

/// Buddy Customization Screen
///
/// Allows users to customize their whale Buddy's appearance:
/// - Change color (unlocked colors only)
/// - Select accessories (unlocked items only)
/// - Change background
///
/// Shows locked items with level requirements
class BuddyCustomizationScreen extends ConsumerStatefulWidget {
  const BuddyCustomizationScreen({super.key});

  @override
  ConsumerState<BuddyCustomizationScreen> createState() =>
      _BuddyCustomizationScreenState();
}

class _BuddyCustomizationScreenState
    extends ConsumerState<BuddyCustomizationScreen> {
  String? _selectedColor;
  String? _selectedAccessory;
  String? _selectedBackground;
  bool _isSaving = false;
  int _currentTab = 0; // 0: Colors, 1: Accessories, 2: Backgrounds, 3: Rename
  final TextEditingController _nameController = TextEditingController();
  bool _hasHydratedProfile = false;

  // Available accessories (emoji-based for simplicity)
  static const Map<String, Map<String, dynamic>> accessories = {
    'none': {'emoji': '🚫', 'name': 'None', 'level': 1},
    'crown': {'emoji': '👑', 'name': 'Crown', 'level': 5},
    'hat': {'emoji': '🎩', 'name': 'Top Hat', 'level': 3},
    'sunglasses': {'emoji': '😎', 'name': 'Sunglasses', 'level': 7},
    'party': {'emoji': '🎉', 'name': 'Party Hat', 'level': 4},
    'flower': {'emoji': '🌸', 'name': 'Flower', 'level': 6},
    'star': {'emoji': '⭐', 'name': 'Star', 'level': 8},
    'heart': {'emoji': '💖', 'name': 'Heart', 'level': 10},
  };

  // Available backgrounds
  static const Map<String, Map<String, dynamic>> backgrounds = {
    'ocean': {
      'emoji': '🌊',
      'name': 'Ocean',
      'color': Color(0xFF4ECDC4),
      'level': 1,
    },
    'sunset': {
      'emoji': '🌅',
      'name': 'Sunset',
      'color': Color(0xFFFFB74D),
      'level': 3,
    },
    'forest': {
      'emoji': '🌲',
      'name': 'Forest',
      'color': Color(0xFF66BB6A),
      'level': 5,
    },
    'space': {
      'emoji': '🌌',
      'name': 'Space',
      'color': Color(0xFF9575CD),
      'level': 7,
    },
    'rainbow': {
      'emoji': '🌈',
      'name': 'Rainbow',
      'color': Color(0xFFF06292),
      'level': 9,
    },
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = ref.watch(buddyCustomizationCurrentUserIdProvider);

    if (userId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F6FD),
        appBar: AppBar(
          title: const Text('Customize Your Whale'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Please log in to customize your Buddy'),
        ),
      );
    }

    final buddyProfileAsync = ref.watch(buddyProfileNotifierProvider(userId));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD),
      appBar: AppBar(
        title: const Text('Customize Your Buddy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _handleSave(userId),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTab('Colors', 0),
                _buildTab('Accessories', 1),
                _buildTab('Background', 2),
                _buildTab('Rename', 3),
              ],
            ),
          ),
        ),
      ),
      body: buddyProfileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pets, size: 80, color: Color(0xFF4ECDC4)),
                    const SizedBox(height: 24),
                    const Text(
                      'No Buddy Found',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You need to complete the Buddy onboarding first!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        '/buddy-welcome',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ECDC4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Create Your Buddy'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          _hydrateProfileSelections(profile);

          return _buildContent(theme, profile);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: BuddyErrorWidget(
            message: 'Failed to load Buddy profile',
            onRetry: () => ref.refresh(buddyProfileNotifierProvider(userId)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, profile) {
    final currentLevel = profile.level;
    final currentXP = profile.xp;
    final xpForNextLevel = currentLevel * 100;
    final xpProgress = currentXP % xpForNextLevel;
    final progressPercent = xpProgress / xpForNextLevel;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buddy preview
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _selectedBackground != null
                    ? backgrounds[_selectedBackground]!['color'] as Color
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      BuddyIdleAnimation(
                        child: BuddyCharacterWidget(
                          color: BuddyColors.getColor(
                            _selectedColor ?? profile.color,
                          ),
                          size: 150,
                        ),
                      ),
                      // Show selected accessory
                      if (_selectedAccessory != null &&
                          _selectedAccessory != 'none')
                        Positioned(
                          top: -10,
                          right: -10,
                          child: Text(
                            accessories[_selectedAccessory]!['emoji'] as String,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Buddy name
                  Text(
                    _nameController.text.isNotEmpty
                        ? _nameController.text
                        : profile.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF314158),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Level and XP display (long press for admin level hack)
                  GestureDetector(
                    onLongPress: kDebugMode
                        ? () => _showLevelHack(currentLevel)
                        : null,
                    child: Text(
                      'Level $currentLevel',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF314158),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // XP Progress bar
                  Container(
                    width: 200,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progressPercent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ECDC4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$xpProgress / $xpForNextLevel XP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Tab content
          if (_currentTab == 0) _buildColorsTab(currentLevel, theme),
          if (_currentTab == 1) _buildAccessoriesTab(currentLevel, theme),
          if (_currentTab == 2) _buildBackgroundsTab(currentLevel, theme),
          if (_currentTab == 3) _buildRenameTab(theme),
        ],
      ),
    );
  }

  void _hydrateProfileSelections(BuddyProfile profile) {
    if (_hasHydratedProfile) return;

    _selectedColor = profile.color;
    _selectedAccessory = normalizeBuddyAccessorySelection(
      profile.accessories,
      accessories.keys,
    );
    _selectedBackground = normalizeBuddyBackgroundSelection(
      profile.accessories,
      backgrounds.keys,
    );
    _nameController.text = profile.name;
    _hasHydratedProfile = true;
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? const Color(0xFF4ECDC4)
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF4ECDC4) : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorsTab(int currentLevel, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a Color',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF314158),
          ),
        ),
        const SizedBox(height: 16),
        _buildColorGrid(currentLevel),
      ],
    );
  }

  Widget _buildAccessoriesTab(int currentLevel, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose an Accessory',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF314158),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: accessories.entries.map((entry) {
            final accessoryData = entry.value;
            final isUnlocked = currentLevel >= (accessoryData['level'] as int);
            final isSelected = _selectedAccessory == entry.key;

            return GestureDetector(
              onTap: isUnlocked
                  ? () => setState(() => _selectedAccessory = entry.key)
                  : null,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.white : Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4ECDC4)
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF4ECDC4,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isUnlocked)
                      Text(
                        accessoryData['emoji'] as String,
                        style: const TextStyle(fontSize: 32),
                      )
                    else
                      const Icon(Icons.lock, color: Colors.grey, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      isUnlocked
                          ? accessoryData['name'] as String
                          : 'Lvl ${accessoryData['level']}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isUnlocked ? Colors.black87 : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBackgroundsTab(int currentLevel, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a Background',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF314158),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: backgrounds.entries.map((entry) {
            final bgData = entry.value;
            final isUnlocked = currentLevel >= (bgData['level'] as int);
            final isSelected = _selectedBackground == entry.key;

            return GestureDetector(
              onTap: isUnlocked
                  ? () => setState(() => _selectedBackground = entry.key)
                  : null,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? bgData['color'] as Color
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isUnlocked)
                      Text(
                        bgData['emoji'] as String,
                        style: const TextStyle(fontSize: 40),
                      )
                    else
                      const Icon(Icons.lock, color: Colors.grey, size: 40),
                    const SizedBox(height: 4),
                    Text(
                      isUnlocked
                          ? bgData['name'] as String
                          : 'Lvl ${bgData['level']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnlocked ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRenameTab(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rename Your Buddy',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF314158),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          maxLength: 20,
          decoration: InputDecoration(
            labelText: 'Buddy Name',
            hintText: 'Enter a new name',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 2),
            ),
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose a fun name for your buddy! (1-20 characters)',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildColorGrid(int currentLevel) {
    final colors = BuddyColors.getAllColorsInOrder();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((colorName) {
        final isUnlocked = BuddyColors.isUnlocked(colorName, currentLevel);
        final isSelected = _selectedColor == colorName;
        final color = BuddyColors.getColor(colorName);
        final levelRequired = BuddyColors.getLevelRequirement(colorName);

        return GestureDetector(
          onTap: isUnlocked
              ? () {
                  setState(() {
                    _selectedColor = colorName;
                  });
                }
              : null,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isUnlocked ? color : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                if (isSelected)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                if (!isUnlocked)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, color: Colors.grey, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          'Lvl $levelRequired',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showLevelHack(int currentLevel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Color(0xFFFF9800)),
            SizedBox(width: 8),
            Text('Admin: Set Level'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '⚠️ Admin Tool - For Testing Only',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Select a level to unlock all items:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [1, 3, 5, 7, 10, 15, 20, 50, 100].map((level) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _setLevel(level);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: level == currentLevel
                        ? const Color(0xFF4ECDC4)
                        : Colors.grey[300],
                    foregroundColor: level == currentLevel
                        ? Colors.white
                        : Colors.black87,
                  ),
                  child: Text('Lvl $level'),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _setLevel(int newLevel) async {
    try {
      final userId = ref.read(buddyCustomizationCurrentUserIdProvider);
      if (userId == null) return;

      // Calculate XP for the new level
      final newXP = (newLevel - 1) * 100;

      await ref.read(buddyCustomizationSaveProvider)(userId, {
        'level': newLevel,
        'xp': newXP,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Refresh the provider
      ref.invalidate(buddyProfileNotifierProvider(userId));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔧 Admin: Level set to $newLevel'),
          backgroundColor: const Color(0xFFFF9800),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set level: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSave(String userId) async {
    final nameError = validateBuddyCustomizationName(_nameController.text);
    if (nameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nameError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final profile = ref.read(buddyProfileNotifierProvider(userId)).value;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Load your Buddy profile before saving changes.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updates = buildBuddyCustomizationUpdates(
        profile: profile,
        nameInput: _nameController.text,
        selectedColor: _selectedColor,
        selectedAccessory: _selectedAccessory,
        selectedBackground: _selectedBackground,
        updatedAt: DateTime.now(),
      );

      // Save to database
      await ref.read(buddyCustomizationSaveProvider)(userId, updates);

      // Refresh the provider
      ref.invalidate(buddyProfileNotifierProvider(userId));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buddy customization saved! 🎉'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back after successful save
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _handleSave(userId),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
