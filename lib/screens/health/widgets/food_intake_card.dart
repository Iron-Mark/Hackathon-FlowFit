import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

// Food intake card with calorie progress, meal tabs, and logged food items.
class FoodIntakeCard extends StatelessWidget {
  const FoodIntakeCard({
    super.key,
    required this.totalCalories,
    required this.calorieGoal,
    required this.calorieProgress,
    required this.selectedMealTab,
    required this.foodItems,
    required this.isShowingAddFoodDialog,
    required this.onAddFood,
    required this.onSelectMealTab,
    required this.onRemoveFoodItem,
  });

  final int totalCalories;
  final int calorieGoal;
  final double calorieProgress;
  final String selectedMealTab;
  final List<Map<String, String>> foodItems;
  final bool isShowingAddFoodDialog;
  final VoidCallback onAddFood;
  final ValueChanged<String> onSelectMealTab;
  final ValueChanged<int> onRemoveFoodItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          SolarIconsBold.hamburgerMenu,
                          size: 24,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Food Intake',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$totalCalories/$calorieGoal kcal',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isShowingAddFoodDialog ? null : onAddFood,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Food'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: calorieProgress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
              ),
            ),

            const SizedBox(height: 20),

            // Meal Type Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMealTab(context, 'Breakfast'),
                  const SizedBox(width: 8),
                  _buildMealTab(context, 'Lunch'),
                  const SizedBox(width: 8),
                  _buildMealTab(context, 'Dinner'),
                  const SizedBox(width: 8),
                  _buildMealTab(context, 'Snacks'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Food Items
            ...foodItems.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFoodItem(
                  context,
                  entry.value['name']!,
                  entry.value['calories']!,
                  onRemove: () => onRemoveFoodItem(entry.key),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTab(BuildContext context, String label) {
    final theme = Theme.of(context);
    final isSelected = selectedMealTab == label;

    return GestureDetector(
      onTap: () => onSelectMealTab(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.surfaceContainerHighest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFoodItem(
    BuildContext context,
    String name,
    String calories, {
    required VoidCallback onRemove,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                calories,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Food actions',
          icon: Icon(
            Icons.more_vert,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onSelected: (value) {
            if (value == 'remove') {
              onRemove();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18),
                  SizedBox(width: 8),
                  Text('Remove'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
