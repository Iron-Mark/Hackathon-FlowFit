# FlowFit Play Console Submission Pack - 2026-07-04

Use this pack for the first Google Play internal testing upload of the current
MVP candidate.

## Candidate

| Field | Value |
| --- | --- |
| Source commit | `25feb1175f7b18947cfa778eff2893238fbf174b` |
| AAB path | `build/app/outputs/bundle/release/app-release.aab` |
| AAB size | 115,238,170 bytes |
| AAB SHA-256 | `50c00b66247c04f7b86bf27091e94443f2e9ec85bc0b88eaf4833a35c7f6765b` |
| Android package ID | `com.msiazondev.flowfit` |
| App name | FlowFit |
| Category | Health & Fitness |
| Support email | `marksiazon.dev@gmail.com` |
| Privacy policy URL | `https://iron-mark.github.io/Hackathon-FlowFit/privacy.html` |
| Account deletion URL | `https://iron-mark.github.io/Hackathon-FlowFit/account-deletion.html` |

## Listing Copy

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
- Adds in-app support and account deletion request flows.
```

## App Review Notes

```text
FlowFit uses Supabase for authentication and app data sync. Test reviewers can
create an account with email/password unless a dedicated review account is
provided in Play Console notes.

Account deletion is available in Profile > Settings > Delete Account. The app
clears app-owned public records through the backend deletion flow and records a
pending request for admin-side Supabase Auth deletion.

Help & Support is app-owned: authenticated users can submit support and bug
requests in Profile > Settings > Help & Support. The public support inbox is
marksiazon.dev@gmail.com and external inbound receipt has been verified.

Heart-rate and watch-to-phone features require supported Wear OS/Samsung Health
Sensor API hardware and user-granted permissions. Location is foreground-only
for wellness routes and workout context; the app does not request background
location.
```

## Play Console Data Entry Checklist

- [ ] Create or open the Play Console app for package `com.msiazondev.flowfit`.
- [ ] Upload `build/app/outputs/bundle/release/app-release.aab` to internal
      testing.
- [ ] Confirm Play Console accepts the upload key, package ID, version code, and
      signing lineage.
- [ ] Set app name to `FlowFit`.
- [ ] Set category to Health & Fitness.
- [ ] Add support email `marksiazon.dev@gmail.com`.
- [ ] Add privacy policy URL.
- [ ] Add account deletion URL.
- [ ] Complete Data safety from `docs/PRIVACY_DATA_MAP.md`.
- [ ] Complete content rating.
- [ ] Complete target audience and content settings.
- [ ] Complete ads declaration.
- [ ] Add foreground-location and health/wearable disclosures if Play requests
      them.
- [ ] Upload phone screenshots.
- [ ] Upload Wear OS screenshots only if the Play listing declares Wear OS
      support in this release.
- [ ] Upload app icon and feature graphic.
- [ ] Add internal testing release notes.

## Internal Testing QA Template

Fill this after installing from Play Console internal testing, not from a local
debug or side-loaded build.

| Field | Result |
| --- | --- |
| Tester | Pending |
| Device model | Pending |
| Android version | Pending |
| Install source | Play Console internal testing |
| AAB SHA-256 | `50c00b66247c04f7b86bf27091e94443f2e9ec85bc0b88eaf4833a35c7f6765b` |
| Test account | Stored outside repo |
| Signup/login | Pending |
| Email verification | Pending |
| Profile onboarding | Pending |
| Buddy onboarding | Pending |
| Workout save/list/delete | Pending |
| Help & Support request | Pending |
| Privacy page opens | Pending |
| Account deletion request | Pending |
| Supabase row verification | Pending |
| Notes | Pending |

## Do Not Promote Past Internal Testing Until

- [ ] Internal testing smoke passes on a real Android device from Play Console.
- [ ] Supabase Auth email templates are copied into the dashboard.
- [ ] Supabase redirect URLs include Android and web production URLs.
- [ ] Store listing, Data safety, privacy, account deletion, content rating, and
      target audience sections are complete.
- [ ] The uploaded AAB matches the SHA-256 in this pack or the pack is refreshed
      for the newly uploaded artifact.
