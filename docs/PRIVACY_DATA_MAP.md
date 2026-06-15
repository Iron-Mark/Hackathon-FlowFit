# FlowFit Privacy and Data Map

Last updated: 2026-06-14

This is an engineering source of truth for Play Console Data safety, App Store
privacy labels, privacy-policy drafting, and reviewer notes. It is not legal
advice; the maintainer should review it before store submission.

## Current Policy Requirements Checked

- Google Play requires accurate User Data disclosures, a privacy policy in Play
  Console and in the app, secure handling, runtime permissions, and account
  deletion request paths for apps that create accounts.
- Google Play Data safety must include app data practices plus third-party SDK
  practices.
- Apple App Store Connect requires app privacy responses and a privacy policy
  URL. Apple also requires apps that support account creation to let users
  initiate account deletion in the app.

Sources:

- Google Play User Data policy:
  https://support.google.com/googleplay/android-developer/answer/10144311
- Google Play Data safety form:
  https://support.google.com/googleplay/android-developer/answer/10787469
- Apple App Store Connect app privacy:
  https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- Apple account deletion reminder:
  https://developer.apple.com/news/?id=12m75xbj

## Data Inventory

| Data category | Examples in FlowFit | Source | Purpose | Stored where | Store disclosure notes |
| --- | --- | --- | --- | --- | --- |
| Account identifiers | Supabase auth user ID, email | Signup/login | Authentication, account recovery, account linking | Supabase Auth | Personal info / identifiers |
| Profile data | Name, nickname, age, gender, height, weight, goals, units, daily targets, kids-mode flag | Onboarding/profile screens | Personalization, fitness targets, Buddy setup | Supabase `user_profiles`, local cache | Personal info, health/fitness if tied to goals/body metrics |
| Buddy profile data | Companion name/color/type, level, XP, streaks, selected goals | Buddy onboarding/profile | Companion progression and onboarding state | Supabase `buddy_profiles`, local cache | App activity / user-generated content |
| Workout data | Workout type, duration, distance, steps, pace, calories, route/session metadata | Workout screens | Workout tracking and history | Supabase `workout_sessions`, local cache | Health and fitness / app activity |
| Heart-rate data | BPM, IBI values, timestamps, sensor status | Samsung Health Sensor API / watch bridge | Heart-rate display, wellness state, activity classification | Supabase `heart_rate`, local SQLite/cache | Health and fitness, sensitive health data |
| Activity and motion data | Step counts, accelerometer/rotation-derived activity classification, active minutes | Device sensors/plugins | Activity tracking and workout detection | Local cache and derived session records | Health and fitness / device sensor data |
| Location data | Current location, background geofence hits, route/path points | Geolocator/native geofence | Wellness missions, calming routes, walking/running maps | Local state and workout/mission records | Location; background use needs prominent disclosure/consent |
| Camera/photo data | Live camera frames or selected images for YOLO/debug/share features | Camera and image picker | User-triggered detection and share-card/profile features | Processed locally unless user saves/shares | Photos/videos and camera access; disclose if stored or uploaded |
| Notifications | Notification permission/preference and local alerts | App settings/permission prompt | Geofence and wellness reminders | Local preferences and profile flags | App info / device permissions |
| Diagnostics/logs | Error messages, build/runtime logs in development | App runtime and developer tools | Debugging and reliability | Local logs unless connected to a backend later | Declare only if collected/transmitted in production |

## Third-Party Services and SDKs

| Provider/package | Role | Data considerations |
| --- | --- | --- |
| Supabase | Auth, database, API transport | Stores account, profile, Buddy, workout, and heart-rate records configured by FlowFit. |
| Samsung Health Sensor API | Wear OS heart-rate sensor access | Reads heart-rate sensor data on supported Samsung devices after permission. |
| Geolocator/native_geofence/flutter_map | Location and map/geofence features | Accesses foreground/background location for wellness missions and routes. |
| Camera/image_picker/ultralytics_yolo/tflite_flutter | User-triggered camera/image inference | Processes camera frames/images for detection/classification features. |
| flutter_local_notifications | Local alerts | Uses device notification permission for reminders; no remote push is configured in this repo. |

Before submission, review each SDK provider's current privacy guidance and
reflect any automatic collection/transmission in Play Data safety and App Store
privacy labels.

## Security and Retention

- Supabase traffic uses HTTPS.
- Public database tables are protected by RLS in the canonical migration.
- Store releases must not include service-role keys or secret keys.
- Flutter runtime config must use only the project URL and publishable key.
  Prefer `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` Dart defines; ignored
  `lib/secrets.dart` is only a local fallback for release/audit scripts.
- Account deletion is initiated in-app through `request_account_deletion()`.
  The function deletes app-owned public records immediately and creates a
  pending `account_deletion_requests` row for privileged auth-account deletion.
- While a deletion request is `pending` or `processing`, RLS blocks
  authenticated client inserts and updates on app-owned public data so another
  active session cannot recreate deleted rows before admin processing.
- The in-app deletion flow also clears known local profile, survey, Buddy,
  wellness, sync queue, profile-image, and heart-rate SQLite data on the
  current device on a best-effort basis.
- `web/privacy.html` is the public privacy-policy page that should be hosted
  with Flutter web before store submission.
- `web/account-deletion.html` is the public account-deletion page for users who
  removed the app or cannot access the in-app deletion flow.

## Disclosure Requirements to Resolve Before Store Review

- Release builds request background location: Android declares
  `ACCESS_BACKGROUND_LOCATION` and native geofence components, while iOS
  declares `UIBackgroundModes` location. Keep prominent in-app disclosure before
  requesting permission and describe background geofence/mission usage in Play
  Data safety and App Store privacy forms.
- Confirm whether camera/photo features are user-facing in production or debug
  only. Remove or hide debug-only routes before release if they are not intended
  for store users.
- Confirm whether health/heart-rate records are uploaded to Supabase in
  production. If yes, disclose health and fitness data collection.
- Publish `privacy.html` and `account-deletion.html` from the deployed Flutter
  web output before Play/App Store submission.
