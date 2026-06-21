import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../widgets/survey_app_bar.dart';
import '../../core/utils/height_measurements.dart';
import '../../core/utils/logger.dart';

class SurveyBodyMeasurementsScreen extends ConsumerStatefulWidget {
  const SurveyBodyMeasurementsScreen({super.key});

  @override
  ConsumerState<SurveyBodyMeasurementsScreen> createState() =>
      _SurveyBodyMeasurementsScreenState();
}

class _SurveyBodyMeasurementsScreenState
    extends ConsumerState<SurveyBodyMeasurementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';
  bool _isContinuing = false;
  final _logger = Logger('SurveyBodyMeasurementsScreen');

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
        final profileHeightUnit = profile.heightUnit ?? 'cm';
        // User has existing profile data - pre-populate from profile
        if (profile.height != null) {
          _heightController.text = heightInputLabelFromStoredValue(
            profile.height!,
            profileHeightUnit,
          );
        }
        if (profile.weight != null) {
          _weightController.text = profile.weight.toString();
        }
        if (profile.heightUnit != null) {
          setState(() {
            _heightUnit = profile.heightUnit!;
          });
          ref
              .read(surveyNotifierProvider.notifier)
              .updateSurveyData('heightUnit', profile.heightUnit);
        }
        if (profile.weightUnit != null) {
          setState(() {
            _weightUnit = profile.weightUnit!;
          });
          ref
              .read(surveyNotifierProvider.notifier)
              .updateSurveyData('weightUnit', profile.weightUnit);
        }
        // Update survey state with profile data
        if (profile.height != null) {
          ref
              .read(surveyNotifierProvider.notifier)
              .updateSurveyData('height', profile.height);
        }
        if (profile.weight != null) {
          ref
              .read(surveyNotifierProvider.notifier)
              .updateSurveyData('weight', profile.weight);
        }
        return;
      }
    }

    // If no profile data, load from survey state
    final surveyState = ref.read(surveyNotifierProvider);
    final heightUnit = surveyState.surveyData['heightUnit'] as String?;
    if (heightUnit != null && heightUnit.isNotEmpty) {
      _heightUnit = heightUnit;
    }
    final weightUnit = surveyState.surveyData['weightUnit'] as String?;
    if (weightUnit != null && weightUnit.isNotEmpty) {
      _weightUnit = weightUnit;
    }
    final heightInput = surveyState.surveyData['heightInput'] as String?;
    final height = (surveyState.surveyData['height'] as num?)?.toDouble();
    if (heightInput != null && heightInput.isNotEmpty) {
      _heightController.text = heightInput;
    } else if (height != null) {
      _heightController.text = heightInputLabelFromStoredValue(
        height,
        _heightUnit,
      );
    }
    final weight = surveyState.surveyData['weight'];
    if (weight != null) {
      _weightController.text = weight.toString();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _heightController.text.isNotEmpty && _weightController.text.isNotEmpty;

  void _handleHeightUnitChanged(String value) {
    if (value == _heightUnit) return;

    final convertedInput = convertHeightInputForUnit(
      input: _heightController.text,
      fromUnit: _heightUnit,
      toUnit: value,
    );

    setState(() {
      if (convertedInput != null) {
        _heightController.text = convertedInput;
      }
      _heightUnit = value;
    });
  }

  void _handleWeightUnitChanged(String value) {
    if (value == _weightUnit) return;

    final currentWeight = double.tryParse(_weightController.text.trim());
    setState(() {
      if (currentWeight != null && currentWeight > 0) {
        final convertedWeight = _convertWeightInput(
          currentWeight,
          fromUnit: _weightUnit,
          toUnit: value,
        );
        if (convertedWeight != null) {
          _weightController.text = _formatMeasurementInput(convertedWeight);
        }
      }
      _weightUnit = value;
    });
  }

  Future<void> _handleNext() async {
    if (_isContinuing) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Capture context-dependent values BEFORE any async operations
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] as String?;

    setState(() => _isContinuing = true);

    try {
      // Save data to survey notifier
      final surveyNotifier = ref.read(surveyNotifierProvider.notifier);
      final parsedHeight = parseHeightForStorage(
        _heightController.text,
        _heightUnit,
      );
      await surveyNotifier.updateSurveyData('height', parsedHeight);
      await surveyNotifier.updateSurveyData(
        'heightInput',
        _heightController.text.trim(),
      );
      await surveyNotifier.updateSurveyData(
        'weight',
        double.parse(_weightController.text),
      );
      await surveyNotifier.updateSurveyData('heightUnit', _heightUnit);
      await surveyNotifier.updateSurveyData('weightUnit', _weightUnit);

      // Validate using the notifier's validation method
      final validationError = surveyNotifier.validateBodyMeasurements();
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
          _logger.info('Incremental save successful for body measurements');
        } catch (e, stackTrace) {
          // Log error but don't block user from continuing
          // Incremental save is best-effort
          _logger.warning(
            'Incremental save failed for body measurements',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      // Navigate to next screen
      if (!mounted) return;
      Navigator.pushNamed(context, '/survey_activity_goals', arguments: args);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isContinuing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const SurveyAppBar(currentStep: 2, totalSteps: 4),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Progress Indicator
                          const SurveyProgressIndicator(
                            currentStep: 2,
                            totalSteps: 4,
                          ),

                          const SizedBox(height: 32),

                          // Title with icon
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  SolarIconsBold.ruler,
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
                                      'Your measurements',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryBlue,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Help us calculate accurate metrics',
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

                          const SizedBox(height: 40),

                          // Height Input
                          Text(
                            'Height',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF314158),
                                ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _heightController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: const TextStyle(
                                    color: AppTheme.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter height',
                                    helperText: _heightUnit == 'ft'
                                        ? 'Use feet.inches, e.g. 5.8 for 5 ft 8 in'
                                        : null,
                                    hintStyle: TextStyle(
                                      color: Colors.grey[500],
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryBlue,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Height is required';
                                    }
                                    if (_heightUnit == 'ft') {
                                      final height = tryParseFeetInchesInput(
                                        value,
                                      );
                                      if (height == null) {
                                        return 'Enter inches from 0 to 11';
                                      }
                                      return null;
                                    }
                                    final height = double.tryParse(value);
                                    if (height == null || height <= 0) {
                                      return 'Enter a valid height';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildUnitToggle(
                                  value: _heightUnit,
                                  option1: 'cm',
                                  option2: 'ft',
                                  onChanged: _handleHeightUnitChanged,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Weight Input
                          Text(
                            'Weight',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF314158),
                                ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    color: AppTheme.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter weight',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[500],
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryBlue,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Weight is required';
                                    }
                                    final weight = double.tryParse(value);
                                    if (weight == null || weight <= 0) {
                                      return 'Enter a valid weight';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildUnitToggle(
                                  value: _weightUnit,
                                  option1: 'kg',
                                  option2: 'lbs',
                                  onChanged: _handleWeightUnitChanged,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

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
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUnitToggle({
    required String value,
    required String option1,
    required String option2,
    required void Function(String) onChanged,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option1),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: value == option1
                      ? AppTheme.primaryBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    option1,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: value == option1
                          ? Colors.white
                          : AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option2),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: value == option2
                      ? AppTheme.primaryBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    option2,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: value == option2
                          ? Colors.white
                          : AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double? _convertWeightInput(
    double value, {
    required String fromUnit,
    required String toUnit,
  }) {
    if (fromUnit == toUnit) return value;
    if (fromUnit == 'kg' && toUnit == 'lbs') {
      return value / 0.45359237;
    }
    if (fromUnit == 'lbs' && toUnit == 'kg') {
      return value * 0.45359237;
    }
    return null;
  }

  String _formatMeasurementInput(double value) {
    final rounded = double.parse(value.toStringAsFixed(1));
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
  }
}
