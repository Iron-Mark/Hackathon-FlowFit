import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/providers/profile_providers.dart'
    as profile_providers;
import '../../widgets/survey_app_bar.dart';
import '../../core/domain/entities/user_profile.dart';
import '../../core/utils/height_measurements.dart';

class SurveyDailyTargetsScreen extends ConsumerStatefulWidget {
  const SurveyDailyTargetsScreen({super.key});

  @override
  ConsumerState<SurveyDailyTargetsScreen> createState() =>
      _SurveyDailyTargetsScreenState();
}

class _SurveyDailyTargetsScreenState
    extends ConsumerState<SurveyDailyTargetsScreen> {
  int _targetCalories = 2450;
  int _targetSteps = 10000;
  int _targetActiveMinutes = 30;
  double _targetWaterLiters = 2.0;
  bool _isSubmitting = false;

  final List<int> _stepsOptions = [5000, 10000, 12000, 15000];
  final List<int> _minutesOptions = [20, 30, 45, 60];
  final List<double> _waterOptions = [1.5, 2.0, 2.5, 3.0];

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
        if (profile.dailyCalorieTarget != null) {
          setState(() {
            _targetCalories = profile.dailyCalorieTarget!;
          });
        }
        if (profile.dailyStepsTarget != null) {
          setState(() {
            _targetSteps = profile.dailyStepsTarget!;
          });
        }
        if (profile.dailyActiveMinutesTarget != null) {
          setState(() {
            _targetActiveMinutes = profile.dailyActiveMinutesTarget!;
          });
        }
        if (profile.dailyWaterTarget != null) {
          setState(() {
            _targetWaterLiters = profile.dailyWaterTarget!;
          });
        }
        // Update survey state with profile data
        if (profile.dailyCalorieTarget != null) {
          ref
              .read(surveyNotifierProvider.notifier)
              .updateSurveyData(
                'dailyCalorieTarget',
                profile.dailyCalorieTarget,
              );
        }
        if (profile.dailyStepsTarget != null) {
          ref
              .read(surveyNotifierProvider.notifier)
              .updateSurveyData('dailyStepsTarget', profile.dailyStepsTarget);
        }
        if (profile.dailyActiveMinutesTarget != null) {
          ref
              .read(surveyNotifierProvider.notifier)
              .updateSurveyData(
                'dailyActiveMinutesTarget',
                profile.dailyActiveMinutesTarget,
              );
        }
        if (profile.dailyWaterTarget != null) {
          ref
              .read(surveyNotifierProvider.notifier)
              .updateSurveyData('dailyWaterTarget', profile.dailyWaterTarget);
        }
        return;
      }
    }

    // If no profile data, calculate from survey data
    _calculateCalorieTarget();
  }

  void _calculateCalorieTarget() {
    final surveyState = ref.read(surveyNotifierProvider);
    final surveyData = surveyState.surveyData;

    // Get user data
    final age = surveyData['age'] as int? ?? 25;
    final gender = surveyData['gender'] as String? ?? 'male';
    final weight = _weightInKilograms(surveyData);
    final height = _heightInCentimeters(surveyData);
    final activityLevel =
        surveyData['activityLevel'] as String? ?? 'moderately_active';
    final goals = surveyData['goals'] as List<dynamic>? ?? [];

    // Calculate BMR using Mifflin-St Jeor Equation
    double bmr;
    if (gender == 'male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // Apply activity multiplier
    double activityMultiplier;
    switch (activityLevel) {
      case 'sedentary':
        activityMultiplier = 1.2;
        break;
      case 'lightly_active':
        activityMultiplier = 1.375;
        break;
      case 'moderately_active':
        activityMultiplier = 1.55;
        break;
      case 'very_active':
        activityMultiplier = 1.725;
        break;
      case 'extremely_active':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.55;
    }

    double tdee = bmr * activityMultiplier;

    // Adjust based on primary goal
    if (goals.contains('lose_weight')) {
      tdee -= 500; // Safe deficit
    } else if (goals.contains('build_muscle')) {
      tdee += 300; // Surplus
    }

    setState(() {
      _targetCalories = tdee.round();
    });

    // Save to survey data
    ref
        .read(surveyNotifierProvider.notifier)
        .updateSurveyData('dailyCalorieTarget', _targetCalories);
  }

  double _heightInCentimeters(Map<String, dynamic> surveyData) {
    final height = (surveyData['height'] as num?)?.toDouble() ?? 170.0;
    final unit = surveyData['heightUnit'] as String? ?? 'cm';
    return heightInCentimeters(
      height,
      unit,
      rawHeightInput: surveyData['heightInput'] as String?,
    );
  }

  double _weightInKilograms(Map<String, dynamic> surveyData) {
    final weight = (surveyData['weight'] as num?)?.toDouble() ?? 70.0;
    final unit = surveyData['weightUnit'] as String? ?? 'kg';
    return unit == 'lbs' ? weight * 0.45359237 : weight;
  }

  Future<void> _handleComplete() async {
    if (_isSubmitting) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] as String?;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Save daily targets to survey data
      final surveyNotifier = ref.read(surveyNotifierProvider.notifier);
      await surveyNotifier.updateSurveyData(
        'dailyCalorieTarget',
        _targetCalories,
      );
      await surveyNotifier.updateSurveyData('dailyStepsTarget', _targetSteps);
      await surveyNotifier.updateSurveyData(
        'dailyActiveMinutesTarget',
        _targetActiveMinutes,
      );
      await surveyNotifier.updateSurveyData(
        'dailyWaterTarget',
        _targetWaterLiters,
      );

      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Get survey data
      final surveyData = ref.read(surveyNotifierProvider).surveyData;

      // Try to save using handler, but fallback to local-only save if it fails
      bool savedSuccessfully = false;
      String? errorDetails;

      try {
        // Get survey completion handler
        final handler = await ref.read(
          profile_providers.surveyCompletionHandlerProvider.future,
        );

        // Complete survey using handler
        savedSuccessfully = await handler.completeSurvey(userId, surveyData);
      } catch (handlerError) {
        // Handler failed - try direct local save as fallback
        errorDetails = handlerError.toString();
        try {
          final repository = await ref.read(
            profile_providers.profileRepositoryProvider.future,
          );
          final profile = UserProfile.fromSurveyData(userId, surveyData);
          await repository.saveLocalProfile(profile);
          savedSuccessfully = true;
        } catch (fallbackError) {
          // Both handler and fallback failed
          savedSuccessfully = false;
          errorDetails = 'Handler: $handlerError, Fallback: $fallbackError';
        }
      }

      if (!mounted) return;

      if (savedSuccessfully) {
        // Clear survey state after successful save
        await surveyNotifier.resetSurvey();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profile saved successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Navigate based on context
        // If user came from profile edit (not from intro), go to profile tab
        // If new user from intro, go to home tab
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            // Check if user came from intro screen or from edit profile
            final isFromEdit = args?['fromEdit'] as bool? ?? false;

            if (isFromEdit) {
              // Trigger profile refresh before navigating back
              ref.invalidate(profileNotifierProvider(userId));

              // Also manually trigger a reload
              ref.read(profileNotifierProvider(userId).notifier).loadProfile();

              // Pop back to dashboard
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              // New user - navigate to dashboard and clear all previous routes
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
            }
          }
        });
      } else {
        // Show error with details
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to save profile. ${errorDetails ?? 'Please try again.'}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Show user-friendly error message
        String errorMessage = 'Failed to save profile. Please try again.';

        // Provide more specific error messages for common cases
        if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage =
              'No internet connection. Your profile is saved locally and will sync when online.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Request timed out. Your profile is saved locally.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _handleComplete,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getActivityLevelDisplay() {
    final surveyData = ref.read(surveyNotifierProvider).surveyData;
    final activityLevel =
        surveyData['activityLevel'] as String? ?? 'moderately_active';

    switch (activityLevel) {
      case 'sedentary':
        return 'Sedentary';
      case 'lightly_active':
        return 'Lightly active';
      case 'moderately_active':
        return 'Moderately active';
      case 'very_active':
        return 'Very active';
      case 'extremely_active':
        return 'Extremely active';
      default:
        return 'Moderately active';
    }
  }

  String _getGoalsDisplay() {
    final surveyData = ref.read(surveyNotifierProvider).surveyData;
    final goals = surveyData['goals'] as List<dynamic>? ?? [];

    if (goals.isEmpty) return 'No goals selected';

    final goalNames = goals.map((goal) {
      switch (goal) {
        case 'lose_weight':
          return 'Lose weight';
        case 'maintain_weight':
          return 'Maintain weight';
        case 'build_muscle':
          return 'Build muscle';
        case 'improve_cardio':
          return 'Improve cardio';
        default:
          return goal.toString();
      }
    }).toList();

    return goalNames.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final surveyData = ref.watch(surveyNotifierProvider).surveyData;
    final age = surveyData['age'] as int? ?? 0;
    final gender = surveyData['gender'] as String? ?? 'male';
    final height = surveyData['height'] as double? ?? 0.0;
    final weight = surveyData['weight'] as double? ?? 0.0;
    final heightUnit = surveyData['heightUnit'] as String? ?? 'cm';
    final weightUnit = surveyData['weightUnit'] as String? ?? 'kg';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SurveyAppBar(
        currentStep: 4,
        totalSteps: 4,
        title: 'Your Daily Targets',
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
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Title with icon - consistent with other screens
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
                          'Personalized Goals',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Based on your profile',
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

              const SizedBox(height: 32),

              Divider(color: Colors.grey[300], thickness: 1),

              const SizedBox(height: 24),

              // Calorie Target
              Row(
                children: [
                  const Icon(
                    SolarIconsBold.fire,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Calorie Target',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF314158),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_targetCalories',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'calories per day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Based on your profile',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$age years • ${gender == 'male'
                                ? 'Male'
                                : gender == 'female'
                                ? 'Female'
                                : 'Other'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '${_formatMeasurement(height, heightUnit)} • ${_formatMeasurement(weight, weightUnit)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getActivityLevelDisplay(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (_getGoalsDisplay() != 'No goals selected') ...[
                            const SizedBox(height: 2),
                            Text(
                              _getGoalsDisplay(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Divider(color: Colors.grey[300], thickness: 1),

              const SizedBox(height: 24),

              // Steps Target
              _buildDiscreteSliderSection(
                icon: SolarIconsBold.walking,
                color: Colors.green,
                title: 'Steps Target',
                value: _targetSteps,
                options: _stepsOptions,
                formatLabel: (val) => '${(val / 1000).toStringAsFixed(0)}K',
                formatValue: (val) =>
                    '${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} steps',
                onChanged: (val) => setState(() => _targetSteps = val),
              ),

              const SizedBox(height: 32),

              Divider(color: Colors.grey[300], thickness: 1),

              const SizedBox(height: 24),

              // Active Minutes Target
              _buildDiscreteSliderSection(
                icon: SolarIconsBold.clockCircle,
                color: Colors.purple,
                title: 'Active Minutes',
                value: _targetActiveMinutes,
                options: _minutesOptions,
                formatLabel: (val) => '$val',
                formatValue: (val) => '$val minutes',
                onChanged: (val) => setState(() => _targetActiveMinutes = val),
              ),

              const SizedBox(height: 32),

              Divider(color: Colors.grey[300], thickness: 1),

              const SizedBox(height: 24),

              // Water Intake Target
              _buildDiscreteSliderSectionDouble(
                icon: Icons.water_drop,
                color: Colors.blue,
                title: 'Water Intake',
                value: _targetWaterLiters,
                options: _waterOptions,
                formatLabel: (val) => '${val.toStringAsFixed(1)}L',
                formatValue: (val) => '${val.toStringAsFixed(1)} liters',
                onChanged: (val) => setState(() => _targetWaterLiters = val),
              ),

              const SizedBox(height: 32),

              Divider(color: Colors.grey[300], thickness: 1),

              const SizedBox(height: 24),

              // Info
              Row(
                children: [
                  Icon(
                    SolarIconsBold.infoCircle,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can adjust these anytime in your profile settings',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Complete Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 24),
                            SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'Complete & Start App',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMeasurement(double value, String unit) {
    if (unit == 'ft') {
      final surveyData = ref.read(surveyNotifierProvider).surveyData;
      return formatHeightMeasurement(
        value,
        unit,
        rawHeightInput: surveyData['heightInput'] as String?,
      );
    }

    final displayValue = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$displayValue$unit';
  }

  Widget _buildDiscreteSliderSection({
    required IconData icon,
    required Color color,
    required String title,
    required int value,
    required List<int> options,
    required String Function(int) formatLabel,
    required String Function(int) formatValue,
    required Function(int) onChanged,
  }) {
    final currentIndex = options.indexOf(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF314158),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Value Display
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            formatValue(value),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 24),

        // Discrete Slider
        Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.2),
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                trackHeight: 6,
                tickMarkShape: const RoundSliderTickMarkShape(
                  tickMarkRadius: 4,
                ),
                activeTickMarkColor: Colors.white,
                inactiveTickMarkColor: color.withValues(alpha: 0.3),
              ),
              child: Slider(
                value: currentIndex.toDouble(),
                min: 0,
                max: (options.length - 1).toDouble(),
                divisions: options.length - 1,
                onChanged: (newIndex) {
                  onChanged(options[newIndex.round()]);
                },
              ),
            ),

            // Labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: options.map((opt) {
                  final isSelected = opt == value;
                  return Text(
                    formatLabel(opt),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? color : Colors.grey[600],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscreteSliderSectionDouble({
    required IconData icon,
    required Color color,
    required String title,
    required double value,
    required List<double> options,
    required String Function(double) formatLabel,
    required String Function(double) formatValue,
    required Function(double) onChanged,
  }) {
    final currentIndex = options.indexOf(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF314158),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Value Display
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            formatValue(value),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 24),

        // Discrete Slider
        Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.2),
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                trackHeight: 6,
                tickMarkShape: const RoundSliderTickMarkShape(
                  tickMarkRadius: 4,
                ),
                activeTickMarkColor: Colors.white,
                inactiveTickMarkColor: color.withValues(alpha: 0.3),
              ),
              child: Slider(
                value: currentIndex.toDouble(),
                min: 0,
                max: (options.length - 1).toDouble(),
                divisions: options.length - 1,
                onChanged: (newIndex) {
                  onChanged(options[newIndex.round()]);
                },
              ),
            ),

            // Labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: options.map((opt) {
                  final isSelected = opt == value;
                  return Text(
                    formatLabel(opt),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? color : Colors.grey[600],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
