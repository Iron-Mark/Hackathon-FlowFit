# FlowFit Store Submission Checklist

Last updated: 2026-06-15

This checklist tracks store-facing readiness for Google Play, App Store, and
Flutter web. Use it with `docs/RELEASE_READINESS_RUNBOOK.md` and
`docs/STORE_METADATA_DRAFT.md`.

## Shared Before Any Store Submission

- [ ] Production Supabase project exists and canonical migration is applied.
- [ ] `.mcp.json` has `REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF` replaced with
      the development/staging release-verification project ref; Codex has
      been restarted/reloaded, Supabase MCP OAuth is complete, the MCP URL has
      `read_only=true` after migrations/advisors are done, and
      `pwsh -NoProfile -File scripts/release_readiness_audit.ps1 -Strict`
      no longer reports the MCP project-scope or release read-only blockers.
      Prefer the helper instead of hand-editing:
      `pwsh -NoProfile -File scripts/configure_supabase_mcp.ps1 -ProjectRef '<project-ref>' -ReleaseReadOnly`.
      If production verification through MCP is unavoidable, use temporary
      owner-approved read-only MCP access only, avoid user-data queries, and
      remove `.mcp.json` after capturing release evidence.
- [ ] Supabase advisors have no unresolved high-risk security/performance
      findings.
- [ ] `scripts/verify_supabase_backend.ps1 -Linked` or the equivalent MCP
      `execute_sql` run of `supabase/verification/verify_flowfit_backend.sql`
      returns only passing backend verification rows.
- [ ] Production Supabase client values are supplied through `SUPABASE_URL` and
      `SUPABASE_PUBLISHABLE_KEY`, either from the process environment, ignored
      `.env.release`, or ignored local fallback `lib/secrets.dart`.
- [ ] Flutter release commands pass the production auth scheme with
      `--dart-define=FLOWFIT_AUTH_SCHEME=...`.
- [ ] Production wrapper builds set `FLOWFIT_SUPPORT_EMAIL` to the final
      deliverable support/privacy inbox; manual Flutter release commands pass
      the same value with `--dart-define=FLOWFIT_SUPPORT_EMAIL=...`.
- [ ] Strict audit rejects local smoke/example values; do not use
      `com.flowfit.smoke`, `com.example.*`, `com.yourcompany.*`, `.example`,
      `.invalid`, `.test`, localhost, or IP-loopback web hosts for production
      artifacts.
- [ ] Public privacy-policy URL is live, accessible without login, not a PDF,
      and matches `docs/PRIVACY_DATA_MAP.md`. After deploying Flutter web, use
      `https://<your-web-host>/privacy.html`.
- [ ] Public account-deletion URL is live and lets users initiate deletion
      without reinstalling the app. After deploying Flutter web, use
      `https://<your-web-host>/account-deletion.html`.
- [ ] In-app Privacy Policy, Terms, and Delete Account screens have final
      maintainer/legal-reviewed copy.
- [ ] The source default `support@flowfit.com` has been replaced by a verified
      production support/privacy inbox in public pages and in-app copy. Run
      `pwsh -NoProfile -File scripts/verify_support_inbox.ps1`, then rerun with
      `-ConfirmedInbound` and `-EvidenceNote` after receiving an external test
      email. If DNS reports Null MX, configure a deliverable mailbox/MX host or
      choose a different support address before store submission.
- [ ] Location disclosures describe foreground-only wellness routes, walking
      paths, and geofence missions; release manifests must not request
      background location until native background geofencing is implemented.
- [ ] Debug-only routes/screens are hidden or removed from production builds.
- [ ] Legacy debug aliases such as `/trackertest` are not reachable from
      production UI; use production route names such as `/activity-classifier`.
- [ ] Real device smoke covers signup, login, profile onboarding, Buddy
      onboarding, workout creation, account deletion request, and signout.

## Google Play

- [ ] Accept Android SDK licenses locally: `flutter doctor --android-licenses`.
- [ ] Create maintainer-owned package ID and set it in
      `android/gradle.properties`.
- [ ] Confirm signed release builds fail if `FLOWFIT_ANDROID_APPLICATION_ID`,
      `FLOWFIT_AUTH_SCHEME`, or matching Dart defines are still placeholders,
      examples, or smoke values.
