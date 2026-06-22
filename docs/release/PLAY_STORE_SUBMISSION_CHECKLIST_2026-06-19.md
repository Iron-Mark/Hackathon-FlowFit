# FlowFit Play Store Submission Checklist - 2026-06-19

Use this checklist after the release handoff in
`docs/release/FINAL_RELEASE_HANDOFF_2026-06-19.md`.

## Current Candidate

| Field | Value |
| --- | --- |
| Source commit | `f8321f9f29d49b9d6b0686ffb96e496ef8c37208` |
| Release workflow/checklist docs | Tracked on `main`; use `git log -1 -- docs/release .github/workflows/android-production-release.yml` for the latest docs commit |
| Android package ID | `com.msiazondev.flowfit` |
| AAB path | `build/app/outputs/bundle/release/app-release.aab` |
| AAB SHA-256 | `e62358e4f3251e540e6742ccf4380ce2e276634a8f72287fb5832849fd3b1f10` |
| Privacy URL | `https://iron-mark.github.io/Hackathon-FlowFit/privacy.html` |
| Account deletion URL | `https://iron-mark.github.io/Hackathon-FlowFit/account-deletion.html` |
| Support inbox | `marksiazon.dev@gmail.com` |

## Protected GitHub Release Workflow

The manual workflow `.github/workflows/android-production-release.yml` can
rebuild a signed Android Play Store AAB from GitHub Actions.

Configure a GitHub Environment named `play-store-release` before using it:

- [ ] Require reviewer approval.
- [ ] Limit deployment branches or tags according to the release policy.
- [ ] Store signing secrets only in that environment if possible.

Required repository or environment variables:

- [ ] `FLOWFIT_PUBLIC_WEB_BASE_URL`
- [ ] `FLOWFIT_SUPPORT_EMAIL`
- [ ] `FLOWFIT_SUPPORT_EMAIL_VERIFIED=true`
- [ ] `SUPABASE_URL`
- [ ] `SUPABASE_PUBLISHABLE_KEY`
- [ ] Optional: `FLOWFIT_ANDROID_APPLICATION_ID`
- [ ] Optional: `FLOWFIT_AUTH_SCHEME`

Required repository or environment secrets:

- [ ] `FLOWFIT_ANDROID_KEYSTORE_BASE64`
- [ ] `FLOWFIT_ANDROID_KEYSTORE_PASSWORD`
- [ ] `FLOWFIT_ANDROID_KEY_ALIAS`
- [ ] `FLOWFIT_ANDROID_KEY_PASSWORD`

Manual workflow input:

- [ ] `support_inbox_evidence_note`, for example
      `Received external support/account-deletion test email on 2026-06-18`.

Expected workflow artifact:

- [ ] `flowfit-android-play-store-release-<commit-sha>`

That artifact contains the AAB, strict audit JSON, artifact verification JSON,
support inbox evidence, release manifest, and rendered Supabase email templates.

## Play Console Setup

- [ ] Create or open the Play Console app.
- [ ] Confirm package name `com.msiazondev.flowfit`.
- [ ] Set app name: `FlowFit`.
- [ ] Set default language.
- [ ] Add category: Health & Fitness.
- [ ] Confirm ads declaration.
- [ ] Complete content rating questionnaire.
- [ ] Complete target audience and content settings.
- [ ] Add privacy policy URL.
- [ ] Add account deletion URL.
- [ ] Complete Data safety from `docs/PRIVACY_DATA_MAP.md`.
- [ ] Add foreground location disclosure if Play requests it.
- [ ] Add health/heart-rate wording only for supported device flows.

## Store Listing Copy

Short description:

```text
Track workouts, wellness goals, heart-rate trends, and Buddy progress.
```

Full description:

```text
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
```

Internal testing release notes:

```text
Initial FlowFit internal testing build.

- Adds account signup and login with Supabase-backed profiles.
- Adds profile onboarding for goals, units, and fitness preferences.
- Adds Buddy companion setup and progress surfaces.
- Adds workout and wellness tracking screens.
- Adds Wear OS phone/watch build support and sensor-oriented flows.
- Adds public privacy and account deletion pages for store review.
- Adds in-app account deletion request flow from Profile > Settings.
```

## Store Assets

- [ ] App icon uploaded.
- [ ] Feature graphic uploaded.
- [ ] Phone screenshots uploaded.
- [ ] Wear OS screenshots uploaded if listing includes Wear OS.
- [ ] Public privacy page screenshot archived.
- [ ] Public account deletion page screenshot archived.
- [ ] No screenshot shows debug labels, private data, old Supabase project refs,
      local URLs, or placeholder credentials.

## Internal Testing QA Result Template

Fill this section only after the AAB is installed from Play Console internal
testing.

| Field | Result |
| --- | --- |
| Tester | Pending |
| Device model | Pending |
| Android version | Pending |
| Install source | Play Console internal testing |
| AAB SHA-256 | `e62358e4f3251e540e6742ccf4380ce2e276634a8f72287fb5832849fd3b1f10` |
| Test account | Stored outside repo |
| Signup and email verification | Pending |
| Profile onboarding | Pending |
| Buddy onboarding | Pending |
| Workout save/list | Pending |
| Privacy page opens | Pending |
| Account deletion request | Pending |
| Supabase row verification | Pending |
| Notes | Pending |

## Final Release Gate

Do not promote beyond internal testing until:

- [ ] Internal testing smoke passes on a real Android device.
- [ ] Supabase advisors and DB lint are run against the intended project.
- [ ] Supabase Auth email templates are copied to the dashboard.
- [ ] Supabase redirect URLs include Android and web production URLs.
- [ ] Play Console accepts the AAB signature and package ID.
- [ ] Store listing, Data safety, privacy, account deletion, content rating, and
      target audience sections are complete.
