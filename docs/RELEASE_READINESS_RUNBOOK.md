# FlowFit Release Readiness Runbook

Last updated: 2026-06-15

This is the current source of truth for getting FlowFit ready for Play Store,
App Store, and Flutter web deployment.

## Current Local Status

- Android debug APK builds locally.
- Wear OS debug APK builds locally from `lib/main_wear.dart`.
- Flutter web JavaScript release build builds locally.
- Flutter web Wasm smoke build builds locally when explicitly requested.
- Analyzer and unit/widget tests pass locally.
- iOS can be prepared in this repo, but final archive/signing must run on macOS
  with Xcode and an Apple Developer team.
- Supabase project creation, MCP OAuth, production credentials, and live schema
  verification require the owner account.

## Required Secrets

Do not commit these files:

- `lib/secrets.dart`
- `android/key.properties`
- `android/upload-keystore.jks` or any `android/*.jks`
- Apple signing certificates/profiles, `.p12`, `.mobileprovision`,
  `.provisionprofile`, App Store Connect `AuthKey_*.p8`, or export-options
  plist files

Preferred production/store/web Supabase client inputs:

```powershell
$env:SUPABASE_URL = 'https://PROJECT_REF.supabase.co'
$env:SUPABASE_PUBLISHABLE_KEY = 'REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY'
```

The tracked app config reads those values from Dart defines. The production
wrapper validates the environment values, or falls back to ignored
`lib/secrets.dart` when both environment values are absent, then passes the
resolved values to Flutter without printing the key.

For handoff, copy `.env.release.example` to ignored `.env.release`, fill the
real values locally, and pass `-EnvFile .env.release` to the strict audit or
production wrapper. The file uses simple `NAME=value` lines and is gitignored.

Optional local fallback shape:

```dart
class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT_REF.supabase.co';
  static const String publishableKey = 'sb_publishable_YOUR_KEY';

  @Deprecated('Use publishableKey instead.')
  static const String anonKey = publishableKey;
}
```

After creating the Supabase project, the local helper can write ignored fallback
`lib/secrets.dart` without printing the key:

```powershell
pwsh -NoProfile -File scripts/configure_local_release.ps1 `
  -SupabaseUrl 'https://PROJECT_REF.supabase.co' `
  -SupabasePublishableKey 'REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY' `
  -Force
