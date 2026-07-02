# FlowFit MVP Launch Readiness - 2026-07-02

This snapshot records the current MVP release state after PR #13 merged and the
follow-up evidence refresh on `codex/flowfit-launch-evidence-refresh`.

## Current Verdict

FlowFit is green on repo-controlled and runtime-controlled MVP evidence for an
app-owned support path. The public support inbox remains an external
store/contact warning until inbound receipt proof is recorded.

The linked Supabase project is reachable and reports `ACTIVE_HEALTHY`.
Migrations are up to date, backend verification passes, the live app smoke
passes against authenticated RLS, and GitHub CI is green on `main` commit
`1c7db18a694c7d504547a3c90993e91e87e7cd7a` after PR #13 merged. The Help &
Support screen now submits authenticated in-app support and bug requests to
`public.support_requests`; email remains a fallback public contact surface.

Do not call the app store-ready or externally submitted until final store/account
review steps are completed, including any platform-required public support email
proof.

## Fresh Evidence

| Area | Command | Result |
| --- | --- | --- |
| GitHub PR status | `gh pr view 13 --repo Iron-Mark/Hackathon-FlowFit --json ...` | PR #13, `[codex] Add FlowFit landing page and launch gates`, merged to `main` at `2026-07-02T15:29:15Z` as `1c7db18a694c7d504547a3c90993e91e87e7cd7a`; its final head commit was `184e5c37567ddc127be731824de384dcdb9d7dc9`. |
| GitHub main Flutter CI | `gh run view 28601898762 --repo Iron-Mark/Hackathon-FlowFit --json status,conclusion,jobs,url` | Passed on `main` commit `1c7db18a694c7d504547a3c90993e91e87e7cd7a`: Windows offline app action smoke, release readiness audit, release source safety, Dart format, analyzer, full Flutter tests, web JS build, web compliance/static smoke, web Wasm build, Android debug APK, Wear OS debug APK, and Android release App Bundle smoke build. |
| GitHub main Web Pages readiness | `gh run view 28601898718 --repo Iron-Mark/Hackathon-FlowFit --json status,conclusion,jobs,url` | Workflow passed on `main` commit `1c7db18a694c7d504547a3c90993e91e87e7cd7a`; `Check web deploy readiness` succeeded and `Build and Deploy Flutter Web` was skipped. |
| GitHub Flutter CI | `gh run view 28600340969 --repo Iron-Mark/Hackathon-FlowFit --json status,conclusion,jobs,url` | Passed on commit `184e5c37567ddc127be731824de384dcdb9d7dc9`: Windows offline app action smoke, release readiness audit, release source safety, Dart format, analyzer, full Flutter tests, web JS build, web compliance/static smoke, web Wasm build, Android debug APK, Wear OS debug APK, and Android release App Bundle smoke build. |
| GitHub Web Pages readiness | `gh run list --repo Iron-Mark/Hackathon-FlowFit --branch codex/flowfit-landing-page --limit 5 --json ...` | Workflow run `28600340886` passed the deploy-readiness check on commit `184e5c37567ddc127be731824de384dcdb9d7dc9`; the deployment job was skipped because this PR branch is not the production Pages deployment path. |
| Supabase project inventory | `npx -y supabase@latest projects list --output json` | Linked project `xhmkghwijqpvnbpeeckg` / `flowfit` reports `ACTIVE_HEALTHY`. |
| Supabase host DNS | `Resolve-DnsName xhmkghwijqpvnbpeeckg.supabase.co` | Resolved to Cloudflare A records. |
| Support request migration drift check | `npx -y supabase@latest db push --linked --dry-run` | Passed after apply; the remote database is up to date. The initial pre-apply dry run showed only `20260703010000_add_support_requests.sql` pending. |
| Support request migration apply | `npx -y supabase@latest db push --linked` | Passed; `20260703010000_add_support_requests.sql` applied to the linked Supabase project. |
| Backend verification | `scripts/verify_supabase_backend.ps1 -Linked -Output json` | Passed 19 read-only schema/RLS/grant checks. |
| Live app smoke | `scripts/verify_supabase_app_smoke.ps1 -EnvFile .env -AllowExternalWrites -OutFile build/supabase-app-smoke.json` | Passed 7 checks: auth sign-in, smoke row guard, profile upsert, buddy upsert, workout create/update/list/delete, heart-rate insert/list, and support request create/read/delete. |
| Android live-auth E2E smoke | `scripts/verify_android_live_auth_smoke.ps1 -Device emulator-5554 -EnvFile .env -OutFile build/android-live-auth-smoke-latest.json` | Passed 122 checks on `sdk_gphone64_x86_64` / Android 15: login, age gate, survey onboarding, dashboard tabs, Health food add/remove, Track routes, Buddy setup, Supabase row assertions, cleanup, and no AndroidRuntime crash markers. |
| Strict release audit | `scripts/release_readiness_audit.ps1 -Strict -EnvFile .env -OutFile build/store-release-readiness-audit.json` | Refreshed after the in-app support queue migration: 76 pass, 2 warn, 0 fail. The remaining support inbox item is a store/contact warning, not the app-support path. |
| GitHub-variable strict snapshot | `scripts/release_status_snapshot.ps1 -Repo Iron-Mark/Hackathon-FlowFit -PullRequest 15 -OutFile build/release-status-snapshot.md` | Snapshot refreshed for PR #15; GitHub-variable strict audit reports 77 pass, 2 warn, 0 fail, PR checks are green, and PR merge state is `CLEAN`. |
| Store metadata | `scripts/verify_store_metadata.ps1 -Strict -GitHubRepo Iron-Mark/Hackathon-FlowFit -OutFile build/store-metadata-verification.json` | Passed 48 checks, 0 warnings, 0 failures. |
| Store artifact verification | `scripts/verify_store_artifacts.ps1 -Strict -RequireStrictAudit -RequireCurrentCommit` | 0 pass, 0 warn, 1 fail because `build/store-release-artifacts.json` does not exist yet. Final artifact generation is blocked until support inbox proof is complete. |
| Offline release preflight | `scripts/release_preflight.ps1 -IncludeReleaseSmoke` | Passed advisory audit, metadata advisory check, dependency install, analyzer, full Flutter tests, web JS build, local web smoke, Android debug build, Wear debug build, and Android release App Bundle smoke build. |
| Full Flutter tests | `flutter test --reporter compact` | Passed locally after the support request UI/service changes. GitHub Actions run `28601898762` remains the green `main` baseline. |
| Public web deployment | `scripts/verify_web_deployment.ps1 -BaseUrl https://iron-mark.github.io/Hackathon-FlowFit -SupportEmail marksiazon.dev@gmail.com -OutFile build/web-deployment-verification.json` | Passed 15 HTTP/content/compliance checks against GitHub Pages. |
| Public web app smoke | `npm run web:smoke -- --base-url https://iron-mark.github.io/Hackathon-FlowFit --out-file build/web-app-smoke-public.json` | Passed 58 browser workflow checks, 8 Chromium/WebGL software-rendering warnings, 0 app console errors, 0 failed requests. |
| Local runnable web build | `flutter build web --release --no-pub` with ignored local Supabase client config passed as Dart defines | Built `build/web` locally after the support request UI/service changes on Flutter 3.41.9 stable / Dart 3.11.5. |
| Local runnable web app smoke | `npm run web:smoke -- --base-url http://127.0.0.1:<local-port> --out-file build/web-app-smoke-local.json` | Passed 59 browser workflow checks against the locally served release web build, with 9 Chromium/WebGL software-rendering warnings, 0 app console errors, and 0 failed requests. |
| Android phone debug build | `flutter build apk --debug --no-pub` | Passed locally; built `build/app/outputs/flutter-apk/app-debug.apk`. |
| Wear OS debug build | `flutter build apk --debug -t lib/main_wear.dart --no-pub` | Passed locally; built `build/app/outputs/flutter-apk/app-debug.apk` for the Wear entrypoint. |
| Android phone emulator smoke | `scripts/verify_android_phone_smoke.ps1 -Device emulator-5554 -EnvFile .env -OutFile build/android-phone-smoke-latest.json` | Passed on `sdk_gphone64_x86_64` / Android 15 with 24 checks and no AndroidRuntime crash markers. |
| Wear OS emulator smoke | `scripts/verify_wear_emulator_smoke.ps1 -OutFile build/wear-emulator-smoke-latest.json` | Passed on `sdk_gwear_x86_64` / Android 14 with 20 checks and no AndroidRuntime crash markers. |
| Dart formatting | `scripts/verify_dart_format.ps1` | Passed for 463 tracked Dart files. |
| Focused release guard tests | `flutter test test/scripts/release_guard_source_test.dart --reporter compact` | Passed 95 tests. |

