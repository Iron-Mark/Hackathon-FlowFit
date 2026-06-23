# FlowFit Play Store Release Notes and QA Evidence - 2026-06-19

Use this file with `docs/release/FINAL_RELEASE_HANDOFF_2026-06-19.md`.

## Play Store Release Notes

### Internal Testing

Initial FlowFit internal testing build.

- Adds account signup and login with Supabase-backed profiles.
- Adds profile onboarding for goals, units, and fitness preferences.
- Adds Buddy companion setup and progress surfaces.
- Adds workout and wellness tracking screens.
- Adds Wear OS phone/watch build support and sensor-oriented flows.
- Adds public privacy and account deletion pages for store review.
- Adds in-app account deletion request flow from Profile > Settings.

### Closed Testing

FlowFit helps testers try the first maintained-fork release of the app. This
build focuses on authentication, onboarding, Buddy setup, workout tracking,
public privacy pages, and Android release packaging.

Known verification focus:

- Confirm signup and email verification.
- Complete profile and Buddy onboarding.
- Save and list one workout session.
- Confirm Profile > Settings > Delete Account is visible.
- Confirm privacy and account deletion URLs open from the app and from a
  browser.

### Production Draft

FlowFit combines workout tracking, wellness goals, and Buddy companion progress
in one app. Create a profile, complete onboarding, set goals, customize Buddy,
and track activity sessions. The app includes public privacy and account
deletion pages plus an in-app account deletion request flow.

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

## Verified QA Evidence

| Check | Result | Evidence |
| --- | --- | --- |
| Source commit pushed | Passed | `f8321f9f29d49b9d6b0686ffb96e496ef8c37208` on `origin/main` |
| Local analyzer | Passed | `flutter analyze`, no issues |
| Local tests | Passed | `flutter test --reporter compact`, 840 passed and 1 skipped |
| Strict release audit | Passed | `69 pass, 1 warn, 0 fail` |
| Android release lint | Passed | Wrapper Android lint stage succeeded |
| Play Store AAB build | Passed | `build/app/outputs/bundle/release/app-release.aab` |
| Artifact verification | Passed | `12 pass, 0 warn, 0 fail` |
| Flutter CI | Passed | <https://github.com/Iron-Mark/Hackathon-FlowFit/actions/runs/27812413453> |
| Flutter Web Pages | Passed | <https://github.com/Iron-Mark/Hackathon-FlowFit/actions/runs/27812413448> |
| Protected release workflow docs CI | Passed | <https://github.com/Iron-Mark/Hackathon-FlowFit/actions/runs/27815624424> |

Artifact hash:

```text
build/app/outputs/bundle/release/app-release.aab
SHA-256: e62358e4f3251e540e6742ccf4380ce2e276634a8f72287fb5832849fd3b1f10
Size: 113,820,977 bytes
```

## Real-Device Internal Testing Checklist

Run this after uploading the AAB to Play Console internal testing.

- [ ] Install from Play Console internal testing, not from local debug build.
- [ ] Open the app on a clean device or fresh app data.
- [ ] Create a new test account.
- [ ] Confirm the signup email arrives.
- [ ] Confirm the auth callback returns to the app.
- [ ] Complete profile onboarding.
- [ ] Confirm `user_profiles` has one row for the signed-in auth user.
- [ ] Complete Buddy onboarding.
- [ ] Confirm `buddy_profiles` has one row for the signed-in auth user.
- [ ] Confirm Buddy fields in `user_profiles` update by `user_id`.
- [ ] Save one workout session.
- [ ] Confirm the workout appears again after app restart.
- [ ] Open Profile > Settings > Privacy Policy.
- [ ] Open Profile > Settings > Delete Account.
- [ ] Submit one deletion request with a throwaway test account.
- [ ] Confirm the app signs out and does not recreate app-owned rows.

## Supabase QA Evidence And Remaining Work

These checks require release Supabase credentials or dashboard access:

- [ ] Supabase Auth advisor warnings are resolved or explicitly accepted for
      release: leaked-password protection and additional MFA options.
- [x] `supabase db lint --linked` or equivalent advisor/lint command passes.
- [x] Supabase advisors were run against the intended project with 0 error
      findings and 2 Auth warnings.
- [x] `scripts/verify_supabase_backend.ps1 -Linked` passes against the release
      project.
      Evidence from 2026-06-23: `build/supabase-db-lint-advisors-current.json`.
- [ ] Auth email templates are copied into Supabase dashboard.
- [ ] Auth redirect URLs include Android and web production URLs.
- [ ] One live signup/login/onboarding/workout path passes against the release
      project.
