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

## App Readiness Refresh On 2026-06-21

A later button and feature-readiness pass added durable source guards:

- `test/scripts/navigation_route_guard_test.dart` now scans static
  `Navigator.pushNamed`, `pushReplacementNamed`, and
  `pushNamedAndRemoveUntil` calls under `lib/`.
- The guard compares those static targets with release `MaterialApp.routes` in
  `lib/main.dart`, and separately prevents production navigation from relying
  on routes registered only inside `if (kDebugMode)`.
- This keeps newly added route-opening buttons from silently shipping with a
  missing route registration.
- The same guard scans slash-prefixed string literals and allows only release
  routes, debug-only route declarations, and the known `/km` display unit.
  This catches dynamic route-map mistakes that direct `Navigator` regexes can
  miss.
- `test/scripts/interactive_action_guard_test.dart` scans production Dart
  source for exact empty `onPressed`, `onTap`, and `onLongPress` handlers so
  visible controls do not become inert no-ops.
- `test/scripts/interactive_surface_coverage_guard_test.dart` scans
  production interactive surfaces and requires a matching action-oriented test
  reference, so newly introduced buttons/widgets do not avoid the offline smoke
  gate through incidental source mentions.
- `test/routes/release_route_surface_test.dart` now derives release routes
  before the debug-only `if (kDebugMode)` route block and asserts that the
  debug route menu import/widget mount stay out of the production app shell.
- `SurveyIntroScreen` now saves smart default profile data through the existing
  survey completion handler before routing skip users to the dashboard, so the
  "do this later" action does not send the same user back through onboarding on
  the next login/startup check.
- `test/screens/wear/wear_app_entrypoint_test.dart` now boots the real
  `WearApp` shell to catch entrypoint regressions beyond the existing Wear
  dashboard and heart-rate screen tests.
- The Weight, Fitness, and Nutrition goal editors now share
  `GoalSaveButton`, keeping their save/loading behavior consistent while
  removing duplicated button styling from the three profile goal screens.

Current local verification after the source guards:

```powershell
dart analyze --format=machine
flutter analyze
flutter test test\scripts\interactive_action_guard_test.dart test\scripts\navigation_route_guard_test.dart --reporter compact
flutter test --reporter compact
flutter build apk --debug --no-pub
flutter build apk --debug -t lib\main_wear.dart --no-pub
flutter build web --release --no-pub
pwsh -NoProfile -File scripts\store_release_build.ps1 -Target Web -SkipFlutterPubGet -SkipValidation -SupportEmailVerified -AllowDirty
pwsh -NoProfile -File scripts\verify_web_deployment.ps1 -BaseUrl http://127.0.0.1:8791/Hackathon-FlowFit -SupportEmail marksiazon.dev@gmail.com -AllowInsecureLocalhost
Playwright MCP browser smoke against http://127.0.0.1:8792/Hackathon-FlowFit/
git diff --check
```

Result: both analyzers passed, the targeted source guards passed, and the full
Flutter test suite reported 1246 passing tests after the smart-default skip and
Wear entrypoint smoke additions. Android phone debug, Wear debug, and web
release builds passed. The web release wrapper also produced a GitHub Pages
base-href artifact with the verified maintainer support inbox, and
`verify_web_deployment.ps1` passed 15 local HTTP checks against that artifact.
The Playwright MCP browser smoke loaded the production-base web artifact at
`#/welcome`, enabled Flutter semantics, verified the visible welcome content,
clicked `Get Started` to `#/signup`, clicked `Log In` to `#/login`, and clicked
the login-screen `Sign Up` link back to `#/signup`; console verification
reported 0 warnings and 0 errors for the run.
`git diff --check` reported no whitespace errors, only existing Windows CRLF
conversion warnings. A current `lib` scan found no direct `TODO`, `FIXME`,
`coming soon`, `not implemented`, or `UnimplementedError` markers in reachable
production source; remaining `--` values are no-data display states for metrics
such as pace, steps, and heart rate.

This refresh does not prove live backend/device behavior. Supabase auth and
database smoke tests, watch/sensor/GPS checks, and store-signing checks still
require external credentials or physical devices.

Historical local verification after the profile-goal DRY extraction:

```powershell
dart analyze --format=machine
flutter analyze
flutter test --reporter compact
flutter build apk --debug --no-pub
flutter build apk --debug -t lib\main_wear.dart --no-pub
flutter build apk --debug --no-pub
flutter build web --release --no-pub
git diff --check
```

