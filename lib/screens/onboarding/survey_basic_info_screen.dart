import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../widgets/survey_app_bar.dart';
import '../../core/utils/logger.dart';

class SurveyBasicInfoScreen extends ConsumerStatefulWidget {
  const SurveyBasicInfoScreen({super.key});

  @override
  ConsumerState<SurveyBasicInfoScreen> createState() =>
      _SurveyBasicInfoScreenState();
}

class _SurveyBasicInfoScreenState extends ConsumerState<SurveyBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;
  bool _isEditMode = false;
  final _logger = Logger('SurveyBasicInfoScreen');

  @override
  void initState() {
    super.initState();
    // Get user name from arguments (passed from signup)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
  }

  /// Load existing data from profile or survey state
  /// Requirement 7.3: Ensure survey screens reflect profile data if returning
  Future<void> _loadExistingData() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final name = args?['name'] as String?;
    final userId = args?['userId'] as String?;
    final fromEdit = args?['fromEdit'] as bool? ?? false;

    setState(() {
      _isEditMode = fromEdit;
    });

    // First, try to load from existing profile if user is returning
    if (userId != null) {
      final profileAsync = ref.read(profileNotifierProvider(userId));
      final profile = profileAsync.valueOrNull;

      if (profile != null) {
        // User has existing profile data - pre-populate from profile
        if (profile.fullName != null) {
          _nameController.text = profile.fullName!;
        }
        if (profile.age != null) {
          _ageController.text = profile.age.toString();
        }
        if (profile.gender != null) {
          setState(() {
            _selectedGender = profile.gender;
          });
        }
        // Update survey state with profile data
        if (profile.fullName != null) {
          ref
              .read(surveyNotifierProvider.notifier)
              .updateSurveyData('fullName', profile.fullName);
        }
        if (profile.age != null) {
          ref
              .read(surveyNotifierProvider.notifier)
              .updateSurveyData('age', profile.age);
        }
        if (profile.gender != null) {
          ref
              .read(surveyNotifierProvider.notifier)
              .updateSurveyData('gender', profile.gender);
        }
        return;
      }
    }

    // If no profile data, load from survey state or use defaults
    final surveyState = ref.read(surveyNotifierProvider);

    // Set name from signup if provided
    if (name != null && name.isNotEmpty) {
      ref
          .read(surveyNotifierProvider.notifier)
          .updateSurveyData('fullName', name);
    }

    // Load age from survey state or default
    final age = surveyState.surveyData['age'];
    if (age != null) {
      _ageController.text = age.toString();
    } else {
      _ageController.text = '18'; // Default age
    }

    // Load gender from survey state
    _selectedGender = surveyState.surveyData['gender'] as String?;
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    // In edit mode, name is also required
    if (_isEditMode) {
      return _selectedGender != null &&
          _ageController.text.isNotEmpty &&
          _nameController.text.isNotEmpty;
    }
    return _selectedGender != null && _ageController.text.isNotEmpty;
  }

  void _incrementAge() {
    final currentAge = int.tryParse(_ageController.text) ?? 0;
    if (currentAge < 120) {
      _ageController.text = (currentAge + 1).toString();
      setState(() {});
    }
  }

  void _decrementAge() {
    final currentAge = int.tryParse(_ageController.text) ?? 0;
    if (currentAge > 7) {
      _ageController.text = (currentAge - 1).toString();
      setState(() {});
    }
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your age';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid number';
    }
    if (age < 7) {
      return 'Age must be between 7 and 120';
    }
    if (age > 120) {
      return 'Please enter a valid age';
    }
    return null;
  }

  Future<void> _handleNext() async {
    if (_formKey.currentState!.validate()) {
      // Capture context-dependent values BEFORE any async operations
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final userId = args?['userId'] as String?;

      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your gender'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Save data to survey notifier
      final surveyNotifier = ref.read(surveyNotifierProvider.notifier);

      // Save name if in edit mode
      if (_isEditMode && _nameController.text.isNotEmpty) {
        await surveyNotifier.updateSurveyData(
          'fullName',
          _nameController.text.trim(),
        );
      }

      await surveyNotifier.updateSurveyData(
        'age',
        int.parse(_ageController.text),
      );
      await surveyNotifier.updateSurveyData('gender', _selectedGender);

      // Validate using the notifier's validation method
      final validationError = surveyNotifier.validateBasicInfo();
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
          _logger.info('Incremental save successful for basic info');
        } catch (e, stackTrace) {
          // Log error but don't block user from continuing
          // Incremental save is best-effort
          _logger.warning(
            'Incremental save failed for basic info',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      // Navigate to next screen
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/survey_body_measurements',
        arguments: args,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const SurveyAppBar(currentStep: 1, totalSteps: 4),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Progress Indicator
                        const SurveyProgressIndicator(
                          currentStep: 1,
                          totalSteps: 4,
                        ),

                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'Tell us about yourself',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'This helps us personalize your experience',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),

                        const SizedBox(height: 40),

                        // Name field (only in edit mode)
                        if (_isEditMode) ...[
                          Text(
                            'Full Name',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF314158),
                                ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(
                              color: AppTheme.text,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter your full name',
                              hintStyle: TextStyle(color: Colors.grey[500]),
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
                              if (_isEditMode &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                            onChanged: (value) => setState(() {}),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Gender Selection
                        Text(
                          'Gender',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF314158),
                              ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildGenderCard('Male', Icons.male),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGenderCard('Female', Icons.female),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGenderCard(
                                'Other',
                                SolarIconsBold.user,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Age Input
                        Text(
                          'Age',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF314158),
                              ),
                        ),

                        const SizedBox(height: 12),

                        _buildAgeInput(),

                        const Spacer(),

                        // Continue Button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _canContinue ? _handleNext : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildAgeInput() {
    final currentAge = int.tryParse(_ageController.text);
    final canDecrement = currentAge != null && currentAge > 7;
    final canIncrement = currentAge != null && currentAge < 120;

    return Form(
      key: _formKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Decrement Button
          Transform.translate(
            offset: const Offset(-4, -16),
            child: _buildAdjustButton(
              icon: Icons.remove_rounded,
              onTap: canDecrement ? _decrementAge : null,
              enabled: canDecrement,
            ),
          ),

          // Age Display
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                      height: 1.0,
                      letterSpacing: 0,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      errorStyle: TextStyle(fontSize: 0, height: 0),
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    validator: _validateAge,
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'years old',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),

          // Increment Button
          Transform.translate(
            offset: const Offset(4, -16),
            child: _buildAdjustButton(
              icon: Icons.add_rounded,
              onTap: canIncrement ? _incrementAge : null,
              enabled: canIncrement,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.primaryBlue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, size: 32, color: Colors.white),
      ),
    );
  }

  Widget _buildGenderCard(String gender, IconData icon) {
    // Store lowercase value for validation, but display capitalized
    final genderValue = gender.toLowerCase();
    final isSelected = _selectedGender == genderValue;

    // Define colors based on gender
    Color selectedColor;
    Color unselectedIconColor;

    switch (gender) {
      case 'Male':
        selectedColor = AppTheme.primaryBlue;
        unselectedIconColor = AppTheme.primaryBlue.withValues(alpha: 0.4);
        break;
      case 'Female':
        selectedColor = const Color(0xFFFF69B4); // Hot pink
        unselectedIconColor = const Color(0xFFFF69B4).withValues(alpha: 0.4);
        break;
      case 'Other':
        selectedColor = Colors.grey[700]!;
        unselectedIconColor = Colors.grey[400]!;
        break;
      default:
        selectedColor = AppTheme.primaryBlue;
        unselectedIconColor = Colors.grey[400]!;
    }

    // Rainbow border for "Other" option - use same structure as other cards
    if (gender == 'Other' && isSelected) {
      return GestureDetector(
        onTap: () => setState(() => _selectedGender = genderValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF6B6B), // Red
                Color(0xFFFFD93D), // Yellow
                Color(0xFF6BCF7F), // Green
                Color(0xFF4D96FF), // Blue
                Color(0xFFB565D8), // Purple
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(2), // Border width
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 22,
            ), // 24 - 2 = 22 to match total height
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32, color: selectedColor),
                const SizedBox(height: 12),
                Text(
                  gender,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selectedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Regular cards for Male, Female, and unselected Other
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = genderValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey[200]!,
            width: 2,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : unselectedIconColor,
            ),
            const SizedBox(height: 12),
            Text(
              gender,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