## Evidence Files

| File | Contents |
| --- | --- |
| `build/store-release-readiness-audit.json` | Strict local release audit evidence; currently 76 pass, 2 warn, 0 fail. |
| `build/release-status-snapshot.md` | Non-secret GitHub/release snapshot for PR #15; currently 77 pass, 2 warn, 0 fail under GitHub repository variables, with PR checks green and merge state `CLEAN`. |
| `build/supabase-app-smoke.json` | Live Supabase app smoke evidence with redacted smoke email, including support request create/read/delete, and no printed keys. |
| `build/android-live-auth-smoke-latest.json` | Native Android live-auth E2E smoke evidence with redacted credentials and screenshots/UI dumps under `build/android-live-auth-smoke/`. |
| `build/store-metadata-verification.json` | Strict store metadata evidence; 48 pass, 0 warn, 0 fail. |
| `build/store-release-artifact-verification.json` | Strict store artifact verification evidence; currently fails because no final store release artifact manifest has been generated. |
| `build/web-deployment-verification.json` | Public GitHub Pages HTTP/content/compliance evidence. |
| `build/web-app-smoke-public.json` | Public browser workflow smoke evidence. |
| `build/web-app-smoke-local.json` | Local browser workflow smoke evidence against the locally served release web build. |
| `build/web-app-smoke-preflight.json` | Local preflight browser workflow smoke evidence. |
| `build/android-phone-smoke-latest.json` | Android phone emulator smoke evidence and artifact paths. |
| `build/wear-emulator-smoke-latest.json` | Wear OS emulator smoke evidence and artifact paths. |
| `build/support-inbox-verification.json` | Support inbox evidence; `confirmedInbound=false`. |

