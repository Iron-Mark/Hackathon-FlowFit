param(
    [switch]$SkipPubGet
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string[]]$Command
    )

    Write-Host ""
    Write-Host "==> $Label"
    & $Command[0] @($Command[1..($Command.Length - 1)])
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE"
    }
}

function Invoke-FlutterTestGroup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string[]]$Tests
    )

    Invoke-CheckedCommand $Label @(
        @('flutter', 'test') + $Tests + @('--reporter', 'compact')
    )
}

Push-Location $repoRoot
try {
    if (-not $SkipPubGet) {
        Invoke-CheckedCommand 'Flutter dependencies' @('flutter', 'pub', 'get')
    }

    Invoke-FlutterTestGroup 'Offline route and action guards' @(
        'test/scripts/navigation_route_guard_test.dart',
        'test/scripts/interactive_action_guard_test.dart',
        'test/scripts/interactive_surface_coverage_guard_test.dart',
        'test/scripts/android_phone_smoke_source_test.dart',
        'test/scripts/android_live_auth_smoke_source_test.dart',
        'test/scripts/offline_action_verifier_manifest_test.dart',
        'test/routes/release_route_surface_test.dart',
        'test/routes/running_share_route_test.dart',
        'test/routes/survey_named_route_contract_test.dart'
    )

    Invoke-FlutterTestGroup 'Auth and production navigation actions' @(
        'test/integration/auth_flow_test.dart',
        'test/integration/login_flow_test.dart',
        'test/app/flowfit_phone_app_navigation_smoke_test.dart',
        'test/screens/auth/email_verification_screen_actions_test.dart',
        'test/screens/auth/welcome_screen_actions_test.dart',
        'test/screens/auth/login_signup_actions_test.dart',
        'test/screens/loading_screen_test.dart',
        'test/screens/splash_screen_test.dart',
        'test/screens/startup_configuration_error_screen_test.dart'
    )

    Invoke-FlutterTestGroup 'Onboarding and buddy actions' @(
        'test/integration/survey_back_navigation_test.dart',
        'test/screens/onboarding/buddy_completion_screen_test.dart',
        'test/screens/onboarding/buddy_entry_flow_actions_test.dart',
        'test/screens/onboarding/buddy_profile_setup_flow_test.dart',
        'test/screens/onboarding/buddy_ready_screen_test.dart',
        'test/screens/onboarding/notification_permission_screen_test.dart',
        'test/screens/onboarding/onboarding_core_actions_test.dart',
        'test/screens/onboarding/survey_basic_info_actions_test.dart',
        'test/screens/onboarding/survey_measurements_activity_actions_test.dart',
        'test/integration/profile_onboarding_integration_test.dart',
        'test/widgets/buddy_pending_sync_listener_test.dart',
        'test/widgets/buddy_widgets_test.dart',
        'test/widgets/onboarding_button_test.dart',
        'test/widgets/survey_app_bar_test.dart'
    )

    Invoke-FlutterTestGroup 'Profile and settings actions' @(
        'test/screens/profile/app_integration_screen_test.dart',
        'test/screens/profile/buddy_customization_screen_test.dart',
        'test/screens/profile/change_password_screen_test.dart',
        'test/screens/delete_account_flow_test.dart',
        'test/screens/profile/delete_account_screen_test.dart',
        'test/screens/profile/goal_save_button_test.dart',
        'test/screens/profile/help_support_screen_actions_test.dart',
        'test/screens/profile/kids_profile_screen_actions_test.dart',
        'test/screens/profile/profile_edit_navigation_unit_test.dart',
        'test/screens/profile/profile_goals_persistence_test.dart',
        'test/screens/profile/profile_haptic_feedback_property_test.dart',
        'test/screens/profile/profile_logout_property_test.dart',
        'test/screens/profile/profile_logout_unit_test.dart',
        'test/screens/profile/profile_photo_actions_test.dart',
        'test/screens/profile/profile_settings_preferences_test.dart',
        'test/screens/profile/profile_state_handling_unit_test.dart',
        'test/screens/profile/profile_sync_status_property_test.dart',
        'test/screens/profile/profile_view_actions_test.dart',
        'test/screens/profile/settings_legal_back_actions_test.dart',
        'test/screens/profile/settings_screen_actions_test.dart',
        'test/services/user_settings_preferences_test.dart'
    )

    Invoke-FlutterTestGroup 'Dashboard health phone and Wear actions' @(
        'test/features/activity_classifier/presentation/tracker_page_watch_listener_test.dart',
        'test/integration/dashboard_refactoring_integration_test.dart',
        'test/screens/dashboard_ai_activity_card_test.dart',
        'test/screens/dashboard_auth_redirect_property_test.dart',
        'test/screens/dashboard_auth_redirect_unit_test.dart',
        'test/screens/dashboard_initial_tab_property_test.dart',
        'test/screens/dashboard_responsive_test.dart',
        'test/screens/dashboard_tab_navigation_unit_test.dart',
        'test/screens/font_demo_screen_test.dart',
        'test/screens/health/health_screen_actions_test.dart',
        'test/screens/heart_rate_monitor_screen_actions_test.dart',
        'test/screens/home/widgets/cta_section_test.dart',
        'test/screens/home/widgets/home_header_test.dart',
        'test/screens/home/widgets/recent_activity_section_test.dart',
        'test/screens/home/widgets/stats_section_test.dart',
        'test/screens/phone/phone_heart_rate_screen_test.dart',
        'test/screens/phone/phone_home_test.dart',
        'test/screens/progress/progress_screen_actions_test.dart',
        'test/screens/sensor_permission_screen_test.dart',
        'test/screens/track/track_screen_actions_test.dart',
        'test/screens/wear/heart_rate_watch_screen_test.dart',
        'test/screens/wear/sensor_permission_rationale_screen_test.dart',
        'test/screens/wear/wear_app_entrypoint_test.dart',
        'test/screens/wear/wear_dashboard_actions_test.dart',
        'test/screens/wear/wear_heart_rate_screen_accessibility_test.dart',
        'test/screens/wear/wear_heart_rate_screen_emulator_fallback_test.dart',
        'test/screens/wear/wear_permission_wrapper_test.dart',
        'test/screens/wear/wear_workout_relax_actions_test.dart'
    )

    Invoke-FlutterTestGroup 'Wellness and map actions' @(
        'test/features/wellness/wellness_maps_page_actions_test.dart',
        'test/features/wellness/maps_page_wrapper_notification_test.dart',
        'test/features/wellness/mission_bottom_sheet_filter_test.dart',
        'test/features/wellness/mission_bottom_sheet_focus_test.dart',
        'test/features/wellness/widgets/floating_actions_test.dart',
        'test/features/wellness/widgets/focus_mission_overlay_test.dart',
        'test/features/wellness/widgets/map_shared_widgets_test.dart',
        'test/features/wellness/widgets/mission_bottom_sheet_focus_test.dart',
        'test/features/wellness/widgets/mission_dialogs_test.dart',
        'test/features/wellness/widgets/place_mode_overlay_test.dart',
        'test/screens/wellness/wellness_onboarding_screen_test.dart',
        'test/screens/wellness/wellness_settings_screen_actions_test.dart',
        'test/screens/wellness/wellness_tracker_page_lifecycle_test.dart',
        'test/services/openroute_service_test.dart',
        'test/widgets/wellness/cardio_detection_banner_test.dart',
        'test/widgets/wellness/stress_alert_banner_test.dart',
        'test/widgets/wellness_debug_panel_actions_test.dart',
        'test/widgets/wellness_map_widget_actions_test.dart'
    )

    Invoke-FlutterTestGroup 'Workout actions' @(
        'test/screens/workout/active_workout_controls_test.dart',
        'test/screens/workout/mission_creation_screen_actions_test.dart',
        'test/screens/workout/resistance_split_start_flow_test.dart',
        'test/screens/workout/running_setup_screen_actions_test.dart',
        'test/screens/workout/share_achievement_screen_actions_test.dart',
        'test/screens/workout/walking_options_screen_actions_test.dart',
        'test/screens/workout/workout_type_selection_screen_test.dart',
        'test/screens/workout/workout_summary_actions_test.dart'
    )

    Invoke-FlutterTestGroup 'Mood camera and shared widget actions' @(
        'test/features/yolo_camera/presentation/detection_overlay_widget_test.dart',
        'test/features/yolo_camera/presentation/yolo_camera_widget_test.dart',
        'test/features/yolo_camera/presentation/yolo_debug_screen_actions_test.dart',
        'test/screens/mood_tracking_demo_screen_actions_test.dart',
        'test/widgets/debug_route_menu_test.dart',
        'test/widgets/mood_summary_widgets_test.dart',
        'test/widgets/permission_status_widget_test.dart',
        'test/widgets/post_workout_mood_check_test.dart',
        'test/widgets/quick_mood_check_bottom_sheet_test.dart'
    )
} finally {
    Pop-Location
}
