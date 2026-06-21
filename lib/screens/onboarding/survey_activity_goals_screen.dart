import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../widgets/survey_app_bar.dart';
import '../../core/utils/logger.dart';

class SurveyActivityGoalsScreen extends ConsumerStatefulWidget {
  const SurveyActivityGoalsScreen({super.key});

  @override
  ConsumerState<SurveyActivityGoalsScreen> createState() =>
      _SurveyActivityGoalsScreenState();
}

class _SurveyActivityGoalsScreenState
    extends ConsumerState<SurveyActivityGoalsScreen> {
  String? _selectedActivityLevel;
  Set<String> _selectedGoals = {};
  bool _isContinuing = false;
  final _logger = Logger('SurveyActivityGoalsScreen');

  final List<Map<String, dynamic>> _activityLevels = [
    {
      'id': 'sedentary',
      'title': 'Sedentary',
      'icon': SolarIconsBold.smartphone,
      'description': 'Desk job, little exercise',
      'multiplier': '1.2×',
    },
    {
      'id': 'moderately_active',
      'title': 'Moderately Active',
      'icon': SolarIconsBold.bicycling,
      'description': 'Exercise 3-5 times/week',
      'multiplier': '1.55×',
    },
    {
      'id': 'very_active',
      'title': 'Very Active',
      'icon': SolarIconsBold.dumbbellSmall,
      'description': 'Daily intense exercise',
      'multiplier': '1.725×',
    },
  ];

  final List<Map<String, dynamic>> _goals = [
    {
      'id': 'lose_weight',
      'title': 'Lose Weight',
      'icon': SolarIconsBold.fire,
      'description': 'Safe deficit: -500 cal/day',
      'color': Colors.orange,
    },
    {
      'id': 'maintain_weight',
      'title': 'Maintain Weight',
      'icon': SolarIconsBold.scale,
      'description': 'Stay at current weight',
      'color': Colors.green,
    },
    {
      'id': 'build_muscle',
      'title': 'Build Muscle',
      'icon': SolarIconsBold.dumbbellSmall,
      'description': 'Surplus: +300 cal/day',
      'color': Colors.purple,
    },
    {
      'id': 'improve_cardio',
      'title': 'Improve Cardio',
      'icon': SolarIconsBold.heartPulse,
      'description': 'Focus on heart health',
      'color': Colors.red,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
  }

  /// Load existing data from profile or survey state
  /// Requirement 7.3: Ensure survey screens reflect profile data if returning
  Future<void> _loadExistingData() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] as String?;

    // First, try to load from existing profile if user is returning
    if (userId != null) {
      final profileAsync = ref.read(profileNotifierProvider(userId));
      final profile = profileAsync.valueOrNull;

      if (profile != null) {
        // User has existing profile data - pre-populate from profile
        if (profile.activityLevel != null) {
          setState(() {
            _selectedActivityLevel = profile.activityLevel;
          });
        }
        if (profile.goals != null && profile.goals!.isNotEmpty) {
          setState(() {
            _selectedGoals = profile.goals!.toSet();
          });
        }
        // Update survey state with profile data
        if (profile.activityLevel != null) {
          ref
              .read(surveyNotifierProvider.notifier)
              .updateSurveyData('activityLevel', profile.activityLevel);
        }
        if (profile.goals != null) {
          ref
              .read(surveyNotifierProvider.notifier)
              .updateSurveyData('goals', profile.goals);
        }
        return;
      }
    }

    // If no profile data, load from survey state
    final surveyState = ref.read(surveyNotifierProvider);
    _selectedActivityLevel = surveyState.surveyData['activityLevel'] as String?;
    final goals = surveyState.surveyData['goals'] as List<dynamic>?;
    if (goals != null) {
      _selectedGoals = goals.map((e) => e.toString()).toSet();
    }
    setState(() {});
  }

  bool get _canContinue =>
      _selectedActivityLevel != null && _selectedGoals.isNotEmpty;

  Future<void> _handleNext() async {
    if (_isContinuing) return;

    // Capture context-dependent values BEFORE any async operations
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] as String?;

    // Validate selections
    if (_selectedActivityLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your activity level'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one fitness goal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isContinuing = true);

    try {
      // Save data to survey notifier
      final surveyNotifier = ref.read(surveyNotifierProvider.notifier);
      await surveyNotifier.updateSurveyData(
        'activityLevel',
        _selectedActivityLevel,
      );
      await surveyNotifier.updateSurveyData('goals', _selectedGoals.toList());

      // Validate using the notifier's validation method
      final validationError = surveyNotifier.validateActivityGoals();
      if (validationError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationError),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Incremental save: Save partial profile data to local storage
      // This ensures data persists if user navigates away
      // Requirement 1.1, 1.2: Save data locally on each step
      if (userId != null) {
        try {
          final handler = await ref.read(
            surveyCompletionHandlerProvider.future,
          );
          final surveyData = ref.read(surveyNotifierProvider).surveyData;

          // Save partial profile data incrementally
          // This won't clear survey state, just persists to profile storage
          await handler.completeSurvey(userId, surveyData);
          _logger.info('Incremental save successful for activity goals');
        } catch (e, stackTrace) {
          // Log error but don't block user from continuing
          // Incremental save is best-effort
          _logger.warning(
            'Incremental save failed for activity goals',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      // Navigate to next screen
      if (!mounted) return;
      Navigator.pushNamed(context, '/survey_daily_targets', arguments: args);
    } finally {
      if (mounted) {
        setState(() => _isContinuing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SurveyAppBar(
        currentStep: 3,
        totalSteps: 4,
        title: 'Activity & Goals',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Activity Level Section - consistent header style
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      SolarIconsBold.running,
                      color: AppTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Activity Level',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'How active are you?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ..._activityLevels.map(
                (level) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildActivityCard(level),
                ),
              ),

              const SizedBox(height: 32),

              Divider(color: Colors.grey[300], thickness: 1),

              const SizedBox(height: 32),

              // Goals Section - consistent header style
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      SolarIconsBold.target,
                      color: AppTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Primary Fitness Goal',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'What do you want to achieve?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ..._goals.map(
                (goal) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildGoalCard(goal),
                ),
              ),

              const SizedBox(height: 48),

              // Continue Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _canContinue && !_isContinuing
                      ? _handleNext
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isContinuing ? 'Saving...' : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> level) {
    final isSelected = _selectedActivityLevel == level['id'];

    return GestureDetector(
      onTap: () => setState(() => _selectedActivityLevel = level['id']),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primaryBlue : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 16),
            Icon(
              level['icon'],
              color: isSelected ? AppTheme.primaryBlue : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primaryBlue : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level['description'],
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(${level['multiplier']} multiplier)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final isSelected = _selectedGoals.contains(goal['id']);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedGoals.remove(goal['id']);
          } else {
            if (_selectedGoals.length < 5) {
              _selectedGoals.add(goal['id'] as String);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maximum 5 goals can be selected'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (goal['color'] as Color).withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? goal['color'] : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? goal['color'] : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 16),
            Icon(
              goal['icon'],
              color: isSelected ? goal['color'] : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? goal['color'] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goal['description'],
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