## Remaining Blockers

| Gate | Current result | Required fix |
| --- | --- | --- |
| Production support inbox | `build/support-inbox-verification.json` confirms Gmail MX records but `confirmedInbound=false`; strict audit now reports this as a store/contact warning because the in-app support queue is verified. | Optional for app MVP; required before store submission if the platform/release checklist needs external inbox proof. Rerun `scripts/verify_support_inbox.ps1 -EnvFile .env -ConfirmedInbound -ReceivedFrom "<external-sender>" -ReceivedAt "<received-timestamp>" -EvidenceNote "<evidence>" -OutFile build/support-inbox-verification.json`. |
| Supabase Auth dashboard templates | Rendered templates exist in `build/supabase-email-templates`, but dashboard copy was not verified locally. | Copy rendered templates into Supabase Auth Email Templates before store submission. |
| Store submission | Local checks do not prove Play Console/App Store Connect account, review, data-safety, content-rating, or device review completion. | Complete platform submission steps with the appropriate account access and final signed artifacts. |
| Docker-local Supabase validation | Strict audit warns Docker CLI is unavailable on this Windows host. | Optional: install Docker only if local Supabase stack validation is required; linked backend verification already passes. |

## Release Notes

- GitHub release variables are present and `FLOWFIT_SUPPORT_EMAIL_VERIFIED` is
  set to `false`, matching external inbox evidence. This no longer blocks the
  authenticated in-app support request path.
- `public.support_requests` is applied on the linked Supabase project and live
  app smoke verifies support request create/read/delete through authenticated
  RLS.
- GitHub PR #13 was merged into `main`; the post-merge `main` Flutter CI and
  Web Pages readiness workflows are green on
  `1c7db18a694c7d504547a3c90993e91e87e7cd7a`.
- The Supabase publishable key is present in local/GitHub configuration and was
  not printed in logs or docs.
- `.env` and `lib/secrets.dart` remain ignored local configuration surfaces.
- The offline preflight generated a release-smoke App Bundle with dummy
  Supabase Dart defines and debug release signing. It is useful build evidence,
  not a store-upload artifact.
- No `build/store-release-artifacts.json` manifest exists yet, so strict store
  artifact verification is intentionally not claimed.
- Gmail connector access is not part of the app-support evidence path.

## Launch Plan

1. Copy rendered Supabase Auth email templates into the active Supabase project.
2. Generate final signed store artifacts with real signing/export inputs.
3. Run `scripts/verify_store_artifacts.ps1 -Strict -RequireStrictAudit -RequireCurrentCommit` after artifact generation.
4. Complete Play Console/App Store Connect review tasks and device checks.
5. Record optional public support inbox receipt proof if required for store review.
