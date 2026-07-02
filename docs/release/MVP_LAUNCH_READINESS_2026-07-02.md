# FlowFit MVP Launch Readiness - 2026-07-02

This snapshot records the current MVP release state after the resumed release
readiness pass on `codex/flowfit-landing-page`.

## Current Verdict

FlowFit is green on repo-controlled and runtime-controlled MVP evidence, but it
is not final launch-ready while the production support inbox remains unverified.

The linked Supabase project is reachable and reports `ACTIVE_HEALTHY`.
Migrations are up to date, backend verification passes, the live app smoke
passes against authenticated RLS, and GitHub CI is green for the PR #13 head
commit `184e5c37567ddc127be731824de384dcdb9d7dc9`. PR #13 was merged to
`main` as merge commit `1c7db18a694c7d504547a3c90993e91e87e7cd7a`. The strict
release gate is down to one real failure: proof that the configured public
support/privacy inbox can receive external mail.

Per the resumed instruction, the support-inbox proof blocker is being skipped
for continued local/release work only. Do not call the MVP fully launch-ready,
store-ready, or externally complete until that support inbox evidence is
confirmed and final store/account review steps are completed.

## Fresh Evidence

| Area | Command | Result |
| --- | --- | --- |
| GitHub PR status | `gh pr view 13 --repo Iron-Mark/Hackathon-FlowFit --json ...` | PR #13, `[codex] Add FlowFit landing page and launch gates`, merged to `main` at `2026-07-02T15:29:15Z` as `1c7db18a694c7d504547a3c90993e91e87e7cd7a`; its final head commit was `184e5c37567ddc127be731824de384dcdb9d7dc9`. |
| GitHub Flutter CI | `gh run view 28600340969 --repo Iron-Mark/Hackathon-FlowFit --json status,conclusion,jobs,url` | Passed on commit `184e5c37567ddc127be731824de384dcdb9d7dc9`: Windows offline app action smoke, release readiness audit, release source safety, Dart format, analyzer, full Flutter tests, web JS build, web compliance/static smoke, web Wasm build, Android debug APK, Wear OS debug APK, and Android release App Bundle smoke build. |
| GitHub Web Pages readiness | `gh run list --repo Iron-Mark/Hackathon-FlowFit --branch codex/flowfit-landing-page --limit 5 --json ...` | Workflow run `28600340886` passed the deploy-readiness check on commit `184e5c37567ddc127be731824de384dcdb9d7dc9`; the deployment job was skipped because this PR branch is not the production Pages deployment path. |
| Supabase project inventory | `npx -y supabase@latest projects list --output json` | Linked project `xhmkghwijqpvnbpeeckg` / `flowfit` reports `ACTIVE_HEALTHY`. |
| Supabase host DNS | `Resolve-DnsName xhmkghwijqpvnbpeeckg.supabase.co` | Resolved to Cloudflare A records. |
| Migration dry run | `npx -y supabase@latest db push --linked --dry-run` | Passed; remote database is up to date. |
| Migration apply | `npx -y supabase@latest db push --linked` | Passed; no pending migrations were applied because remote database is up to date. |
| Backend verification | `scripts/verify_supabase_backend.ps1 -Linked -Output json` | Passed 19 read-only schema/RLS/grant checks. |
| Live app smoke | `scripts/verify_supabase_app_smoke.ps1 -EnvFile .env -AllowExternalWrites -OutFile build/supabase-app-smoke.json` | Passed 6 checks: auth sign-in, smoke row guard, profile upsert, buddy upsert, workout create/update/list/delete, and heart-rate insert/list. |
| Android live-auth E2E smoke | `scripts/verify_android_live_auth_smoke.ps1 -Device emulator-5554 -EnvFile .env -OutFile build/android-live-auth-smoke-latest.json` | Passed 122 checks on `sdk_gphone64_x86_64` / Android 15: login, age gate, survey onboarding, dashboard tabs, Health food add/remove, Track routes, Buddy setup, Supabase row assertions, cleanup, and no AndroidRuntime crash markers. |
| Strict release audit | `scripts/release_readiness_audit.ps1 -Strict -EnvFile .env -OutFile build/store-release-readiness-audit.json` | 71 pass, 1 warn, 1 fail. The fail is support-inbox proof. |
| GitHub-variable strict snapshot | `scripts/release_status_snapshot.ps1 -Repo Iron-Mark/Hackathon-FlowFit -OutFile build/release-status-snapshot.md` | Snapshot written; GitHub-variable strict audit reports 72 pass, 1 warn, 1 fail. |
| Store metadata | `scripts/verify_store_metadata.ps1 -Strict -GitHubRepo Iron-Mark/Hackathon-FlowFit -OutFile build/store-metadata-verification.json` | Passed 48 checks, 0 warnings, 0 failures. |
| Store artifact verification | `scripts/verify_store_artifacts.ps1 -Strict -RequireStrictAudit -RequireCurrentCommit` | 0 pass, 0 warn, 1 fail because `build/store-release-artifacts.json` does not exist yet. Final artifact generation is blocked until support inbox proof is complete. |
| Offline release preflight | `scripts/release_preflight.ps1 -IncludeReleaseSmoke` | Passed advisory audit, metadata advisory check, dependency install, analyzer, full Flutter tests, web JS build, local web smoke, Android debug build, Wear debug build, and Android release App Bundle smoke build. |
| Full Flutter tests | GitHub Actions / Flutter CI run `28600340969`, step `Flutter tests` | Passed on commit `184e5c37567ddc127be731824de384dcdb9d7dc9` after support-proof schema hardening. |
| Public web deployment | `scripts/verify_web_deployment.ps1 -BaseUrl https://iron-mark.github.io/Hackathon-FlowFit -SupportEmail marksiazon.dev@gmail.com -OutFile build/web-deployment-verification.json` | Passed 15 HTTP/content/compliance checks against GitHub Pages. |
| Public web app smoke | `npm run web:smoke -- --base-url https://iron-mark.github.io/Hackathon-FlowFit --out-file build/web-app-smoke-public.json` | Passed 58 browser workflow checks, 8 Chromium/WebGL software-rendering warnings, 0 app console errors, 0 failed requests. |
| Android phone emulator smoke | `scripts/verify_android_phone_smoke.ps1 -Device emulator-5554 -EnvFile .env -OutFile build/android-phone-smoke-latest.json` | Passed on `sdk_gphone64_x86_64` / Android 15 with 24 checks and no AndroidRuntime crash markers. |
| Wear OS emulator smoke | `scripts/verify_wear_emulator_smoke.ps1 -OutFile build/wear-emulator-smoke-latest.json` | Passed on `sdk_gwear_x86_64` / Android 14 with 20 checks and no AndroidRuntime crash markers. |
| Dart formatting | `scripts/verify_dart_format.ps1` | Passed for 463 tracked Dart files. |
| Focused release guard tests | `flutter test test/scripts/release_guard_source_test.dart --reporter compact` | Passed 95 tests. |

