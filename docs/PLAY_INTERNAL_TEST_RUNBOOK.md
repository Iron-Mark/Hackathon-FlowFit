# FlowFit Play Internal Testing Runbook

Last updated: 2026-08-27

Living guide for the first **Google Play internal testing** upload of
`com.msiazondev.flowfit`. Use with
[STORE_SUBMISSION_CHECKLIST.md](STORE_SUBMISSION_CHECKLIST.md),
[STORE_METADATA_DRAFT.md](STORE_METADATA_DRAFT.md), and
[RELEASE_READINESS_RUNBOOK.md](RELEASE_READINESS_RUNBOOK.md).

Historical July 2026 Play pack:
[release/PLAY_CONSOLE_SUBMISSION_PACK_2026-07-04.md](release/PLAY_CONSOLE_SUBMISSION_PACK_2026-07-04.md).

## Before you start (owner blockers)

Complete or accept these before uploading:

| Item | Status | Notes |
| --- | --- | --- |
| Upload keystore | Owner | `scripts/create_android_upload_keystore.ps1` or CI signing secrets |
| Production Supabase URL + publishable key | Owner | `--dart-define` or ignored `lib/secrets.dart` |
| Support inbox verified | Done (2026-07-03 evidence) | `marksiazon.dev@gmail.com`; see `build/support-inbox-verification.json` when present locally |
| Public privacy + deletion pages | Live | Verified 2026-08-27 against GitHub Pages |
| Supabase auth email templates in dashboard | Owner | Render locally (below), paste into Supabase Auth |
| Live `verify_flowfit_backend.sql` | Owner | MCP OAuth or SQL editor on production project |
| Families/Kids legal decision | Owner | Options memo: [FAMILIES_KIDS_OPTIONS.md](FAMILIES_KIDS_OPTIONS.md) |

## Release identity (do not change without store/console updates)

| Field | Value |
| --- | --- |
| Package ID | `com.msiazondev.flowfit` |
| Auth scheme | `com.msiazondev.flowfit` |
| Dev auth scheme | `com.msiazondev.flowfit.dev` |
| App name | FlowFit |
| Category | Health & Fitness |
| Support email | `marksiazon.dev@gmail.com` |
| Privacy policy | `https://iron-mark.github.io/Hackathon-FlowFit/privacy.html` |
| Account deletion | `https://iron-mark.github.io/Hackathon-FlowFit/account-deletion.html` |
| Supabase redirect | `com.msiazondev.flowfit://auth-callback` |

Listing copy: [STORE_METADATA_DRAFT.md](STORE_METADATA_DRAFT.md).

## 1. Render Supabase auth email templates (paste-ready)

Run on a machine with PowerShell after the support inbox is verified:

```powershell
pwsh -NoProfile -File scripts/render_supabase_email_templates.ps1 `
  -SupportEmail marksiazon.dev@gmail.com `
  -SupportEmailVerified `
  -OutDir build/supabase-email-templates-handoff
```

Outputs under `build/supabase-email-templates-handoff/`:

- `confirm_signup.html` / `.txt`
- `reset_password.html` / `.txt`
- `magic_link.html` / `.txt`
- `change_email.html` / `.txt`
- `reauthentication.html` / `.txt`
- `manifest.json` (SHA-256 per file)

Paste each HTML body into **Supabase Dashboard → Authentication → Email Templates**
(matching template name). Keep the `.txt` files with your release handoff.

## 2. Configure Android signing and package

Local file path:

```powershell
pwsh -NoProfile -File scripts/create_android_upload_keystore.ps1
```

Or refresh CI handoff without overwriting an existing keystore:

```powershell
pwsh -NoProfile -File scripts/export_android_signing_env.ps1 `
  -OutFile .env.release.android-signing.generated
```

Confirm `android/gradle.properties`:

```properties
FLOWFIT_ANDROID_APPLICATION_ID=com.msiazondev.flowfit
FLOWFIT_AUTH_SCHEME=com.msiazondev.flowfit
```

Add redirect URL in Supabase Auth settings:

```text
com.msiazondev.flowfit://auth-callback
```