- [ ] If `FLOWFIT_ANDROID_APPLICATION_ID` differs from
      `com.oldstlabs.flowfit`, confirm the release wrapper still passes Android
      manifest component checks; native component class names must stay fully
      qualified under `com.oldstlabs.flowfit`.
- [ ] Generate upload keystore and configure either ignored
      `android/key.properties` plus the referenced keystore, or CI/release env
      secrets `FLOWFIT_ANDROID_KEYSTORE_BASE64`,
      `FLOWFIT_ANDROID_KEYSTORE_PASSWORD`, `FLOWFIT_ANDROID_KEY_ALIAS`, and
      `FLOWFIT_ANDROID_KEY_PASSWORD`. For a new local upload key, run
      `pwsh -NoProfile -File scripts/create_android_upload_keystore.ps1` and
      back up the ignored generated files privately before uploading an AAB.
      If the CI handoff file must be refreshed from an existing keystore, run
      `pwsh -NoProfile -File scripts/export_android_signing_env.ps1 -OutFile .env.release.android-signing.generated`
      and use the newest matching ignored handoff file.
- [ ] Add production auth schemes to Supabase redirect URLs.
- [ ] Build upload artifact:
      `pwsh -NoProfile -File scripts/store_release_build.ps1 -Target Android`.
- [ ] Complete App content:
  - [ ] Privacy Policy URL.
  - [ ] Data safety form from `docs/PRIVACY_DATA_MAP.md`.
  - [ ] Account deletion URL.
  - [ ] Health and foreground-location permission disclosures.
  - [ ] Content rating questionnaire.
  - [ ] Target audience and ads declaration.
- [ ] Upload screenshots, feature graphic, app icon, short description, and
      full description.
- [ ] Review and finalize listing copy from `docs/STORE_METADATA_DRAFT.md`.
- [ ] Run `pwsh -NoProfile -File scripts/verify_store_metadata.ps1 -Strict`
      with the final web base URL/support inbox and archive
      `build/store-metadata-verification.json`.
- [ ] Validate that the uploaded AAB is signed with the upload key, not the
      debug release-smoke key.

## App Store / TestFlight

- [ ] Run on macOS with Xcode and CocoaPods available.
- [ ] Set `FLOWFIT_IOS_BUNDLE_IDENTIFIER` in `ios/Flutter/FlowFit.xcconfig`.
- [ ] Set `FLOWFIT_SUPPORT_EMAIL` and optional
      `FLOWFIT_IOS_EXPORT_OPTIONS_PLIST` on the macOS build host.
      If Xcode export needs explicit options, create ignored
      `ios/ExportOptions.plist` with
      `pwsh -NoProfile -File scripts/create_ios_export_options.ps1 -TeamId <TEAMID> -ProvisioningProfileName '<profile name>'`.
- [ ] Add production auth schemes to Supabase redirect URLs.
- [ ] Assign Apple Developer team and signing profiles in Xcode.
- [ ] Confirm `ios/Runner/PrivacyInfo.xcprivacy` is included in the Runner
      target resources and matches `docs/PRIVACY_DATA_MAP.md`.
- [ ] Build signed archive/IPA:
      `pwsh -NoProfile -File scripts/store_release_build.ps1 -Target iOS`.
- [ ] Confirm `build/store-release-artifacts.json` includes
      `ios-app-store-ipa`.
- [ ] Archive `build/store-release-artifacts.json` with each store/web handoff;
      confirm artifact SHA-256, byte size, git commit, strict-audit summary,
      and non-secret release inputs match the uploaded package.
- [ ] Confirm the production wrapper ran from a clean git tree without
      `-AllowDirty`, or document the emergency override in the release notes.
- [ ] Confirm analyzer, Flutter tests, and Android release lint ran through the
      production wrapper without `-SkipValidation`, or attach separate fresh
      evidence for the same commit.
- [ ] Complete App Store Connect app privacy answers from
      `docs/PRIVACY_DATA_MAP.md`.
- [ ] Generate Privacy Report from the Xcode archive and reconcile the app
      manifest plus third-party SDK manifests with App Store Connect app
      privacy answers before upload.
