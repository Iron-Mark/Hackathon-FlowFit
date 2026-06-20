# FlowFit Codebase Cleanup Audit - 2026-06-19

This audit records the current clutter, dependency, and DRY/refactor state for
the maintained fork. It intentionally avoids broad behavior changes. The goal is
to separate safe housekeeping from larger refactors that need their own branch
and verification pass.

## Scope

- Repo-local documentation, ignored artifacts, tracked root clutter, and stale
  references.
- Dependency freshness and deprecated package risk without upgrading packages.
- Code organization and DRY hotspots that should guide the next cleanup branch.

## Safe Cleanup Applied

- Moved the tracked root UI screenshot:
  - From: `flutter_01.png`
  - To: `docs/assets/screenshots/home-screen-snapshot-2026-06-18.png`
- Added `flutter_*.png` to `.gitignore` so future local Flutter screenshots do
  not return as root-level tracked artifacts.

No Dart behavior, migration SQL, workflows, or release scripts were changed in
this pass.

## App Cleanup Applied Later On 2026-06-19

A follow-up app-behavior cleanup pass removed several reachable stale surfaces:

- Removed the unused `lib/shared/navigation/app_router.dart` because FlowFit
  uses the `MaterialApp.routes` table in `lib/main.dart`.
- Removed the unused legacy dashboard tab files under `lib/screens/dashboard/`
  and the retired `lib/screens/track/random_workout_screen.dart`.
- Removed the direct `go_router` dependency after converting the remaining
  `context.go(...)` calls to Navigator-compatible behavior.
- Replaced the Track tab's retired random camera workout action with the
  maintained `/activity-classifier` route.
- Replaced synthetic OpenRouteService POIs with a real `/pois` request and an
  empty fallback when the API is unavailable.
- Replaced fake Buddy profile fallback data with a level-1 onboarding preview
  and explicit Buddy setup navigation.
- Replaced the Profile weight chart placeholder with a compact local trend
  widget.
- Added generic `WorkoutSession.fromJson` dispatch for running, walking, and
  resistance sessions.
- Kept web activity classification functional by using a deterministic
  heuristic fallback when native TFLite is unavailable.
- Changed dashboard mood fallbacks so missing or unavailable heart-rate data
  does not invent stress/calm minutes.
- Replaced the default wellness `SharedPreferences` provider failure with an
  explicit override-contract `StateError`.
- Added a visible startup configuration screen so web/mobile builds launched
  without real Supabase dart defines no longer fail as a blank Flutter canvas.
- Wired the Home water and meal quick actions into the active Health tab so
  they update hydration or open the Add Food dialog instead of dead-end copy.
- Removed stale dashboard navigation docs and the duplicate quick-start copy
  that still described retired tab shells.
- Added local persistence for Weight, Fitness, and Nutrition goal screens so
  their Save buttons reload saved user choices instead of only showing a
  transient success message.
- Added local persistence for Language, Units, and Notification settings.
  Individual unit rows now open selectable pickers instead of only displaying
  passive values.
- Replaced the Change Password screen's fake delayed success path with
  Supabase email/password reauthentication plus `auth.updateUser` password
  update, with local widget coverage for success, auth failure, and reused
  password validation.
- Replaced the Wellness onboarding timed success path with a real setup
  readiness check for body sensor permission, location permission, and Samsung
  Galaxy Watch connection.
- Removed the unused duplicate `lib/screens/profile/settings_screen.dart`; the
  maintained settings hub is `lib/screens/profile/settings/settings_screen.dart`.
- Made the reachable `/phone_heart_rate` route start the phone watch-data
  listener itself, with a visible retry state when listener startup fails.

Verification for the follow-up pass:

```powershell
dart analyze --format=machine
flutter analyze
flutter test --reporter compact
flutter build web --release --no-pub
flutter build web --release --no-pub --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
flutter build apk --debug --no-pub
flutter build apk --debug -t lib\main_wear.dart --no-pub
git diff --check
```