Result: all commands exited successfully. The final Android debug artifact at
`build/app/outputs/flutter-apk/app-debug.apk` is the phone build with SHA-256
`FEB121F0ADF49F2748F667207DF6D78E5EA497491C668DC6DDA5AE8761C025DA`. The latest
web release entrypoint `build/web/main.dart.js` has SHA-256
`C0532965C15760365D9DDC6C447D0B2F853A048D332EA24F2081823684D33B47`.

Historical local verification after the phone clear-state and onboarding unit
conversion fixes:

```powershell
flutter test test\core\utils\height_measurements_test.dart test\screens\onboarding\survey_measurements_activity_actions_test.dart test\screens\phone\phone_home_test.dart --reporter compact
dart analyze --format=machine
flutter analyze
flutter test --reporter compact
flutter build apk --debug --no-pub
flutter build apk --debug -t lib\main_wear.dart --no-pub
flutter build web --release --no-pub
flutter build apk --debug --no-pub
git diff --check
```

Result: all commands exited successfully. The focused regression suite covered
20 tests across height measurement helpers, onboarding body-measurement unit
switching, and phone watch-data actions. The full Flutter test suite reported
1083 passing tests. The final Android debug artifact at
`build/app/outputs/flutter-apk/app-debug.apk` is the phone build with SHA-256
`1C04C7F404E14E7CA1B5C0C8B980EE646B8B8C1C1A66CA5A171DF8660D4EF8A6`. The
latest web release entrypoint `build/web/main.dart.js` has SHA-256
`1EAE6FDC22CF3F76B00C15EA04491EDB932D8CB727725482AAB92BA9931861FD`.

Additional local browser smoke for the rebuilt web app:

```powershell
flutter build web --release --no-pub --output build\web-smoke-configured --dart-define=SUPABASE_URL=<shape-valid non-secret smoke URL> --dart-define=SUPABASE_PUBLISHABLE_KEY=<shape-valid non-secret smoke key>
python -m http.server 8796 --bind 127.0.0.1
Playwright MCP browser smoke against http://127.0.0.1:8796/#/welcome
```

Result: the separate configured smoke artifact loaded at `#/welcome`, rendered
the expected "Find Your Flow" welcome copy, and exposed the `Get Started` and
`Log In` actions through Flutter semantics. `Get Started` routed to `#/signup`
with the expected signup fields and Terms/Privacy actions. The signup `Log In`
action routed to `#/login` with the expected email/password fields, forgot
password action, and `Sign Up` link. The login `Sign Up` link routed back to
`#/signup`. Playwright console collection reported 0 warnings and 0 errors.

Additional release-readiness audit:

```powershell
$env:FLOWFIT_SUPPORT_EMAIL = 'marksiazon.dev@gmail.com'
$env:FLOWFIT_SUPPORT_EMAIL_VERIFIED = 'true'
pwsh -NoProfile -File scripts\render_supabase_email_templates.ps1 -SupportEmail $env:FLOWFIT_SUPPORT_EMAIL -SupportEmailVerified
pwsh -NoProfile -File scripts\release_readiness_audit.ps1 -SupportEmailVerified -McpMode Release -OutFile build\release-readiness-audit-autonomous-2026-06-21-release-mcp.json
```

Result: rendered dashboard-ready Supabase confirmation email templates to
`build/supabase-email-templates/` for the verified maintainer inbox. The release
posture audit reported 68 pass, 2 warnings, and 0 failures. The remaining
warnings were external/environmental: `FLOWFIT_PUBLIC_WEB_BASE_URL` still needs
a deployed HTTPS store-compliance host, and Docker CLI is unavailable on this
machine for local Supabase CLI validation. The audit passed the project-scoped
read-only Supabase MCP release posture, canonical migration static checks,
local Supabase client config shape, Android/iOS release guards, support inbox
verification, and public privacy/account-deletion page checks.

Current local verification after dashboard mood fallback, formatter cleanup,
CI format-gate wiring, auth-route gating, direct-route guards, and docs hub
refresh:

