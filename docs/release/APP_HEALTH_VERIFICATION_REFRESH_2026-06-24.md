# FlowFit App Health Verification Refresh - 2026-06-24

This refresh captures the current maintained-fork app-health evidence after the
Wear dashboard reachability work and live Supabase recovery checks. It does not
replace the historical Play Store AAB handoff. Use it as the latest proof that
the current `main` branch is locally, remotely, and live-service verified across
the controllable surfaces on this Windows machine.

## Source State

| Field | Value |
| --- | --- |
| Repository | `Iron-Mark/Hackathon-FlowFit` |
| Branch | `main` |
| Commit | `ad0cd01f6935244b2382f1bd7b0e5875671f0c15` |
| Commit subject | `feat(wear): expose workout and relax tools` |
| Local worktree | Clean, matched `origin/main` |
| Public web URL | `https://iron-mark.github.io/Hackathon-FlowFit` |
| Supabase project | `xhmkghwijqpvnbpeeckg` |

Secrets used for live verification stayed in ignored local files and process
environment only. Do not paste or commit Supabase passwords, publishable keys,
smoke-user passwords, signing passwords, or service-role credentials.

## Verification Results

| Area | Command or source | Result |
| --- | --- | --- |
| Strict release audit | `scripts/release_readiness_audit.ps1 -Strict -EnvFile .env` | `69 pass, 1 warn, 0 fail` |
| Supabase backend schema and RLS | `scripts/verify_supabase_backend.ps1 -DbUrl <pooler-url> -Output json` | `19 pass, 0 fail` |
| Supabase DB lint | `npx -y supabase@latest db lint --db-url <pooler-url> --schema public --level warning --fail-on error --output-format json` | No schema errors |
| Supabase advisors | `npx -y supabase@latest db advisors --db-url <pooler-url> --type all --level warn --fail-on warn --output-format json` | No issues found |
| Supabase app data smoke | `scripts/verify_supabase_app_smoke.ps1 -EnvFile .env -AllowExternalWrites` | `6 pass, cleanup passed` |
| Flutter dependencies | `flutter pub get` | Passed |
| Dart format | `scripts/verify_dart_format.ps1` | `461` tracked Dart files checked, `0` changed |
| Dart analyzer | `dart analyze --format=machine` | Passed |
| Flutter analyzer | `flutter analyze` | No issues found |
| Flutter tests | `flutter test --reporter compact` | Passed |
| Android phone debug APK | `flutter build apk --debug --no-pub` | Passed |
| Wear debug APK | `flutter build apk --debug -t lib\main_wear.dart --no-pub` | Passed |
| Live web deployment | `scripts/verify_web_deployment.ps1 -BaseUrl <public-web-url>` | `15 pass, 0 fail` |
| Live web app action smoke | `npm run web:smoke -- --base-url <public-web-url>` | `58 pass, 0 console errors, 0 failed requests` |
| Android phone emulator smoke | `scripts/verify_android_phone_smoke.ps1 -Device emulator-5554 -EnvFile .env` | `24 pass, 0 warn, 0 fail` |
| Android live-auth emulator smoke | `scripts/verify_android_live_auth_smoke.ps1 -Device emulator-5554 -EnvFile .env` | `120 pass, cleanup passed` |
| Wear emulator smoke | `scripts/verify_wear_emulator_smoke.ps1 -Device emulator-5556` | `21 pass, 0 warn, 0 fail` |
| Remote Flutter CI | GitHub Actions run `28047513405` | Success on `ad0cd01` |
| Remote Flutter Web Pages | GitHub Actions run `28047512937` | Success on `ad0cd01` |

The strict release audit warning is only for missing Docker CLI on this Windows
machine. Supabase CLI access, DB lint, advisors, backend verification, and live
app smoke all ran through the project pooler and passed.

## Evidence Artifacts

These files are ignored build evidence. Regenerate them before a final release
handoff if source, schema, deployment, or environment values change.

| Evidence | Path | Size | SHA-256 |
| --- | --- | ---: | --- |
| Strict release audit | `build/release-readiness-audit-latest.json` | 12,835 bytes | `30a0b3c00e45f6b7428f904cd993fbdcdf77bc85888c28ce00cd81a738c19780` |
| Supabase app smoke | `build/supabase-app-smoke.json` | 1,625 bytes | `eede5aa922852f8560a85fa1c9a5559bde26015f8bca3021d2ea4c1b8243d0f2` |
| Live web deployment verification | `build/web-deployment-live-verification.json` | 2,478 bytes | `8505d9b6acaa7de87b33eab41d2db3ba80e3e8cf9627f37ac6b4f97e4bbff420` |
| Live web action smoke | `build/web-app-smoke-live.json` | 11,998 bytes | `82769939256fb78d12b6d907b9ed72d40be60af7084532ab980555a04e86175b` |
| Android phone emulator smoke | `build/android-phone-smoke-latest.json` | 6,537 bytes | `4405afc10eb2edd3454c43b620171bf5b41e55b4c195e6832d185dcca12ca4a0` |
| Android live-auth emulator smoke | `build/android-live-auth-smoke-latest.json` | 29,831 bytes | `f3089cb4d2e8427b33c608827488ffa687b000d989993c543cb65582b301b1b3` |
| Wear emulator smoke | `build/wear-emulator-smoke-latest.json` | 6,110 bytes | `911ef9719c5a9b2a311cb7b19781a63af4eca6e811ed48e7498ef7c622974189` |

Remote CI evidence:

- Flutter CI:
  <https://github.com/Iron-Mark/Hackathon-FlowFit/actions/runs/28047513405>
- Flutter Web Pages:
  <https://github.com/Iron-Mark/Hackathon-FlowFit/actions/runs/28047512937>

## Emulator Notes

- `emulator-5554` was the Android phone emulator:
  `sdk_gphone64_x86_64`, Android 15.
- The Wear API 36 AVD connected but did not complete Android framework boot.
  That was an emulator runtime issue, not an app launch failure.
- The Wear API 34 AVD `Pulsify_Wear_API_34` booted successfully as
  `emulator-5556`, ran the Wear smoke, and was stopped after verification.
- The Wear smoke verified the Wear entrypoint, Heart Rate screen, Samsung
  Health unavailable message, simulated BPM fallback, Start/Stop path, and
  absence of crash markers.

## Current Residual Gaps

The current branch is strongly verified for controllable local, CI, live web,
live Supabase, Android emulator, and Wear emulator surfaces. The following
items still require external hardware, OS, or store access before the broad
"fully working" goal can be closed:

- Real Galaxy Watch hardware with Samsung Health Tracking Service installed.
- Real Android device install from Play internal testing after uploading a
  signed AAB.
- iOS archive/export on macOS with Xcode, certificates, and provisioning
  profiles.
- Final store-console review steps, content rating, data safety, and release
  submission.