Result: local static checks and targeted startup tests passed. The unconfigured
web smoke now renders `build\web-smoke-unconfigured.png`, and the configured
web smoke renders `build\web-smoke-configured.png` plus route-click evidence
for `#/signup` and `#/login`. The latest full `flutter test` run reported
884 passing tests and 1 skipped test after the profile-goal, profile settings,
Change Password, and Wellness onboarding passes.

## Repository Inventory

Current source scan:

- Total `rg --files` source scan files: 762
- Dart files: 367
- Markdown files: 200
- Active Markdown files outside `docs/archive`: 188
- Archived Markdown files: 12
- PowerShell scripts: 17
- GitHub Actions workflows tracked under `.github/workflows`: 3

Active documentation folders:

- `docs/assets`
- `docs/code`
- `docs/features`
- `docs/implementation`
- `docs/maintenance`
- `docs/platform`
- `docs/presentation`
- `docs/release`
- `docs/scripts`
- `docs/supabase`
- `docs/testing`

## Documentation Findings

The documentation is usable but still cluttered from the original hackathon
history.

- `README.md` appears multiple times, but these are mostly scoped folder
  READMEs rather than accidental duplicates.
- `docs/QUICK_START.md` and `docs/TROUBLESHOOTING.md` have archived root copies
  under `docs/archive/root/`; keep the active versions and leave the archived
  copies as historical evidence unless a full archive cleanup is requested.
- Active docs still contain old package and placeholder references:
  - 36 active `com.example.flowfit` references
  - 23 active placeholder references such as project-ref replacement text
- Several active docs read like one-off fix logs rather than maintained docs,
  including `docs/FIX_FLUTTER.md`, `docs/BUILD_FIXES_APPLIED.md`, and older
  setup/fix summaries.
- Empty active docs remain and should either be rewritten or archived after link
  checks:
  - `docs/COMPREHENSIVE_AUDIT_AND_FIXES.md`
  - `docs/HOW_TO_TEST_HEART_RATE.md`
  - `docs/PHASE_2_3_COMPLETE.md`
  - `docs/RUN_INSTRUCTIONS.md`
  - `docs/SENSOR_BATCH_FIX.md`
  - `docs/SUPABASE_INTEGRATION_GUIDE.md`
  - `docs/TEST_CONNECTION_FIX.md`
  - `docs/WATCH_TENSORFLOW_INTEGRATION.md`

Recommended docs cleanup order:

1. Keep `README.md`, `docs/00_START_HERE.md`, `docs/QUICK_START.md`,
   `docs/TROUBLESHOOTING.md`, and current release/Supabase runbooks as the
   maintained path.
2. Archive or rewrite empty and one-off fix-log docs after confirming no active
   links break.
3. Replace active stale package-name placeholders only where they affect current
   developer setup, Supabase auth redirects, or release handoff.
4. Regenerate `docs/INDEX.md` after the archive pass so counts and navigation
   stay accurate.

## Dependency Findings

`flutter pub outdated --json` summary:

- Outdated packages: 158
- Direct dependencies outdated: 33
- Dev dependencies outdated: 6
- Transitive dependencies outdated: 119
- Discontinued packages: 3
- Retracted packages: 0
- Packages with advisories in the local report: 0

Discontinued packages:

- `wearable_rotary` direct dependency at `2.0.3`
- `build_resolvers` transitive dependency at `2.5.4`
- `build_runner_core` transitive dependency at `9.1.2`

Direct dependencies with notable upgrade pressure at initial audit time:

- `supabase_flutter` `2.10.3` to `2.15.0`
- `flutter_riverpod` `2.6.1` to `3.x`
- `riverpod_annotation` `2.6.1` to `4.x`
- `permission_handler` `11.4.0` to `12.x`
- `sensors_plus` `5.0.1` to `7.x`
- `share_plus` `10.1.4` to `13.x`
- `package_info_plus` `8.3.1` to `10.x`
- `flutter_local_notifications` `19.5.0` to `22.x`
- `ultralytics_yolo` `0.1.42` to `0.6.x`
- `fl_chart` `0.65.0` to `1.x`

