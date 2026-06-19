# FlowFit Final Release Handoff - 2026-06-19

This handoff captures the current Android Play Store candidate and the release
evidence generated from the maintained fork.

## Source Commit

| Field | Value |
| --- | --- |
| Repository | `Iron-Mark/Hackathon-FlowFit` |
| Branch | `main` |
| Commit | `f8321f9f29d49b9d6b0686ffb96e496ef8c37208` |
| Commit subject | `chore(release): clean docs and release handoff` |
| Working tree at artifact build | Clean |

Remote verification:

- `HEAD` matched `origin/main` at `f8321f9f29d49b9d6b0686ffb96e496ef8c37208`.
- `gh run list` showed both release-related workflows passing on the same
  commit.

## Release Inputs

Non-secret release inputs recorded in `build/store-release-artifacts.json`:

| Input | Value |
| --- | --- |
| Target | Android |
| Support email | `marksiazon.dev@gmail.com` |
| Public web base URL | `https://iron-mark.github.io/Hackathon-FlowFit` |
| Android package ID | `com.oldstlabs.flowfit` |
| Android auth scheme | `com.oldstlabs.flowfit` |
| iOS bundle ID | `com.oldstlabs.flowfit` |
| Supabase client source | Local ignored `lib/secrets.dart` fallback or release env |

Do not paste or commit Supabase publishable keys, DB passwords, service-role
keys, Android signing passwords, or Apple signing assets.

## Artifact Evidence

| Artifact | Path | Size | SHA-256 |
| --- | --- | ---: | --- |
| Android Play Store AAB | `build/app/outputs/bundle/release/app-release.aab` | 113,820,977 bytes | `e62358e4f3251e540e6742ccf4380ce2e276634a8f72287fb5832849fd3b1f10` |
| Release artifact manifest | `build/store-release-artifacts.json` | 2,331 bytes | `42f846abe444d3af0207eb3cd64126bfde662c8bce0babe140dc1ce1a44ad745` |
| Strict release audit evidence | `build/store-release-readiness-audit.json` | 12,895 bytes | `1d3ae9c5cd87e71136bcff391e1e7a7bdce69731a9a49859ca26e549e784ce76` |
| Current-commit artifact verification | `build/store-release-artifact-verification-current.json` | 2,093 bytes | `1c4f1fd5ac9322ea6408c9feaa078d9cbc57fd48be4237ccf82e9f300c54984f` |

The AAB was built by:

```powershell
$env:FLOWFIT_SUPPORT_EMAIL='marksiazon.dev@gmail.com'
$env:FLOWFIT_PUBLIC_WEB_BASE_URL='https://iron-mark.github.io/Hackathon-FlowFit'
$env:ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID='com.oldstlabs.flowfit'
$env:ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME='com.oldstlabs.flowfit'
pwsh -NoProfile -File scripts\store_release_build.ps1 `
  -Target Android `
  -RunStrictAudit `
  -SupportEmailVerified `
  -SkipFlutterPubGet
```

Final artifact verifier command:

```powershell
pwsh -NoProfile -File scripts\verify_store_artifacts.ps1 `
  -ManifestPath build\store-release-artifacts.json `
  -OutFile build\store-release-artifact-verification-current.json `
  -Strict `
  -RequireArtifact android-play-store-aab `
  -RequireStrictAudit `
  -RequireCurrentCommit
```

Verifier result: `12 pass, 0 warn, 0 fail`.

## Verification Summary

Local verification for the current release candidate:

- `flutter analyze`: passed, no issues.
- `flutter test --reporter compact`: passed, 840 tests passed and 1 skipped.
- `scripts/store_release_build.ps1 -Target Android -RunStrictAudit`: passed.
- Strict release audit inside the wrapper: `69 pass, 1 warn, 0 fail`.
- Android release lint inside the wrapper: passed.
- Android Play Store AAB build: passed.
- `scripts/verify_store_artifacts.ps1 -Strict -RequireCurrentCommit`: passed.

Remote CI verification:

| Workflow | Result | Commit | Run |
| --- | --- | --- | --- |
| Flutter CI | Success | `f8321f9f29d49b9d6b0686ffb96e496ef8c37208` | <https://github.com/Iron-Mark/Hackathon-FlowFit/actions/runs/27812413453> |
| Flutter Web Pages | Success | `f8321f9f29d49b9d6b0686ffb96e496ef8c37208` | <https://github.com/Iron-Mark/Hackathon-FlowFit/actions/runs/27812413448> |

## Google Play Store Steps

1. Open Google Play Console and create or open the FlowFit app.
2. Confirm the package name is `com.oldstlabs.flowfit`.
3. Upload `build/app/outputs/bundle/release/app-release.aab` to internal
   testing first.
4. Confirm Play Console accepts the upload key and package ID.
5. Add the privacy policy URL:
   `https://iron-mark.github.io/Hackathon-FlowFit/privacy.html`.
6. Add the account deletion URL:
   `https://iron-mark.github.io/Hackathon-FlowFit/account-deletion.html`.
7. Complete Data safety using `docs/PRIVACY_DATA_MAP.md`.
8. Complete content rating, target audience, ads declaration, and health or
   foreground-location disclosures.
9. Use release notes from
   `docs/release/PLAY_STORE_RELEASE_NOTES_AND_QA_2026-06-19.md`.
10. Install the internal testing build on a real Android device and run the
    smoke checklist in the QA evidence doc.
11. Promote only after the real-device smoke passes against the intended
    Supabase project.

## Supabase Store Checklist

Before public rollout:

- Confirm the canonical migration has been applied to the intended release
  Supabase project.
- Apply the rendered email template from
  `build/supabase-email-templates/confirm_signup.html` to Supabase Auth.
- Keep `build/supabase-email-templates/confirm_signup.txt` with the release
  evidence.
- Confirm redirect URLs include:
  - `com.oldstlabs.flowfit://auth-callback`
  - `com.oldstlabs.flowfit.dev://auth-callback`
  - `https://iron-mark.github.io/Hackathon-FlowFit`
- Run Supabase advisors and DB lint after `SUPABASE_DB_PASSWORD` and
  Supabase CLI auth are available locally.
- Keep MCP in release read-only posture after migrations and advisor fixes.

## Known Remaining Blockers

- `SUPABASE_DB_PASSWORD` and `SUPABASE_ACCESS_TOKEN` were not present in the
  local process, so Supabase advisor and DB lint could not be run in this
  pass.
- Docker CLI is unavailable on this machine, so local Docker-backed Supabase
  validation remains skipped.
- iOS IPA generation requires macOS, Xcode, signing certificates, and
  provisioning profiles.
- Final Play Console submission still requires real-device internal testing
  after the AAB is uploaded.
