import 'package:flowfit/screens/health/daily_health_log.dart';
import 'package:flowfit/screens/health/widgets/add_food_dialog.dart';
import 'package:flowfit/screens/health/widgets/edit_sleep_dialog.dart';
import 'package:flowfit/screens/health/widgets/food_intake_card.dart';
import 'package:flowfit/screens/health/widgets/hydration_card.dart';
import 'package:flowfit/screens/health/widgets/sleep_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum HealthInitialAction { addWater, addMeal }

typedef HealthTimePicker =
    Future<TimeOfDay?> Function(BuildContext context, TimeOfDay initialTime);

// Health Screen
class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key, this.initialAction, this.pickTime});

  final HealthInitialAction? initialAction;
  final HealthTimePicker? pickTime;

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  // State variables
  DateTime _selectedDate = DateTime.now();
  final double _waterGoal = 2.0;
  final int _calorieGoal = 2000;
  String _selectedMealTab = 'Breakfast';
  bool _isShowingAddFoodDialog = false;
  bool _isShowingEditSleepDialog = false;
  late final Map<String, DailyHealthLog> _dailyLogs = {
    _dateKey(_selectedDate): DailyHealthLog.seeded(),
  };

  DailyHealthLog get _selectedLog =>
      _dailyLogs.putIfAbsent(_dateKey(_selectedDate), DailyHealthLog.empty);

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
    if (_isShowingAddFoodDialog) return;

    setState(() {
      _isShowingAddFoodDialog = true;
    });

    try {
      await showDialog(
        context: context,
        builder: (context) => AddFoodDialog(
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
    } finally {
      if (mounted) {
        setState(() {
          _isShowingAddFoodDialog = false;
        });
      }
    }
  }

  Future<void> _showEditSleepDialog() async {
    if (_isShowingEditSleepDialog) return;

    setState(() {
      _isShowingEditSleepDialog = true;
    });

    try {
      await showDialog(
        context: context,
        builder: (context) => EditSleepDialog(
          bedTime: _selectedLog.bedTime,
          wakeTime: _selectedLog.wakeTime,
          pickTime: _pickTime,
          onSave: (bedTime, wakeTime) {
            setState(() {
              _selectedLog.bedTime = bedTime;
              _selectedLog.wakeTime = wakeTime;
            });
          },
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isShowingEditSleepDialog = false;
        });
      }
    }
  }

  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initialTime) {
    final pickTime = widget.pickTime;
    if (pickTime != null) {
      return pickTime(context, initialTime);
    }

    return showTimePicker(context: context, initialTime: initialTime);
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
                  FoodIntakeCard(
                    totalCalories: _totalCalories,
                    calorieGoal: _calorieGoal,
                    calorieProgress: _calorieProgress,
                    selectedMealTab: _selectedMealTab,
                    foodItems:
                        selectedLog.foodItems[_selectedMealTab] ?? const [],
                    isShowingAddFoodDialog: _isShowingAddFoodDialog,
                    onAddFood: _showAddFoodDialog,
                    onSelectMealTab: (label) {
                      setState(() {
                        _selectedMealTab = label;
                      });
                    },
                    onRemoveFoodItem: (index) =>
                        _removeFoodItem(_selectedMealTab, index),
                  ),

                  const SizedBox(height: 20),

                  // Hydration Card
                  HydrationCard(
                    waterIntake: selectedLog.waterIntake,
                    waterGoal: _waterGoal,
                    onAddWater: _updateWater,
                  ),

                  const SizedBox(height: 20),

                  // Sleep Card
                  SleepCard(
                    bedTime: selectedLog.bedTime,
                    wakeTime: selectedLog.wakeTime,
                    sleepDuration: _calculateSleepDuration(),
                    isShowingEditSleepDialog: _isShowingEditSleepDialog,
                    onEdit: _showEditSleepDialog,
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
}