```

## Android Play Store Setup

1. Use either an ignored local signing file or CI-safe signing env secrets:
   - Local file path: copy `android/key.properties.example` to
     `android/key.properties`, then generate or place the upload keystore in
     `android/upload-keystore.jks`.
   - Env/CI path: set `FLOWFIT_ANDROID_KEYSTORE_BASE64`,
     `FLOWFIT_ANDROID_KEYSTORE_PASSWORD`, `FLOWFIT_ANDROID_KEY_ALIAS`, and
     `FLOWFIT_ANDROID_KEY_PASSWORD`. `scripts/store_release_build.ps1`
     materializes ignored signing files for the build and removes them before
     exit when it created them. If `FLOWFIT_ANDROID_KEYSTORE_FILE_NAME`
     points to an existing file, the wrapper fails instead of overwriting it.
2. Set production package/auth values in `android/gradle.properties`:

```properties
FLOWFIT_ANDROID_APPLICATION_ID=com.oldstlabs.flowfit
FLOWFIT_AUTH_SCHEME=com.oldstlabs.flowfit
```

Create or update tracked non-secret Android release identity in
`android/gradle.properties` with:

```powershell
pwsh -NoProfile -File scripts/configure_local_release.ps1
```

4. Build Dart with the same auth schemes. The native manifest reads the Gradle
   properties above; Flutter code reads these `--dart-define` values:

```powershell
$authScheme = 'com.oldstlabs.flowfit'
$supportEmail = 'support@flowfit.com'
```

5. Add the production auth scheme to Supabase redirect URLs:

```text
com.oldstlabs.flowfit://auth-callback
```

6. Build the Play Store artifact:

```powershell
pwsh -NoProfile -File scripts/store_release_build.ps1 -Target Android
```

The production wrapper always validates Supabase client config before building
any target, even if `-RunStrictAudit` is not passed. Prefer
`SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`; if they are absent, the wrapper
can use ignored `lib/secrets.dart` as a local fallback. The values must contain
a real Supabase Project URL and current `sb_publishable_` key, not
placeholders, the old project ref, a service-role key, or a secret key.

For CI or an ephemeral release machine, provide those Gradle properties plus
the signing env secrets, then run the release wrapper instead of committing key
material:

```powershell
$env:ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID = 'com.oldstlabs.flowfit'
$env:ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME = 'com.oldstlabs.flowfit'
$env:SUPABASE_URL = 'https://PROJECT_REF.supabase.co'
$env:SUPABASE_PUBLISHABLE_KEY = 'REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY'
$env:FLOWFIT_ANDROID_KEYSTORE_BASE64 = 'REPLACE_WITH_BASE64_ENCODED_UPLOAD_KEYSTORE'
$env:FLOWFIT_ANDROID_KEYSTORE_PASSWORD = 'REPLACE_WITH_UPLOAD_KEYSTORE_PASSWORD'
$env:FLOWFIT_ANDROID_KEY_ALIAS = 'upload'
$env:FLOWFIT_ANDROID_KEY_PASSWORD = 'REPLACE_WITH_UPLOAD_KEY_PASSWORD'
pwsh -NoProfile -File scripts/store_release_build.ps1 -Target Android
```

Direct `flutter build appbundle` still requires ignored `android/key.properties`
and the referenced keystore to exist before Gradle runs.

If no `android/key.properties` exists, the repo still falls back to debug
signing only when Gradle property `FLOWFIT_ALLOW_DEBUG_RELEASE_SIGNING=true`
is set, usually through env var
`ORG_GRADLE_PROJECT_FLOWFIT_ALLOW_DEBUG_RELEASE_SIGNING=true`. That artifact is
not acceptable for Play Store upload.
The strict audit and production wrapper reject local smoke IDs such as
`com.flowfit.smoke`, example IDs such as `com.example.*` and
`com.yourcompany.*`, and reserved `.example`, `.invalid`, `.test`, localhost,
or IP-loopback web hosts.

For a local release smoke build without an upload keystore:

```powershell
$env:ORG_GRADLE_PROJECT_FLOWFIT_ALLOW_DEBUG_RELEASE_SIGNING = 'true'
$env:ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID = 'com.flowfit.smoke'
$env:ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME = 'com.flowfit.smoke'
flutter build appbundle --release --no-pub `
  --dart-define=FLOWFIT_AUTH_SCHEME=com.flowfit.smoke `
  --dart-define=FLOWFIT_SUPPORT_EMAIL=support@flowfit.com
Remove-Item Env:\ORG_GRADLE_PROJECT_FLOWFIT_ALLOW_DEBUG_RELEASE_SIGNING
Remove-Item Env:\ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID
Remove-Item Env:\ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME
```

## App Store Setup

1. Set production iOS bundle/auth values in `ios/Flutter/FlowFit.xcconfig`:

```xcconfig
FLOWFIT_IOS_BUNDLE_IDENTIFIER = com.oldstlabs.flowfit
```

2. Set the support inbox and optional Xcode export-options plist on the macOS
   build host:

```bash
export FLOWFIT_SUPPORT_EMAIL=support@flowfit.com
# Optional when Xcode export needs an explicit profile:
export FLOWFIT_IOS_EXPORT_OPTIONS_PLIST=$HOME/export_options.plist
```

3. Add the production scheme to Supabase redirect URLs:

```text
com.oldstlabs.flowfit://auth-callback
```

Run final iOS artifact generation on macOS with PowerShell 7, Xcode, and Apple
signing configured. The wrapper derives Dart auth schemes from
`ios/Flutter/FlowFit.xcconfig`, requires a clean git working tree, and runs
validation before building:

```bash
flutter pub get
pwsh -NoProfile -File scripts/store_release_build.ps1 -Target iOS
```

Before archive/upload:

- Use macOS with Xcode; Flutter's iOS release flow is not available from the
  Windows Flutter toolchain.
- Set a production bundle ID in `ios/Flutter/FlowFit.xcconfig`; the Xcode
  project reads that value through `PRODUCT_BUNDLE_IDENTIFIER`.
- Assign an Apple Developer team.
- Configure signing certificates and provisioning profiles.
- Review App Store privacy labels for location, motion/activity, camera,
  photos, health/heart-rate-related data, account data, and diagnostics.

The wrapper runs `flutter build ipa --release --no-pub`, passes Dart auth/support
defines derived from the iOS xcconfig, honors `FLOWFIT_IOS_EXPORT_OPTIONS_PLIST`
when set, and records the IPA plus archive in `build/store-release-artifacts.json`.
Manual fallback:

```bash
flutter build ipa --release \
  --export-options-plist=$HOME/export_options.plist \
  --dart-define=FLOWFIT_AUTH_SCHEME=com.oldstlabs.flowfit \
  --dart-define=FLOWFIT_SUPPORT_EMAIL=support@flowfit.com \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY
