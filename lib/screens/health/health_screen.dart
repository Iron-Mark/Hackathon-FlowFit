import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solar_icons/solar_icons.dart';

enum HealthInitialAction { addWater, addMeal }

// Health Screen
class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key, this.initialAction});

  final HealthInitialAction? initialAction;

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  // State variables
  DateTime _selectedDate = DateTime.now();
  final double _waterGoal = 2.0;
  final int _calorieGoal = 2000;
  String _selectedMealTab = 'Breakfast';
  late final Map<String, _DailyHealthLog> _dailyLogs = {
    _dateKey(_selectedDate): _DailyHealthLog.seeded(),
  };

  _DailyHealthLog get _selectedLog =>
      _dailyLogs.putIfAbsent(_dateKey(_selectedDate), _DailyHealthLog.empty);

  int get _totalCalories => _selectedLog.foodItems.values
      .expand((items) => items)
      .fold(0, (total, item) => total + _parseCalories(item['calories']));

  double get _calorieProgress =>
      (_totalCalories / _calorieGoal).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    final initialAction = widget.initialAction;
    if (initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleInitialAction(initialAction);
      });
    }
  }

  void _handleInitialAction(HealthInitialAction action) {
    switch (action) {
      case HealthInitialAction.addWater:
        _updateWater(0.25);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added 250 ml of water to today\'s log.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      case HealthInitialAction.addMeal:
        _showAddFoodDialog();
        return;
    }
  }

  void _updateWater(double amount) {
    setState(() {
      _selectedLog.waterIntake = (_selectedLog.waterIntake + amount).clamp(
        0.0,
        _waterGoal * 2,
      );
    });
  }

  void _removeFoodItem(String mealTab, int index) {
    final items = _selectedLog.foodItems[mealTab];
    if (items == null || index < 0 || index >= items.length) {
      return;
    }

    final removedItem = items[index];
    setState(() {
      items.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removedItem['name']} removed from $mealTab'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _selectedMealTab = 'Breakfast';
    });
  }

  String _dateKey(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String();

  int _parseCalories(String? value) {
    if (value == null) return 0;
    final match = RegExp(r'\d+').firstMatch(value);
    return match == null ? 0 : int.tryParse(match.group(0)!) ?? 0;
  }

  Future<void> _showAddFoodDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _AddFoodDialog(
        onAdd: (name, calories) {
          setState(() {
            if (_selectedLog.foodItems[_selectedMealTab] == null) {
              _selectedLog.foodItems[_selectedMealTab] = [];
            }
            _selectedLog.foodItems[_selectedMealTab]!.add({
              'name': name,
              'calories': '$calories kcal',
            });
          });
        },
      ),
    );
  }

  Future<void> _showEditSleepDialog() async {
    TimeOfDay tempBedTime = _selectedLog.bedTime;
    TimeOfDay tempWakeTime = _selectedLog.wakeTime;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Sleep Schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Bed Time'),
                trailing: Text(tempBedTime.format(context)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: tempBedTime,
                  );
                  if (time != null) {
                    setDialogState(() => tempBedTime = time);
                  }
                },
              ),
              ListTile(
                title: const Text('Wake Up Time'),
                trailing: Text(tempWakeTime.format(context)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: tempWakeTime,
                  );
                  if (time != null) {
                    setDialogState(() => tempWakeTime = time);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedLog.bedTime = tempBedTime;
                  _selectedLog.wakeTime = tempWakeTime;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today, ${DateFormat('MMMM d').format(date)}';
    }
    return DateFormat('EEEE, MMMM d').format(date);
  }

  String _calculateSleepDuration() {
    final now = DateTime.now();
    final bed = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedLog.bedTime.hour,
      _selectedLog.bedTime.minute,
    );
    var wake = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedLog.wakeTime.hour,
      _selectedLog.wakeTime.minute,
    );

    if (wake.isBefore(bed)) {
      wake = wake.add(const Duration(days: 1));
    }

    final duration = wake.difference(bed);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedLog = _selectedLog;
    final totalCalories = _totalCalories;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // Custom Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        onPressed: () => _changeDate(-1),
                        style: IconButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 40),
                        ),
                      ),
                      Text(
                        _formatDate(_selectedDate),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        onPressed: () => _changeDate(1),
                        style: IconButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 40),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Daily Log',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Food Intake Card
                  Padding(
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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      SolarIconsBold.hamburgerMenu,
                                      size: 24,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Food Intake',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$totalCalories/$_calorieGoal kcal',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: _showAddFoodDialog,
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
                              value: _calorieProgress,
                              minHeight: 8,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.cyan,
                              ),
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
                          ...(selectedLog.foodItems[_selectedMealTab] ?? [])
                              .asMap()
                              .entries
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildFoodItem(
                                    context,
                                    entry.value['name']!,
                                    entry.value['calories']!,
                                    onRemove: () => _removeFoodItem(
                                      _selectedMealTab,
                                      entry.key,
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Hydration Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
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
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.cyan.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.water_drop,
                                      size: 24,
                                      color: Colors.cyan,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Hydration',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${selectedLog.waterIntake.toStringAsFixed(1)} / ${_waterGoal.toStringAsFixed(1)} L',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Circular Progress
                          Center(
                            child: SizedBox(
                              width: 160,
                              height: 160,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 160,
                                    height: 160,
                                    child: CircularProgressIndicator(
                                      value:
                                          (selectedLog.waterIntake / _waterGoal)
                                              .clamp(0.0, 1.0),
                                      strokeWidth: 14,
                                      backgroundColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Colors.cyan,
                                          ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${((selectedLog.waterIntake / _waterGoal) * 100).toInt()}%',
                                        style: theme.textTheme.displaySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Goal',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Water buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildWaterButton(context, '-', () {
                                _updateWater(-0.25);
                              }),
                              const SizedBox(width: 40),
                              _buildWaterButton(context, '+', () {
                                _updateWater(0.25);
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sleep Card
                  Padding(
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
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      SolarIconsBold.moon,
                                      size: 24,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sleep',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Total sleep: ${_calculateSleepDuration()}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: _showEditSleepDialog,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Sleep Time Cards
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Went to Bed',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        selectedLog.bedTime.format(context),
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Wake Up',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        selectedLog.wakeTime.format(context),
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildMealTab(BuildContext context, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedMealTab == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMealTab = label;
        });
      },
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

  Widget _buildWaterButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.cyan.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Text(
          label,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.cyan,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _DailyHealthLog {
  _DailyHealthLog({
    required this.waterIntake,
    required this.foodItems,
    required this.bedTime,
    required this.wakeTime,
  });

  factory _DailyHealthLog.seeded() {
    return _DailyHealthLog(
      waterIntake: 1.5,
      foodItems: {
        'Breakfast': [
          {'name': 'Oatmeal with Berries', 'calories': '350 kcal'},
          {'name': 'Black Coffee', 'calories': '5 kcal'},
        ],
        'Lunch': [
          {'name': 'Grilled Chicken Salad', 'calories': '450 kcal'},
          {'name': 'Apple', 'calories': '80 kcal'},
        ],
        'Dinner': [
          {'name': 'Salmon with Veggies', 'calories': '550 kcal'},
        ],
        'Snacks': [
          {'name': 'Almonds', 'calories': '160 kcal'},
        ],
      },
      bedTime: const TimeOfDay(hour: 22, minute: 30),
      wakeTime: const TimeOfDay(hour: 6, minute: 0),
    );
  }

  factory _DailyHealthLog.empty() {
    return _DailyHealthLog(
      waterIntake: 0,
      foodItems: {'Breakfast': [], 'Lunch': [], 'Dinner': [], 'Snacks': []},
      bedTime: const TimeOfDay(hour: 22, minute: 30),
      wakeTime: const TimeOfDay(hour: 6, minute: 0),
    );
  }

  double waterIntake;
  Map<String, List<Map<String, String>>> foodItems;
  TimeOfDay bedTime;
  TimeOfDay wakeTime;
}

class _AddFoodDialog extends StatefulWidget {
  const _AddFoodDialog({required this.onAdd});

  final void Function(String name, String calories) onAdd;

  @override
  State<_AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<_AddFoodDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final calories = _caloriesController.text.trim();
    if (name.isEmpty || calories.isEmpty) return;

    widget.onAdd(name, calories);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Food'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Food Name',
              hintText: 'e.g., Banana',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _caloriesController,
            decoration: const InputDecoration(
              labelText: 'Calories',
              hintText: 'e.g., 105',
              suffixText: 'kcal',
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
