# Dashboard Update Summary

This document records the maintained dashboard shell after the cleanup pass on
2026-06-19. Older hackathon notes referred to retired tab classes and the
debug-only tracker alias; those legacy files/routes have been removed from the
production shell.

## Current Structure

`DashboardScreen` owns the bottom navigation state and renders these active
screens:

- Home: `lib/screens/home/home_screen.dart`
- Health: `lib/screens/health/health_screen.dart`
- Track: `lib/screens/track/track_screen.dart`
- Progress: `lib/screens/progress/progress_screen.dart`
- Profile: `lib/screens/profile/kids_profile_screen.dart`

## Current Home Actions

- `Start AI Workout` opens `/activity-classifier`.
- `Drink Water` switches to Health and adds 250 ml to today's hydration log.
- `Log Meal` switches to Health and opens the Add Food dialog.
- `Track Steps` opens `/mission`.
- `Heart Check` opens `/phone_heart_rate`; the route now starts the phone
  watch-data listener directly and shows a retry path if startup fails.

## Notes

- The active dashboard no longer imports the deleted legacy tab files under
  `lib/screens/dashboard/`.
- Debug-only aliases such as `/trackertest` remain gated by `kDebugMode` in the
  route table and are not production navigation targets.
- Further dashboard cleanup should focus on splitting the large active screen
  files into smaller widgets without changing route names or tab behavior.