```

`flutter build ipa` produces the Xcode archive in `build/ios/archive/` and the
App Store bundle in `build/ios/ipa/` when signing is configured.

## Flutter Web Setup

Build:

```powershell
pwsh -NoProfile -File scripts/store_release_build.ps1 -Target Web
```

Set `FLOWFIT_PUBLIC_WEB_BASE_URL` to the final deployed URL before building.
Root-domain hosts can use an origin such as `https://flowfit.example.com`.
Project-site hosts can include the path, for example
`https://iron-mark.github.io/Hackathon-FlowFit`. The wrapper derives Flutter's
`--base-href` from that path, so GitHub Pages project sites load assets from
`/Hackathon-FlowFit/` instead of `/`. Override the derived value only when the
host needs it:

```powershell
$env:FLOWFIT_WEB_BASE_HREF = '/Hackathon-FlowFit/'
```

Serve the output from `build/web` on the chosen host. The current build targets
Flutter web JavaScript. Wasm compile-smoke is available through the optional
preflight flag below, but JS remains the default release target until the
maintainer intentionally chooses Wasm for the deployed web build.
The production wrapper also writes a portable static-hosting archive at
`build/release/flowfit-web-release.zip` after the compliance pages pass, and
records both the directory and the zip in `build/store-release-artifacts.json`.

Optional Wasm release artifact:

```powershell
pwsh -NoProfile -File scripts/store_release_build.ps1 -Target Web -WebWasm
```

Optional local Wasm compile-smoke without production artifact packaging:

```powershell
pwsh -NoProfile -File scripts/release_preflight.ps1 -IncludeWasmSmoke
```

The web output includes static store-compliance pages:

- `privacy.html` for the public privacy-policy URL.
- `account-deletion.html` for the public account-deletion URL.

After deployment, use `https://<your-web-host>/privacy.html` and
`https://<your-web-host>/account-deletion.html` in Play Console and App Store
Connect. The store release build wrapper replaces `support@flowfit.com` in the
built public pages with `FLOWFIT_SUPPORT_EMAIL`; keep the source default unless
the default inbox is wrong for every environment.
The release audit, preflight, and store wrapper also verify that the public
account deletion page keeps an email request link, account-and-associated-data
wording, no-reinstall wording, and the in-app
`Profile > Settings > Delete Account` path.

After the static host deploys, run the public deployment verifier:

```powershell
pwsh -NoProfile -File scripts/verify_web_deployment.ps1 `
  -BaseUrl 'https://<your-web-host>' `
  -SupportEmail 'support@flowfit.com' `
  -OutFile build/web-deployment-verification.json
```

The verifier checks the app shell, `manifest.json`, `privacy.html`, and
`account-deletion.html`, enforces HTTPS for real deployments, validates the
configured support inbox text, rejects internal maintainer/store-review terms,
and writes JSON evidence for store handoff.

### GitHub Pages Deployment

`.github/workflows/flutter-web-pages.yml` provides a concrete Flutter web
deployment path for this fork. It builds with `scripts/store_release_build.ps1
-Target Web -SkipFlutterPubGet`, uploads `build/web` to GitHub Pages, deploys
it, then runs `scripts/verify_web_deployment.ps1` against the deployed Pages
URL and uploads `flowfit-github-pages-verification` evidence.

Configure these repository variables before running it:

- `FLOWFIT_PUBLIC_WEB_BASE_URL`, defaulting in the workflow to
  `https://iron-mark.github.io/Hackathon-FlowFit` when the variable is absent.
- `SUPABASE_URL` for the release Supabase project.
- `SUPABASE_PUBLISHABLE_KEY` for the release Supabase project.
- Optional `FLOWFIT_SUPPORT_EMAIL` when the production inbox is not
  `support@flowfit.com`.

If the GitHub Pages API still returns 404 for this repository, open repository
Settings > Pages and set the Pages build/deploy source to GitHub Actions. The
workflow is safe to keep in the repo before that switch; it will publish only
after the workflow is run on `main` or manually dispatched with valid variables.

## Supabase Setup

Use `docs/SUPABASE_RECOVERY_RUNBOOK.md`.

Minimum completion criteria before release:

- New `flowfit-dev` or production Supabase project exists.
- `.mcp.json` contains the real project ref and Codex has been reloaded.
- Supabase MCP OAuth is complete.
- Canonical migration has been applied.
- Advisors have no unresolved high-risk security/performance findings.
- After migrations/advisors are complete, `.mcp.json` includes
  `read_only=true` for release verification.