Recommended dependency order:

1. Decide whether `wearable_rotary` is still needed. Remove it if Wear OS input
   can use platform primitives or another maintained package.
2. Upgrade low-risk patch/minor packages in one branch and run the full phone,
   Wear, and web gates.
3. Upgrade Supabase SDK packages in a dedicated branch because auth and database
   behavior are release-critical.
4. Upgrade Riverpod and code generation packages in a dedicated branch because
   generated APIs and provider annotations may need code edits.
5. Upgrade platform plugins in a dedicated branch because Android/iOS manifest
   permissions and runtime prompts can shift.
6. Upgrade camera and YOLO dependencies last because they affect native
   capabilities and model runtime compatibility.

No dependency versions were changed in the initial audit pass. The later app
cleanup removed the direct `go_router` dependency after the unused router and
remaining `context.go(...)` calls were removed.

## Code DRY And Refactor Findings

Largest Dart files by current scan:

- `lib/screens/profile/profile_screen.dart` - 1097 lines
- `lib/screens/workout/running/active_running_screen.dart` - 1044 lines
- `lib/screens/onboarding/survey_daily_targets_screen.dart` - 858 lines
- `lib/screens/wear/wear_heart_rate_screen.dart` - 853 lines
- `lib/screens/health/health_screen.dart` - 849 lines
- `lib/services/watch_bridge.dart` - 825 lines
- `lib/screens/profile/buddy_customization_screen.dart` - 806 lines
- `lib/features/activity_classifier/presentation/tracker_page.dart` - 765 lines
- `lib/screens/home/home_screen.dart` - 728 lines
- `lib/screens/home/widgets/stats_section.dart` - 647 lines

Main DRY/architecture hotspots:

- Profile repositories are split across core, domain, feature, and data paths:
  - `lib/core/domain/repositories/profile_repository.dart`
  - `lib/domain/repositories/i_profile_repository.dart`
  - `lib/features/profile/domain/repositories/profile_repository.dart`
  - `lib/core/data/repositories/profile_repository_impl.dart`
  - `lib/data/repositories/profile_repository.dart`
- Heart-rate repository contracts exist in both global domain and feature
  domain paths.
- Provider styles are mixed across legacy `lib/providers`, `lib/core/providers`,
  `lib/presentation/providers`, and feature-local providers.
- Large screens combine layout, state branching, business decisions, and
  persistence calls, which makes behavior-preserving changes riskier.

Recommended DRY/refactor order:

1. Pick the maintained profile repository contract and migrate callers to it
   behind compatibility shims.
2. Consolidate heart-rate repository contracts after confirming phone, watch,
   and fitness feature call sites.
3. Split the largest screens into view widgets and controllers without changing
   route names, provider names, or persistence behavior.
4. Consolidate workout session save/list logic across running, walking, and
   resistance flows.
5. Move watch bridge DTO parsing/serialization to small shared helpers with
   focused tests.
6. Retire legacy provider paths only after the compatibility shims have no
   remaining callers.

## Product TODOs Still Present

There are 32 TODO-style references outside `docs/archive`:

- 17 in `lib`
- 2 in `test`
- 13 in active docs

The code TODOs are mostly unfinished product behavior, not safe housekeeping:

- Demo dashboard baseline data replacement.
- Full running setup implementation.
- Wear workout start/stop tracking.
- Wear relax audio playback.
- Backend upload for heart-rate data.
- Disabled or incompatible YOLO pose detection path.
- Placeholder activity and sleep repository implementations.

These should be planned as feature work, not silently removed.

## Verification Used For This Audit

- `git status --short --branch`
- `rg --files`
- active-doc scans excluding `docs/archive/**`
- `flutter pub outdated --json`
- targeted source-size and TODO scans

Follow-up branches should run the full local gate after any Dart, dependency, or
workflow changes:

```powershell
flutter pub get
flutter analyze
flutter test --reporter compact
flutter build web --release --no-pub
flutter build apk --debug --no-pub
flutter build apk --debug -t lib\main_wear.dart --no-pub
```
