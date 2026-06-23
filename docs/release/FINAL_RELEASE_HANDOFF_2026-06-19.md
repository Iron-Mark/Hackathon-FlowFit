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
| Android package ID | `com.msiazondev.flowfit` |
| Android auth scheme | `com.msiazondev.flowfit` |
| iOS bundle ID | `com.msiazondev.flowfit` |
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
$env:ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID='com.msiazondev.flowfit'
$env:ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME='com.msiazondev.flowfit'
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
| Flutter CI for the AAB artifact commit | Success | `f8321f9f29d49b9d6b0686ffb96e496ef8c37208` | <https://github.com/Iron-Mark/Hackathon-FlowFit/actions/runs/27812413453> |
| Flutter Web Pages for the latest web-relevant commit | Success | `f8321f9f29d49b9d6b0686ffb96e496ef8c37208` | <https://github.com/Iron-Mark/Hackathon-FlowFit/actions/runs/27812413448> |
| Flutter CI for the protected-release-workflow docs commit | Success | `a28f5c507f5b6c73928902e0d527f602a52ef877` | <https://github.com/Iron-Mark/Hackathon-FlowFit/actions/runs/27815624424> |

Current app-health refresh:

- See `docs/release/APP_HEALTH_VERIFICATION_REFRESH_2026-06-24.md` for the
  latest maintained-fork verification on commit
  `ad0cd01f6935244b2382f1bd7b0e5875671f0c15`.
- The 2026-06-24 refresh includes live Supabase backend verification, Supabase
  DB lint/advisors, live Supabase app smoke, live deployed web checks, Android
  phone emulator smoke, Android live-auth emulator smoke, Wear emulator smoke,
  and successful remote Flutter CI/Web Pages runs for the current branch.

## Google Play Store Steps

1. Open Google Play Console and create or open the FlowFit app.
2. Confirm the package name is `com.msiazondev.flowfit`.
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

For a fresh signed AAB from CI, use the protected manual workflow
`.github/workflows/android-production-release.yml`. Configure the
`play-store-release` environment with reviewer approval, release variables, and
Android signing secrets first. The workflow uploads an artifact named
`flowfit-android-play-store-release-<commit-sha>` containing the AAB, release
manifest, strict audit evidence, artifact verification evidence, support inbox
evidence, and rendered Supabase email templates.

## Supabase Store Checklist

Before public rollout:

- Confirm the canonical migration has been applied to the intended release
  Supabase project.
- Apply the rendered email template from
  `build/supabase-email-templates/confirm_signup.html` to Supabase Auth.
- Keep `build/supabase-email-templates/confirm_signup.txt` with the release
  evidence.
- Confirm redirect URLs include:
  - `com.msiazondev.flowfit://auth-callback`
  - `com.msiazondev.flowfit.dev://auth-callback`
  - `https://iron-mark.github.io/Hackathon-FlowFit`
- Run Supabase advisors and DB lint after `SUPABASE_DB_PASSWORD` and
  Supabase CLI auth are available locally.
- Keep MCP in release read-only posture after migrations and advisor fixes.

### Supabase DB Evidence Refresh - 2026-06-22

The local DB password is stored only in ignored `.env` as
`SUPABASE_DB_PASSWORD`. The file is ignored by `.gitignore`; do not commit or
paste the value.

The direct linked DB hostname was unreliable from this Windows environment, so
the successful release-verification path used the Supabase pooler host for the
project:

| Field | Value |
| --- | --- |
| Project ref | `xhmkghwijqpvnbpeeckg` |
| Project URL | `https://xhmkghwijqpvnbpeeckg.supabase.co` |
| Pooler host | `aws-1-ap-southeast-1.pooler.supabase.com` |
| Pooler port | `5432` |
| Pooler user | `postgres.xhmkghwijqpvnbpeeckg` |
| SSL mode | `require` |

Successful commands, with the password percent-encoded locally and redacted from
logs:

```powershell
$projectRef = 'xhmkghwijqpvnbpeeckg'
$poolerHost = 'aws-1-ap-southeast-1.pooler.supabase.com'
$dbPassword = (Get-Content -Raw .env |
  Select-String -Pattern '(?m)^\s*SUPABASE_DB_PASSWORD\s*=\s*(.+?)\s*$').Matches[0].Groups[1].Value.Trim().Trim('"').Trim("'")
$dbUrl = "postgresql://postgres.${projectRef}:$([uri]::EscapeDataString($dbPassword))@${poolerHost}:5432/postgres?sslmode=require"

npx -y supabase@latest db lint `
  --db-url $dbUrl `
  --schema public `
  --level warning `
  --fail-on error `
  --output-format json

npx -y supabase@latest db advisors `
  --db-url $dbUrl `
  --type all `
  --level warn `
  --fail-on warn `
  --output-format json
```

Result:

- `supabase db lint`: passed, no schema errors.
- `supabase db advisors`: completed with 2 Auth security warnings and 0 error
  findings:
  - `auth_leaked_password_protection`: enable leaked-password protection if the
    Supabase plan supports it.
  - `auth_insufficient_mfa_options`: enable/offer additional MFA options if the
    Supabase plan and product policy allow it.
- `scripts/verify_supabase_backend.ps1 -Linked -Output json`: passed all 19
  backend checks.
- Strict release audit rerun:
  `69 pass, 1 warn, 0 fail`. The only remaining warning is Docker CLI
  availability on this Windows machine.
- Non-secret evidence file:
  `build/supabase-db-lint-advisors-current.json`.

## Known Remaining Blockers

- Supabase DB lint/advisors are no longer blocked locally. They passed through
  the project pooler host using ignored `.env:SUPABASE_DB_PASSWORD`.
- The 2026-06-24 refresh reran Supabase advisors with `--fail-on warn` and
  reported no issues found.
- Docker CLI is unavailable on this machine, so local Docker-backed Supabase
  validation remains skipped.
- iOS IPA generation requires macOS, Xcode, signing certificates, and
  provisioning profiles.
- Final Play Console submission still requires real-device internal testing
  after the AAB is uploaded.
