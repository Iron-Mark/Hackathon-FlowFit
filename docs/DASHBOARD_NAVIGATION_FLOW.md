# FlowFit Dashboard And Navigation Flow

This document describes the maintained dashboard flow after the 2026-06-19
cleanup. It replaces older hackathon notes that described retired tab shells and
debug-only routes as production navigation.

## Launch And Auth Flow

```text
SplashScreen -> WelcomeScreen -> Sign Up / Log In -> Age Gate -> Survey or Buddy onboarding -> DashboardScreen
```

- Welcome `Get Started` opens `/signup`.
- Welcome `Log In` opens `/login`.
- Signup Terms and Privacy links open `/terms-of-service` and
  `/privacy-policy`.
- Auth completion routes through `/age-gate`.
- Email verification routes through `/email_verification` when confirmation is
  still required.

## Dashboard Tabs

`DashboardScreen` renders five active tabs:

- Home: beginner-friendly overview, companion message, watch heart-rate status,
  quick actions, reminders, and progress summary.
- Health: editable food log, hydration controls, and sleep schedule controls.
- Track: workout entry points for AI activity, walking missions, and running.
- Progress: activity, sleep, and progress summaries.
- Profile: kids/Buddy profile, settings, privacy, support, and account actions.

## Home Quick Actions

- `Start AI Workout` opens `/activity-classifier`.
- `Drink Water` switches to Health and adds 250 ml to the hydration log.
- `Log Meal` switches to Health and opens the Add Food dialog.
- `Track Steps` opens `/mission`.
- `Heart Check` opens `/phone_heart_rate`, which starts the phone watch-data
  listener directly and offers Retry if the native listener cannot start.

## Workout Routes

- `/workout/select-type`
- `/workout/running/setup`
- `/workout/running/active`
- `/workout/running/summary`
- `/workout/running/share`
- `/workout/walking/options`
- `/workout/walking/mission`
- `/workout/walking/active`
- `/workout/walking/summary`
- `/workout/resistance/select-split`
- `/workout/resistance/active`
- `/workout/resistance/summary`

## Wellness Routes

- `/wellness-tracker`
- `/wellness-onboarding`
- `/wellness-settings`
- `/mission`

## Buddy Routes

- `/buddy-welcome`
- `/buddy-intro`
- `/buddy-hatch`
- `/buddy-color-selection`
- `/buddy-naming`
- `/buddy_profile_setup`
- `/goal-selection`
- `/notification-permission`
- `/buddy-ready`
- `/buddy-completion`
- `/buddy-customization`

## Debug-Only Routes

The following aliases are present only in debug builds:

- `/font-demo`
- `/trackertest`
- `/yolo-debug`

Production navigation should use `/activity-classifier` instead of
`/trackertest`.

## Verification

Named-route references are checked by
`test/routes/release_route_surface_test.dart`. Browser smoke evidence for the
current welcome, signup, login, configured startup, and missing-Supabase startup
paths is recorded in `docs/maintenance/CODEBASE_CLEANUP_AUDIT_2026-06-19.md`.