## 3. Build the signed release App Bundle

Set production values (example — use your real Supabase project):

```powershell
$env:FLOWFIT_SUPPORT_EMAIL = 'marksiazon.dev@gmail.com'
$env:FLOWFIT_SUPPORT_EMAIL_VERIFIED = 'true'
$env:FLOWFIT_PUBLIC_WEB_BASE_URL = 'https://iron-mark.github.io/Hackathon-FlowFit'
$env:SUPABASE_URL = 'https://xhmkghwijqpvnbpeeckg.supabase.co'
$env:SUPABASE_PUBLISHABLE_KEY = 'REPLACE_WITH_PUBLISHABLE_KEY'

pwsh -NoProfile -File scripts/store_release_build.ps1 -Target Android -SupportEmailVerified
```

Expected AAB path: `build/app/outputs/bundle/release/app-release.aab`

Record SHA-256:

```powershell
Get-FileHash -Algorithm SHA256 build/app/outputs/bundle/release/app-release.aab
```

Optional strict gate before upload:

```powershell
pwsh -NoProfile -File scripts/release_readiness_audit.ps1 -Strict -SupportEmailVerified
```

## 4. Verify public web pages (store URLs)

```powershell
pwsh -NoProfile -File scripts/verify_web_deployment.ps1 `
  -BaseUrl 'https://iron-mark.github.io/Hackathon-FlowFit' `
  -SupportEmail 'marksiazon.dev@gmail.com' `
  -OutFile build/web-deployment-verification.json
```

This checks app shell assets, privacy page, and account-deletion page wording.

## 5. Play Console internal testing upload

1. Open Play Console → create or select app **`com.msiazondev.flowfit`**.
2. **Release → Testing → Internal testing → Create new release**.
3. Upload `app-release.aab`. Confirm version code and signing are accepted.
4. Store listing (from [STORE_METADATA_DRAFT.md](STORE_METADATA_DRAFT.md)):
   - Short + full description
   - Support email `marksiazon.dev@gmail.com`
   - Privacy policy and account deletion URLs (table above)
   - Phone screenshots; Wear screenshots only if listing declares Wear
5. **Policy → App content**:
   - Data safety from [PRIVACY_DATA_MAP.md](PRIVACY_DATA_MAP.md)
   - Content rating questionnaire
   - Target audience and content (Families decision pending)
   - Ads declaration
   - Foreground location + health/wearable disclosures as prompted
6. Add internal testing release notes (example):

```text
Initial FlowFit internal testing build for com.msiazondev.flowfit.
Parent-supervised signup; self-attested age gate. Test signup, verify email,
profile onboarding, help/support, and account deletion.
```

7. Add tester emails and publish the internal track.

## 6. Device smoke (from Play install only)

Install from the internal testing link, not sideloaded debug APK.

| Step | Pass? | Notes |
| --- | --- | --- |
| Install from Play internal track | | |
| Signup + email verification | | |
| Login / password reset | | |
| Profile + Buddy onboarding | | |
| Workout save / list / delete | | |
| Help & Support request reaches Supabase | | |
| Privacy page opens (in-app + public URL) | | |
| Delete Account flow | | |
| Package is `com.msiazondev.flowfit` | | `adb shell pm list packages \| findstr flowfit` |

## 7. Do not promote past internal testing until

- [ ] Smoke table above passes on a real device from Play
- [ ] Auth email templates are live in Supabase dashboard
- [ ] Live backend verification evidence captured
- [ ] Data safety, content rating, and target audience complete
- [ ] AAB SHA-256 recorded in release handoff matches uploaded artifact

## Related scripts

| Script | Purpose |
| --- | --- |
| `scripts/store_release_build.ps1` | Signed AAB / web release wrapper |
| `scripts/verify_web_deployment.ps1` | Public Pages compliance check |
| `scripts/render_supabase_email_templates.ps1` | Dashboard paste-ready auth emails |
| `scripts/verify_store_metadata.ps1` | Listing copy + asset guard |
| `scripts/verify_store_artifacts.ps1` | AAB/web manifest evidence |
