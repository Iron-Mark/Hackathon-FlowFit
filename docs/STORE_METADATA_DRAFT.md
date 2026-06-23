# FlowFit Store Metadata Draft

Last updated: 2026-06-15

This is a release handoff pack for Google Play, App Store, and Flutter web
release work. Final store upload still depends on the production Supabase
project, package/bundle ownership, and a verified support inbox.

## Release Identity

| Field | Draft value | Status |
| --- | --- | --- |
| App name | FlowFit | Ready for review |
| Short tagline | Fitness tracking with a wellness companion | Ready for review |
| Android package ID | `com.msiazondev.flowfit` | Store account confirmation required |
| iOS bundle ID | `com.msiazondev.flowfit` | Apple Developer confirmation required |
| Production auth scheme | `com.msiazondev.flowfit` | Add to Supabase redirect URLs |
| Dev auth scheme | `com.msiazondev.flowfit.dev` | Add to Supabase redirect URLs |
| Support email | `marksiazon.dev@gmail.com` | Verified maintainer support inbox; keep `FLOWFIT_SUPPORT_EMAIL` aligned for release builds |
| Privacy policy URL | `https://iron-mark.github.io/Hackathon-FlowFit/privacy.html` | GitHub Pages release origin |
| Account deletion URL | `https://iron-mark.github.io/Hackathon-FlowFit/account-deletion.html` | GitHub Pages release origin |

## Short Description

Track workouts, wellness goals, heart-rate trends, and Buddy progress.

## Full Description

FlowFit combines workout tracking, wellness goals, and companion-style progress
into one fitness app. Create a profile, set daily goals, complete onboarding,
customize your Buddy companion, and track sessions such as walking, running,
and activity-focused routines.

For supported Wear OS and Samsung Health Sensor API devices, FlowFit can show
heart-rate information and watch-to-phone sensor updates after you grant the
required permissions. Location, notification, camera, and photo features are
used only for the features you choose to enable.

FlowFit includes account controls, an in-app privacy policy, and an account
deletion request flow. Public privacy and account-deletion pages are included
with the Flutter web build for store review, account deletion access, and user
access.

## App Review Notes

- Test account: create in the production Supabase project before final upload
  and store the credentials outside the repo.
- Supabase auth: Email provider must be enabled. For store review, email
  confirmation should be configured according to the reviewer test account
  instructions.
- Account deletion: open Profile > Settings > Delete Account and confirm the
  request. The app clears app-owned public records through
  `request_account_deletion()` and records a pending admin queue row for
  Supabase Auth user deletion.
- Health data: heart-rate features require supported hardware and permissions.
- Location data: release builds use foreground location for wellness missions,
  calming route suggestions, and route/path progress while the app is open. Do
  not claim background location or background geofence progress until native
  background registration is implemented.
- Debug routes: release builds hide the current debug/demo routes.

## Screenshot Shot List

Use current production assets and real device frames. Avoid showing placeholder
credentials, debug labels, staging project refs, or private user data.

### Phone

1. Auth or welcome screen with FlowFit branding.
2. Profile onboarding with fitness goals.
3. Buddy onboarding/customization.
4. Dashboard or progress overview.
5. Workout tracking/session screen.
6. Privacy or account deletion flow if the store requires account-control proof.

### Wear OS

1. Watch home/tracking screen.
2. Heart-rate or sensor status screen on supported device.
3. Workout session view.

### Flutter Web

1. Deployed public privacy page.
2. Deployed public account-deletion page.
3. Optional web app shell if web is submitted as a user-facing target.

## Review Evidence Checklist

- [ ] `pwsh -NoProfile -File scripts\release_readiness_audit.ps1 -Strict`
      passes with production values.
- [ ] `pwsh -NoProfile -File scripts\release_preflight.ps1 -IncludeReleaseSmoke`
      passes locally.
- [ ] If using Flutter WebAssembly, `pwsh -NoProfile -File scripts\release_preflight.ps1 -IncludeWasmSmoke`
      passes locally.
- [ ] If deploying Flutter WebAssembly, `pwsh -NoProfile -File scripts\store_release_build.ps1 -Target Web -WebWasm -SupportEmailVerified`
      records `releaseInputs.webBuildBackend = wasm` in the artifact manifest.
- [ ] On macOS, `pwsh -NoProfile -File scripts\store_release_build.ps1 -Target All -RunStrictAudit -SupportEmailVerified`
      produces `build/store-release-artifacts.json` with Android, iOS, and web
      artifacts.
- [ ] Web handoff includes `build/release/flowfit-web-release.zip` plus the
      `flutter-web-release-zip` manifest entry.
- [ ] `build/store-release-readiness-audit.json` is archived with the store
      handoff evidence after strict audit passes.
- [ ] `build/store-metadata-verification.json` is archived after
      `scripts/verify_store_metadata.ps1 -Strict -GitHubRepo Iron-Mark/Hackathon-FlowFit`
      passes with final public web URLs and support inbox values.
- [ ] `build/store-release-artifacts.json` is archived with artifact paths,
      SHA-256 hashes, byte sizes, git/toolchain metadata, and release inputs.
- [ ] `build/store-release-artifact-verification.json` is archived after
      `scripts/verify_store_artifacts.ps1` re-hashes the generated AAB, IPA, or
      web release artifacts for the same commit.
- [ ] On Windows, Android and web targets pass separately; iOS IPA generation is
      deferred to the macOS/Xcode build host.
- [ ] GitHub CI passes on the release branch.
- [x] Supabase advisors have no unresolved high-risk findings.
      Evidence from 2026-06-23: `build/supabase-db-lint-advisors-current.json`.
- [ ] Supabase redirect URLs include Android, iOS, and web production origins.
- [x] Public `privacy.html` loads from the deployed HTTPS origin.
- [x] Public `account-deletion.html` loads from the deployed HTTPS origin.
- [x] `build/web-deployment-verification.json` shows the deployed web base URL,
      public compliance pages, support inbox, and manifest all pass.
      Evidence from 2026-06-23: `build/web-deployment-verification.json`.
- [ ] Android AAB is signed with the upload key, not debug signing.
- [ ] iOS archive/IPA is signed with the Apple Developer team and provisioning
      profile, and the manifest includes `ios-app-store-ipa`.
- [ ] Real device smoke covers signup, login, onboarding, Buddy setup, workout
      creation, and account deletion request.

## Release Notes Draft

Initial FlowFit release:

- Fitness profile and goal onboarding.
- Buddy companion setup and customization.
- Workout and wellness tracking surfaces.
- Wear OS watch-to-phone sensor integration.
- Public privacy and account deletion pages.
- In-app account deletion request flow.