- App signup/login/onboarding/workout smoke flows have been tested against the
  live project.

## Store Privacy and Account Deletion

Use `docs/PRIVACY_DATA_MAP.md` to complete Play Data safety and App Store
privacy labels. Use `docs/STORE_SUBMISSION_CHECKLIST.md` to track the public
privacy-policy URL, public account-deletion URL, in-app deletion request flow,
and store listing assets.

The in-app Delete Account screen requires the account password, then calls
`request_account_deletion()`. The canonical migration exposes that RPC as
`security invoker`, so it uses the signed-in user's RLS policies to delete
app-owned public rows and records a pending `account_deletion_requests` row.
While that request is `pending` or `processing`, RLS blocks authenticated
client inserts and updates on profile, Buddy, workout, and heart-rate tables so
another active session cannot recreate app-owned rows before admin processing.
That queue row intentionally does not cascade when the Supabase Auth user is
later deleted, so the admin processor can retain operational evidence according
to the project's retention policy. An admin process is still required to remove
the Supabase Auth user itself and mark the queue row processed. The migration
explicitly grants `service_role` `select, update` on
`account_deletion_requests` for that backend/admin processor; do not put the
service-role or secret key in the Flutter app. The app also clears known local
account data on the current device on a best-effort basis before signing out.

## Local Verification Commands

```powershell
# Non-secret external readiness audit:
pwsh -NoProfile -File scripts/release_readiness_audit.ps1

# Strict pre-release audit; expected to fail until production Supabase, read-only
# MCP posture, signing, public web URL, and support inbox decisions are in place:
pwsh -NoProfile -File scripts/release_readiness_audit.ps1 -Strict

# Strict audit with JSON evidence for release handoff:
pwsh -NoProfile -File scripts/release_readiness_audit.ps1 -Strict -SupportEmailVerified -OutFile build/store-release-readiness-audit.json

# Same strict audit using the ignored release env file:
pwsh -NoProfile -File scripts/release_readiness_audit.ps1 -Strict -EnvFile .env.release -OutFile build/store-release-readiness-audit.json

# Full local gate, including release App Bundle smoke:
pwsh -NoProfile -File scripts/release_preflight.ps1 -IncludeReleaseSmoke

# Optional Flutter web Wasm compile-smoke:
pwsh -NoProfile -File scripts/release_preflight.ps1 -IncludeWasmSmoke

# Optional Flutter web Wasm production artifact wrapper:
pwsh -NoProfile -File scripts/store_release_build.ps1 -Target Web -WebWasm

# Production artifact wrapper after external config is complete.
# Run -Target All on macOS for Android, iOS, and web. On Windows, run
# Android/Web targets separately because iOS archive/export requires Xcode.
pwsh -NoProfile -File scripts/store_release_build.ps1 -Target All -RunStrictAudit -SupportEmailVerified

# Or load production inputs from the ignored release env file:
pwsh -NoProfile -File scripts/store_release_build.ps1 -Target All -RunStrictAudit -EnvFile .env.release

# Use -SupportEmailVerified only after the configured/default support inbox is
# owned by the maintainer and can receive privacy or account deletion requests.

# Manual commands:
flutter pub get
dart analyze --format=machine
flutter analyze
flutter test --reporter compact
flutter build apk --debug --no-pub
flutter build apk --debug -t lib\main_wear.dart --no-pub
flutter build web --release --no-pub

# Requires android/key.properties, unless the smoke-only env var above is set.
flutter build appbundle --release --no-pub `
  --dart-define=FLOWFIT_AUTH_SCHEME=com.oldstlabs.flowfit `
  --dart-define=FLOWFIT_SUPPORT_EMAIL=support@flowfit.com `
  --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=$env:SUPABASE_PUBLISHABLE_KEY

# After Flutter web is deployed:
pwsh -NoProfile -File scripts/verify_web_deployment.ps1 `
  -BaseUrl $env:FLOWFIT_PUBLIC_WEB_BASE_URL `
  -SupportEmail $env:FLOWFIT_SUPPORT_EMAIL `
  -OutFile build/web-deployment-verification.json
```