## Evidence Files

| File | Contents |
| --- | --- |
| `build/store-release-readiness-audit.json` | Strict local release audit evidence; currently 71 pass, 1 warn, 1 fail. |
| `build/release-status-snapshot.md` | Non-secret GitHub/release snapshot; currently 72 pass, 1 warn, 1 fail under GitHub repository variables. |
| `build/supabase-app-smoke.json` | Live Supabase app smoke evidence with redacted smoke email and no printed keys. |
| `build/android-live-auth-smoke-latest.json` | Native Android live-auth E2E smoke evidence with redacted credentials and screenshots/UI dumps under `build/android-live-auth-smoke/`. |
| `build/store-metadata-verification.json` | Strict store metadata evidence; 48 pass, 0 warn, 0 fail. |
| `build/store-release-artifact-verification.json` | Strict store artifact verification evidence; currently fails because no final store release artifact manifest has been generated. |
| `build/web-deployment-verification.json` | Public GitHub Pages HTTP/content/compliance evidence. |
| `build/web-app-smoke-public.json` | Public browser workflow smoke evidence. |
| `build/web-app-smoke-preflight.json` | Local preflight browser workflow smoke evidence. |
| `build/android-phone-smoke-latest.json` | Android phone emulator smoke evidence and artifact paths. |
| `build/wear-emulator-smoke-latest.json` | Wear OS emulator smoke evidence and artifact paths. |
| `build/support-inbox-verification.json` | Support inbox evidence; `confirmedInbound=false`. |

## Remaining Blockers

| Gate | Current result | Required fix |
| --- | --- | --- |
| Production support inbox | `build/support-inbox-verification.json` confirms Gmail MX records but `confirmedInbound=false`; strict audit fails this gate. | Send an external test email to `marksiazon.dev@gmail.com`, confirm receipt, then rerun `scripts/verify_support_inbox.ps1 -EnvFile .env -ConfirmedInbound -ReceivedFrom "<external-sender>" -ReceivedAt "<received-timestamp>" -EvidenceNote "<evidence>" -OutFile build/support-inbox-verification.json`. |
| Supabase Auth dashboard templates | Rendered templates exist in `build/supabase-email-templates`, but dashboard copy was not verified locally. | Copy rendered templates into Supabase Auth Email Templates after support-inbox proof is complete. |
| Store submission | Local checks do not prove Play Console/App Store Connect account, review, data-safety, content-rating, or device review completion. | Complete platform submission steps with the appropriate account access and final signed artifacts. |
| Docker-local Supabase validation | Strict audit warns Docker CLI is unavailable on this Windows host. | Optional: install Docker only if local Supabase stack validation is required; linked backend verification already passes. |

## Release Notes

- GitHub release variables are present and `FLOWFIT_SUPPORT_EMAIL_VERIFIED` is
  set to `false`, matching current evidence.
- GitHub PR #13 was merged into `main`, and all required branch checks were
  green on its final head commit
  `184e5c37567ddc127be731824de384dcdb9d7dc9`.
- The Supabase publishable key is present in local/GitHub configuration and was
  not printed in logs or docs.
- `.env` and `lib/secrets.dart` remain ignored local configuration surfaces.
- The offline preflight generated a release-smoke App Bundle with dummy
  Supabase Dart defines and debug release signing. It is useful build evidence,
  not a store-upload artifact.
- No `build/store-release-artifacts.json` manifest exists yet, so strict store
  artifact verification is intentionally not claimed.
- A read-only Gmail mailbox search could not be used for support proof because
  the connected Gmail account requires reauthentication
  (`oauth_token_invalid_grant`).

## Launch Plan

1. Finish support inbox proof and rerun strict audit.
2. Copy rendered Supabase Auth email templates into the active Supabase project.
3. Generate final signed store artifacts with real signing/export inputs.
4. Run `scripts/verify_store_artifacts.ps1 -Strict -RequireStrictAudit -RequireCurrentCommit` after artifact generation.
5. Complete Play Console/App Store Connect review tasks and device checks.