```powershell
flutter test test\providers\dashboard_providers_test.dart --reporter compact
pwsh -NoProfile -File scripts\verify_offline_app_actions.ps1 -SkipPubGet
flutter test test\screens\auth\welcome_screen_actions_test.dart test\screens\auth\login_signup_actions_test.dart test\screens\splash_screen_test.dart --reporter compact
flutter test test\scripts\navigation_route_guard_test.dart test\scripts\interactive_action_guard_test.dart --reporter compact
flutter test test\app\flowfit_phone_app_navigation_smoke_test.dart --reporter compact
<docs hub link check for docs\INDEX.md and docs\README.md>
dart format <Git-listed Dart files, chunked for Windows command length>
dart format --output=none --set-exit-if-changed <tracked Git Dart files, chunked>
git diff --check
dart analyze --format=machine
flutter analyze
flutter test --reporter compact
flutter build apk --debug --no-pub
flutter build apk --debug -t lib\main_wear.dart --no-pub
flutter build web --release --no-pub
flutter build web --release --no-pub --output build\web-smoke-current --dart-define=SUPABASE_URL=<shape-valid non-secret smoke URL> --dart-define=SUPABASE_PUBLISHABLE_KEY=<shape-valid non-secret smoke key>
npm run web:smoke -- --base-url http://127.0.0.1:8799 --browser-executable "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --out-file build\web-app-smoke-current.json
flutter build apk --debug --no-pub
pwsh -NoProfile -File scripts\release_readiness_audit.ps1 -SupportEmailVerified -McpMode Release -OutFile build\release-readiness-audit-autonomous-2026-06-21-current.json
```

Result: all local commands exited successfully. The dashboard mood provider now
falls back to neutral mood data when the heart-rate repository is unavailable,
so transient local heart-rate failures do not degrade the home dashboard into a
user-visible unavailable state. Git-listed Dart formatting is clean for the 421
tracked Dart files; `.github/workflows/flutter-ci.yml` now enforces the same
tracked-source format gate on Ubuntu CI with `git ls-files -z '*.dart' | xargs
-0 dart format --output=none --set-exit-if-changed`, and adds a Windows
`verify_offline_app_actions.ps1` smoke job for route/action guard coverage and
focused offline button-action coverage across auth, onboarding, profile,
dashboard, health, phone, Wear, wellness, workout, mood, camera, and shared
widgets.
The local Windows shell does not have `bash`, so the exact CI shell pipeline was
verified through the equivalent chunked PowerShell gate instead. `git diff
--check` reported no
whitespace errors, only Windows CRLF conversion warnings. The full Flutter test
suite passed after the formatter cleanup. The welcome screen, login screen, and
splash screen now share the same completed-survey gate for authenticated users,
so incomplete authenticated users are routed to the age gate rather than being
sent directly to the dashboard. The splash screen also skips auth-route
resolution when it is mounted underneath another current initial route, so a
direct Flutter web route such as `/#/login` is no longer replaced by the delayed
startup redirect to `/#/welcome`. `test/scripts/navigation_route_guard_test.dart`
now inventories reviewed direct `MaterialPageRoute` pushes so non-named
navigation paths cannot grow silently outside the release route guard. The docs
hub was refreshed to point at current maintained-fork runbooks and maintained
package IDs; the focused docs link check passed for `docs\INDEX.md` and
`docs\README.md`. The Node/Playwright web smoke script verified
`#/welcome`, `Get Started` to `#/signup`, signup `Log In` to `#/login`, direct
`#/login` rendering, and login `Sign Up` back to `#/signup`; it wrote
`build\web-app-smoke-current.json` with 5 passes, 0 console warnings, 0 console
errors, and 0 failed requests. Phone debug APK, Wear debug APK, and web release
builds passed. The final Android debug artifact at
`build/app/outputs/flutter-apk/app-debug.apk` is the phone build with SHA-256
`FE46723DFEAAF9307805DADF50CA0EA1F554597F3F609729A9D1D1F269864BC3`. The latest
web release entrypoint `build/web/main.dart.js` has SHA-256
`A24073B59F19212B935CDC68273C77AD1144927D595124CFE3B0E0C3AD2CA91B`. The
configured web smoke entrypoint at `build/web-smoke-current/main.dart.js` has
SHA-256 `8C50509C352474C2EC05643ACC6C022A9E16835686892117FF55F32F2B3B865E`.
The current release posture audit reported 68 pass, 2 warnings, and 0 failures.
The remaining warnings are still external/environmental:
`FLOWFIT_PUBLIC_WEB_BASE_URL` needs a deployed HTTPS store-compliance host, and
Docker CLI is unavailable on this machine for local Supabase CLI validation.

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

## Product TODO Scan Refresh

The earlier TODO-style snapshot in this audit was superseded by the
2026-06-21 source refresh. Current scan:

- `rg -n "TODO|FIXME|coming soon|not implemented|UnimplementedError" lib`
  returned no matches.
- Remaining placeholder cleanup risk is in docs, dependency decisions, external
  backend/device verification, and release-process artifacts rather than direct
  production-source markers.

Do not reintroduce the older `17 in lib` count unless a fresh command output
shows current production-source matches again.

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
