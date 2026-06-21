import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../services/profile_goal_preferences.dart';
import 'widgets/goal_save_button.dart';

class WeightGoalsScreen extends StatefulWidget {
  const WeightGoalsScreen({super.key});

  @override
  State<WeightGoalsScreen> createState() => _WeightGoalsScreenState();
}

class _WeightGoalsScreenState extends State<WeightGoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentWeightController = TextEditingController(text: '145');
  final _goalWeightController = TextEditingController(text: '135');
  String _selectedWeeklyGoal = '1 lb/week';
  bool _isLoading = false;

  final List<String> _weeklyGoalOptions = [
    '0.5 lb/week',
    '1 lb/week',
    '1.5 lb/week',
    '2 lb/week',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedGoals();
  }

  @override
  void dispose() {
    _currentWeightController.dispose();
    _goalWeightController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goals = await ProfileGoalPreferences(prefs).loadWeightGoals();
    if (!mounted) return;
    setState(() {
      _currentWeightController.text = goals.currentWeight;
      _goalWeightController.text = goals.goalWeight;
      if (_weeklyGoalOptions.contains(goals.weeklyGoal)) {
        _selectedWeeklyGoal = goals.weeklyGoal;
      }
    });
  }

  Future<void> _handleSave() async {
    if (_isLoading) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      await ProfileGoalPreferences(prefs).saveWeightGoals(
        WeightGoalSettings(
          currentWeight: _currentWeightController.text.trim(),
          goalWeight: _goalWeightController.text.trim(),
          weeklyGoal: _selectedWeeklyGoal,
        ),
      );

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weight goals updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            SolarIconsOutline.altArrowLeft,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Weight Goals',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      SolarIconsBold.scale,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Set your weight goals to track your progress',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Current Weight
              Text(
                'Current Weight',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currentWeightController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Enter current weight',
                  suffixText: 'lbs',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    SolarIconsOutline.scale,
                    color: theme.colorScheme.primary,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current weight';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Please enter a valid current weight';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Goal Weight
              Text(
                'Goal Weight',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _goalWeightController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Enter goal weight',
                  suffixText: 'lbs',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    SolarIconsOutline.target,
                    color: theme.colorScheme.primary,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your goal weight';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Please enter a valid goal weight';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Weekly Goal
              Text(
                'Weekly Goal',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RadioGroup<String>(
                  groupValue: _selectedWeeklyGoal,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedWeeklyGoal = value;
                    });
                  },
                  child: Column(
                    children: _weeklyGoalOptions.map((option) {
                      final isSelected = _selectedWeeklyGoal == option;
                      return RadioListTile<String>(
                        value: option,
                        title: Text(option),
                        activeColor: theme.colorScheme.primary,
                        selected: isSelected,
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Progress Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Goal Summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Current',
                            '${_currentWeightController.text} lbs',
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Goal',
                            '${_goalWeightController.text} lbs',
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'To Lose',
                            _formatWeightDifference(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              GoalSaveButton(isLoading: _isLoading, onPressed: _handleSave),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatWeightDifference() {
    final current = double.tryParse(_currentWeightController.text);
    final goal = double.tryParse(_goalWeightController.text);
    if (current == null || goal == null) {
      return '0 lbs';
    }

    final difference = (current - goal).abs();
    final formatted = difference == difference.roundToDouble()
        ? difference.toStringAsFixed(0)
        : difference.toStringAsFixed(1);
    return '$formatted lbs';
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
