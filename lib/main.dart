import 'package:flowfit/features/activity_classifier/data/tflite_activity_repository.dart';
import 'package:flowfit/features/activity_classifier/domain/classify_activity_usecase.dart';
import 'package:flowfit/features/activity_classifier/platform/tflite_activity_classifier.dart';
import 'package:flowfit/features/activity_classifier/platform/heart_bpm_adapter.dart';
import 'package:flowfit/features/activity_classifier/presentation/tracker_page.dart';
import 'package:flowfit/features/wellness/presentation/maps_page_wrapper.dart';
import 'package:flowfit/services/phone_data_listener.dart';
import 'package:flowfit/features/activity_classifier/presentation/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/supabase_runtime_config.dart';
import 'providers/wellness_state_provider.dart';
import 'theme/app_theme.dart';
import 'utils/deep_link_handler.dart';
import 'widgets/buddy_pending_sync_listener.dart';
import 'screens/loading_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/phone_home.dart';
import 'screens/phone/phone_heart_rate_screen.dart';
import 'screens/onboarding/survey_intro_screen.dart';
import 'screens/onboarding/survey_basic_info_screen.dart';
import 'screens/onboarding/survey_body_measurements_screen.dart';
import 'screens/onboarding/survey_activity_goals_screen.dart';
import 'screens/onboarding/survey_daily_targets_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/buddy_welcome_screen.dart';
import 'screens/onboarding/buddy_intro_screen.dart';
import 'screens/onboarding/buddy_hatch_screen.dart';
import 'screens/onboarding/buddy_color_selection_screen.dart';
import 'screens/onboarding/buddy_naming_screen.dart';
import 'screens/onboarding/goal_selection_screen.dart';
import 'screens/onboarding/notification_permission_screen.dart';
import 'screens/onboarding/buddy_ready_screen.dart';
import 'screens/onboarding/buddy_profile_setup_screen.dart';
import 'screens/onboarding/buddy_completion_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/font_demo_screen.dart';
import 'screens/profile/settings/general/privacy_policy_screen.dart';
import 'screens/profile/settings/settings_screen.dart';
import 'screens/profile/settings/general/notification_settings_screen.dart';
import 'screens/profile/settings/general/app_integration_screen.dart';
import 'screens/profile/settings/general/language_settings_screen.dart';
import 'screens/profile/settings/general/unit_settings_screen.dart';
import 'screens/profile/settings/general/terms_of_service_screen.dart';
import 'screens/profile/settings/general/help_support_screen.dart';
import 'screens/profile/settings/general/about_us_screen.dart';
import 'screens/profile/settings/change_password_screen.dart';
import 'screens/profile/settings/delete_account_screen.dart';
import 'screens/profile/goals/weight_goals_screen.dart';
import 'screens/profile/goals/fitness_goals_screen.dart';
import 'screens/profile/goals/nutrition_goals_screen.dart';
import 'screens/profile/buddy_customization_screen.dart';
// import 'widgets/debug_route_menu.dart';
import 'screens/workout/workout_type_selection_screen.dart';
import 'screens/workout/running/running_setup_screen.dart';
import 'screens/workout/running/active_running_screen.dart';
import 'screens/workout/running/running_summary_screen.dart';
import 'screens/workout/running/share_achievement_screen.dart';
import 'screens/workout/walking/walking_options_screen.dart';
import 'screens/workout/walking/mission_creation_screen.dart';
import 'screens/workout/walking/active_walking_screen.dart';
import 'screens/workout/walking/walking_summary_screen.dart';
import 'models/mission.dart';
import 'screens/workout/resistance/split_selection_screen.dart';
import 'screens/workout/resistance/active_resistance_screen.dart';
import 'screens/workout/resistance/resistance_summary_screen.dart';
import 'screens/wellness/wellness_tracker_page.dart';
import 'screens/wellness/wellness_onboarding_screen.dart';
import 'screens/wellness/wellness_settings_screen.dart';
import 'features/yolo_camera/presentation/screens/yolo_debug_screen.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with dart-define configuration and deep link support
  SupabaseRuntimeConfig.validate();
  await Supabase.initialize(
    url: SupabaseRuntimeConfig.url,
    // supabase_flutter 2.10.x still names this parameter anonKey.
    // The value should be the dashboard Publishable key.
    anonKey: SupabaseRuntimeConfig.publishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // Use PKCE flow for mobile security
    ),
  );

  // Initialize deep link handler
  DeepLinkHandler().initialize();

  // Initialize SharedPreferences for wellness state persistence
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const FlowFitPhoneApp(),
    ),
  );
}

