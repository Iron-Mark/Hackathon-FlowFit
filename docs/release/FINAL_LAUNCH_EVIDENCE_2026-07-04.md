# FlowFit Final Launch Evidence - 2026-07-04

This handoff records the current repo-controlled MVP launch evidence after PR
#16 merged to `main`.

## Verdict

FlowFit is ready for the repo-controlled MVP launch path.

The web MVP is live, the merged `main` CI is green, the app-owned support
request path is implemented through Supabase, the external support inbox receipt
is confirmed, and the Android Play Store AAB has strict artifact evidence from
a clean `main` checkout.

Do not treat this as proof of Play Console review, App Store Connect review, or
iOS IPA readiness. Those require external account access and macOS/Xcode
signing.

## Release Identity

| Field | Value |
| --- | --- |
| Repository | `Iron-Mark/Hackathon-FlowFit` |
| Main commit | `756cfe86b369a18aca52fa6b694041835ab17400` |
| Merged PR | `#16` - `ci(supabase): validate local stack in CI` |
| Android package ID | `com.msiazondev.flowfit` |
| iOS bundle ID | `com.msiazondev.flowfit` |
| Public web URL | `https://iron-mark.github.io/Hackathon-FlowFit/` |
| Privacy URL | `https://iron-mark.github.io/Hackathon-FlowFit/privacy.html` |
| Account deletion URL | `https://iron-mark.github.io/Hackathon-FlowFit/account-deletion.html` |
| Support email | `marksiazon.dev@gmail.com` |

## Current Evidence

| Area | Evidence | Result |
| --- | --- | --- |
| Live web app | `Invoke-WebRequest https://iron-mark.github.io/Hackathon-FlowFit/` | HTTP `200`, title `FlowFit` |
| Main CI | `gh run view 28671430810 --repo Iron-Mark/Hackathon-FlowFit` | `success` on `756cfe86b369a18aca52fa6b694041835ab17400` |
| Supabase Docker local validation in CI | Main CI job `Supabase Docker Local Validation` | Passed; reset local database from tracked migrations and ran backend verification |
| Windows offline app action smoke | Main CI job `Windows Offline App Action Smoke` | Passed |
| Analyze, test, and build | Main CI job `Analyze, Test, and Build` | Passed analyzer, full tests, web JS/Wasm builds, Android debug, Wear OS debug, and release App Bundle smoke |
| Strict release audit | `build/store-release-readiness-audit.json` | `77 pass, 1 warn, 0 fail` |
| Android store artifact manifest | `build/store-release-artifacts.json` | Clean `main` commit, `dirty=false`, support email verified |
| Android artifact verification | `build/store-release-artifact-verification.json` | `12 pass, 0 warn, 0 fail` |
| Android AAB | `build/app/outputs/bundle/release/app-release.aab` | 115,238,159 bytes, SHA-256 `1c2423d3a296630eedf2c234cc39aa4c5bb1b836c1de6a95bd729a0fb42f5cff` |
| Support inbox receipt | `build/support-inbox-verification.json` | Confirmed inbound from `onboarding@resend.dev` at `2026-07-03T21:18:46.49728+08:00`, message id `985c0498-9768-4787-ab36-5de3468882ba` |

## Artifact Manifest Summary

`build/store-release-artifacts.json` records:

| Field | Value |
| --- | --- |
| Target | Android |
| Commit | `756cfe86b369a18aca52fa6b694041835ab17400` |
| Dirty tree | `false` |
| Support email verified | `true` |
| Support email | `marksiazon.dev@gmail.com` |
| Public web base URL | `https://iron-mark.github.io/Hackathon-FlowFit` |
| Supabase URL | `https://xhmkghwijqpvnbpeeckg.supabase.co` |
| Android application ID | `com.msiazondev.flowfit` |
| Android auth scheme | `com.msiazondev.flowfit` |
| Web build backend | JavaScript |

## Files To Archive With Android Handoff

- `build/app/outputs/bundle/release/app-release.aab`
- `build/store-release-artifacts.json`
- `build/store-release-artifact-verification.json`
- `build/store-release-readiness-audit.json`
- `build/support-inbox-verification.json`
- `build/supabase-email-templates/confirm_signup.html`
- `build/supabase-email-templates/confirm_signup.txt`

## External Steps Still Required

- Copy the rendered Supabase Auth confirm-signup templates into the Supabase
  dashboard.
- Upload the AAB to Play Console internal testing and complete Play Console app
  content, Data safety, content rating, target audience, and review.
- Build iOS IPA on macOS/Xcode with Apple signing before TestFlight/App Store
  submission.
- Complete any store-console real-device testing and review workflows.