The release preflight also verifies that the Flutter web output contains
`privacy.html` and `account-deletion.html`, that the two pages link to each
other, that they do not contain internal maintainer/store-review wording, and
that release source does not reintroduce hard-coded example auth redirects or a
public privileged deletion RPC. When `-IncludeReleaseSmoke` is set, the script
also compiles the release App Bundle with smoke-only package/auth values
(`com.flowfit.smoke`) and matching Dart auth-scheme defines unless the caller
has already provided production values. That artifact is compile evidence only,
not a store or runnable production artifact unless real Supabase release defines
and production IDs are supplied.
Those smoke IDs are intentionally accepted only by the preflight smoke path; the
strict audit and `store_release_build.ps1` classify them as non-production.

The preflight now runs `scripts/release_readiness_audit.ps1` in advisory mode
without creating a temporary `lib/secrets.dart`; tracked build-time defaults
keep compile checks independent from ignored local files. For store handoff,
run the audit separately with `-Strict`; it should fail until the maintainer has
provided the real Supabase project ref/credentials, Android signing inputs,
production Android/iOS IDs, deployed web origin, and verified support inbox.
When `-OutFile` is provided, the audit writes JSON evidence with pass/warn/fail
counts and non-secret result details. The production wrapper writes
`build/store-release-readiness-audit.json` automatically when `-RunStrictAudit`
is used and includes it in `build/store-release-artifacts.json` after the strict
audit passes. The artifact manifest also records each output's path, kind,
SHA-256 digest, byte size, file count, git commit/dirty state, selected
toolchain versions, non-secret release inputs, and strict-audit summary.
It fails on uncommitted changes unless `-AllowDirty` is supplied, and it runs
analyzer, Flutter tests, and Android release lint unless `-SkipValidation` is
supplied with separate fresh evidence for the same commit.

## GitHub CI

`.github/workflows/flutter-ci.yml` runs the same core gates on pull requests,
pushes to `main`, `develop`, and `supabase/**`, plus manual dispatch. The
workflow installs the required Android SDK packages, runs the advisory
release-readiness audit, builds the JS web artifact, builds Android phone/Wear
debug APKs, and produces a debug-signed release App Bundle smoke artifact named
`flowfit-release-smoke-not-for-store`. The CI release smoke uses
`com.flowfit.smoke` package/auth values plus matching Dart defines and
placeholder Supabase client Dart defines, mirroring the local preflight. It
also verifies the built public privacy and account-deletion pages, serves
`build/web` locally, runs `scripts/verify_web_deployment.ps1` with
`-AllowInsecureLocalhost`, and uploads
`flowfit-web-static-verification-smoke` before uploading the web artifact.
The CI web artifact is named `flowfit-web-smoke-not-for-store` because it uses
smoke Supabase Dart defines and is not a production web deploy artifact. This
CI check is static artifact verification; it does not execute the Flutter app
runtime because the smoke build intentionally uses placeholder Supabase values.
CI also compiles a separate Wasm smoke artifact under `build/web-wasm`, verifies
`main.dart.wasm` and the public compliance pages are present there, and uploads
it as `flowfit-web-wasm-smoke-not-for-store`. That keeps the normal JS web
artifact as the default handoff while proving the Wasm backend still compiles.
Before every Android build, CI clears Flutter's ignored
`android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`
file so a previous web/Wasm build cannot poison native Kotlin compilation.

That CI smoke App Bundle is not acceptable for Play Store upload. Store upload
still requires the real upload keystore, production package/auth values, and
matching Dart auth-scheme defines. Pass `FLOWFIT_SUPPORT_EMAIL` as a Dart
define when the production support/privacy inbox differs from the default.
For production handoff, prefer `scripts/store_release_build.ps1`; it also
writes `build/store-release-artifacts.json` for the generated AAB/web outputs,
including `build/release/flowfit-web-release.zip` for static web hosting.
The production wrapper rejects smoke/example IDs and reserved `.example`,
`.invalid`, `.test`, localhost, or IP-loopback web hosts even when signing files
are present.

CI intentionally runs the audit in advisory mode. Advisory mode defaults to
recovery MCP posture so migrations can still run. Strict mode defaults to
release MCP posture and requires maintainer-controlled inputs: real Supabase
project credentials, MCP OAuth, `read_only=true` on the project-scoped MCP URL,
upload signing, deployed web URL, and support inbox verification.

`.github/workflows/flutter-web-pages.yml` is separate from CI because it is a
deployment workflow. It requires GitHub Pages write permissions plus production
Supabase repository variables, and it verifies the deployed public web URL after
publish.

Machine-level checks:

```powershell
flutter doctor -v
flutter doctor --android-licenses
```

The current Windows machine can verify Android and web builds, but not iOS
archive/signing.