class FlowFitPhoneApp extends StatelessWidget {
  const FlowFitPhoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BuddyPendingSyncListener(
      child: MultiProvider(
        providers: [
          Provider<HeartBpmAdapter>(create: (_) => HeartBpmAdapter()),
          // Phone data listener used to receive watch heart rate via Wearable data layer
          Provider<PhoneDataListener>(create: (_) => PhoneDataListener()),
          Provider<TFLiteActivityClassifier>(
            create: (_) => TFLiteActivityClassifier(),
          ),

          // Data layer
          ProxyProvider<TFLiteActivityClassifier, ActivityClassifierRepository>(
            create: (context) => TFLiteActivityRepository(
              context.read<TFLiteActivityClassifier>(),
            ),
            update: (_, classifier, __) => TFLiteActivityRepository(classifier),
          ),
          // Domain layer (use ActivityClassifierRepository abstract type)
          ProxyProvider<ActivityClassifierRepository, ClassifyActivityUseCase>(
            create: (context) => ClassifyActivityUseCase(
              context.read<ActivityClassifierRepository>(),
            ),
            update: (_, repository, __) => ClassifyActivityUseCase(repository),
          ),

          // Presentation layer
          ChangeNotifierProxyProvider<
            ClassifyActivityUseCase,
            ActivityClassifierViewModel
          >(
            create: (context) => ActivityClassifierViewModel(
              context.read<ClassifyActivityUseCase>(),
            ),
            update: (_, useCase, __) => ActivityClassifierViewModel(useCase),
          ),
        ],
        child: MaterialApp(
          // Add navigator key for deep link handling
          navigatorKey: DeepLinkHandler.navigatorKey,
          // Wrap the app's child with a debug overlay (Floating debug menu)
          builder: (context, child) => Stack(
            children: [
              if (child != null) child,
              // Show the debug route menu only in debug builds.
              // const DebugRouteMenu(),
            ],
          ),
          title: 'FlowFit',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routes: {
            // Only include '/' route in non-debug mode to avoid conflict with 'home'
            '/': (context) => const SplashScreen(),
            '/loading': (context) => const LoadingScreen(),
            '/welcome': (context) => const WelcomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/email_verification': (context) => const EmailVerificationScreen(),
            // Survey flow (4 steps)
            '/survey_intro': (context) => const SurveyIntroScreen(), // Step 0
            '/survey_basic_info': (context) =>
                const SurveyBasicInfoScreen(), // Step 1
            '/survey_body_measurements': (context) =>
                const SurveyBodyMeasurementsScreen(), // Step 2
            '/survey_activity_goals': (context) =>
                const SurveyActivityGoalsScreen(), // Step 3
            '/survey_daily_targets': (context) =>
                const SurveyDailyTargetsScreen(), // Step 4
            '/onboarding1': (context) => const OnboardingScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/activity-classifier': (context) => const TrackerPage(),
            '/mission': (context) => const MapsPageWrapper(),
            '/home': (context) => const PhoneHomePage(),
            '/phone_heart_rate': (context) => const PhoneHeartRateScreen(),
            '/privacy-policy': (context) => const PrivacyPolicyScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/notification-settings': (context) =>
                const NotificationSettingsScreen(),
            '/app-integration': (context) => const AppIntegrationScreen(),
            '/language-settings': (context) => const LanguageSettingsScreen(),
            '/unit-settings': (context) => const UnitSettingsScreen(),
            '/terms-of-service': (context) => const TermsOfServiceScreen(),
            '/help-support': (context) => const HelpSupportScreen(),
            '/change-password': (context) => const ChangePasswordScreen(),
            '/delete-account': (context) => const DeleteAccountScreen(),
            '/weight-goals': (context) => const WeightGoalsScreen(),
            '/fitness-goals': (context) => const FitnessGoalsScreen(),
            '/nutrition-goals': (context) => const NutritionGoalsScreen(),
            '/about-us': (context) => const AboutUsScreen(),
            // Workout flow routes
            '/workout/select-type': (context) =>
                const WorkoutTypeSelectionScreen(),
            '/workout/running/setup': (context) => const RunningSetupScreen(),
            '/workout/running/active': (context) => const ActiveRunningScreen(),
            '/workout/running/summary': (context) =>
                const RunningSummaryScreen(),
            '/workout/running/share': (context) {
              final args =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
              final session = args?['session'];
              return ShareAchievementScreen(session: session);
            },
            '/workout/walking/options': (context) =>
                const WalkingOptionsScreen(),
            '/workout/walking/mission': (context) =>
                const MissionCreationScreen(missionType: MissionType.target),
            '/workout/walking/active': (context) => const ActiveWalkingScreen(),
            '/workout/walking/summary': (context) =>
                const WalkingSummaryScreen(),
            '/workout/resistance/select-split': (context) =>
                const SplitSelectionScreen(),
            '/workout/resistance/active': (context) =>
                const ActiveResistanceScreen(),
            '/workout/resistance/summary': (context) =>
                const ResistanceSummaryScreen(),
            '/wellness-tracker': (context) => const WellnessTrackerPage(),
            '/wellness-onboarding': (context) =>
                const WellnessOnboardingScreen(),
            '/wellness-settings': (context) => const WellnessSettingsScreen(),
            // Buddy onboarding flow (8-screen whale-themed for kids)
            '/buddy-welcome': (context) => const BuddyWelcomeScreen(),
            '/buddy-intro': (context) => const BuddyIntroScreen(),
            '/buddy-hatch': (context) => const BuddyHatchScreen(),
            '/buddy-color-selection': (context) =>
                const BuddyColorSelectionScreen(),
            '/buddy-naming': (context) => const BuddyNamingScreen(),
            '/goal-selection': (context) => const GoalSelectionScreen(),
            '/notification-permission': (context) =>
                const NotificationPermissionScreen(),
            '/buddy-ready': (context) => const BuddyReadyScreen(),
            '/buddy_profile_setup': (context) =>
                const BuddyProfileSetupScreen(),
            '/buddy-completion': (context) => const BuddyCompletionScreen(),
            // Buddy customization
            '/buddy-customization': (context) =>
                const BuddyCustomizationScreen(),
            if (kDebugMode) ...{
              '/font-demo': (context) => const FontDemoScreen(),
              '/trackertest': (context) => const TrackerPage(),
              '/yolo-debug': (context) => const YoloDebugScreen(),
            },
          },
        ),
      ),
    );
  }
}