- [ ] Add privacy policy URL.
- [ ] Confirm in-app account deletion request flow is discoverable and works.
- [ ] Review health, location, motion, camera, photo, and account-data
      permission purposes.
- [ ] Upload screenshots, app preview assets if any, app icon, subtitle,
      promotional text, description, keywords, support URL, and marketing URL.
- [ ] Review and finalize App Review notes from
      `docs/STORE_METADATA_DRAFT.md`.
- [ ] Confirm `build/store-metadata-verification.json` has no failures after
      final metadata, icon assets, support inbox, and public web URLs are set.

## Flutter Web

- [ ] Build JS release:
      `pwsh -NoProfile -File scripts/store_release_build.ps1 -Target Web`.
- [ ] If Wasm is part of the web release plan, build with:
      `pwsh -NoProfile -File scripts/store_release_build.ps1 -Target Web -WebWasm`.
- [ ] Deploy `build/web` to chosen host, or upload
      `build/release/flowfit-web-release.zip` to a static host that unpacks ZIP
      deploy artifacts.
- [ ] For GitHub Pages, configure repository variables `FLOWFIT_PUBLIC_WEB_BASE_URL`,
      `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, and
      `FLOWFIT_SUPPORT_EMAIL`; set `FLOWFIT_SUPPORT_EMAIL_VERIFIED=true` only
      after the configured inbox is receiving external mail, then run
      `.github/workflows/flutter-web-pages.yml`.
      Prefer `scripts/configure_github_release_variables.ps1 -DryRun` before
      setting them so placeholders and secret/service-role keys are rejected.
      Use `https://iron-mark.github.io/Hackathon-FlowFit` as the default project
      site unless a custom domain is configured.
      Until those variables are complete, the Pages workflow's `deploy-ready`
      job skips deployment instead of failing the merge-to-main workflow.
- [ ] If web release values are stored as repository variables, run
      `pwsh -NoProfile -File scripts/release_readiness_audit.ps1 -Strict -GitHubRepo Iron-Mark/Hackathon-FlowFit`
      before dispatching the Pages workflow so the same configured values are
      checked by the release audit.
- [ ] If the web host serves from a subpath, confirm the wrapper-derived
      Flutter base href matches the path, or set `FLOWFIT_WEB_BASE_HREF` before
      building.
- [ ] Confirm `build/store-release-artifacts.json` includes
      `flutter-web-build` and `flutter-web-release-zip` with SHA-256 evidence.
- [ ] Confirm `build/store-release-artifacts.json` records
      `releaseInputs.webBuildBackend` as `javascript` or `wasm`, matching the
      deployed web artifact.
- [ ] Confirm `/privacy.html` and `/account-deletion.html` load on the deployed
      origin.
- [ ] Run `scripts/verify_web_deployment.ps1` against the deployed HTTPS
      origin and archive `build/web-deployment-verification.json`.
- [ ] Configure production Supabase redirect URLs for the web origin.
- [ ] Smoke signup/login/onboarding/workout flow on deployed URL.
- [ ] Decide whether JS or Wasm is the release target. Current repo is JS-ready
      by default, and Wasm compile-smoke passes locally after the dependency
      updates.
- [ ] Archive `build/store-metadata-verification.json` with web/store handoff
      evidence so listing text, icon dimensions, and public URLs match the
      deployed release.

## Current Local Gate

```powershell
pwsh -NoProfile -File scripts/release_readiness_audit.ps1
pwsh -NoProfile -File scripts/release_readiness_audit.ps1 -Strict
pwsh -NoProfile -File scripts/release_preflight.ps1 -IncludeWasmSmoke
pwsh -NoProfile -File scripts/release_preflight.ps1 -IncludeReleaseSmoke
pwsh -NoProfile -File scripts/store_release_build.ps1 -Target Web -WebWasm
```

The release-smoke App Bundle generated by this command is not a store upload
artifact.

The strict audit is expected to fail until production Supabase credentials,
MCP project scope, MCP release read-only posture, Android upload signing,
production package/bundle IDs, the public web deployment URL, and support inbox
verification are complete.
