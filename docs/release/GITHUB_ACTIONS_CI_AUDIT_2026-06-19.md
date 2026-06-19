# FlowFit GitHub Actions CI Audit - 2026-06-19

## Remote Workflow Status

`gh workflow list --repo Iron-Mark/Hackathon-FlowFit` confirmed both workflows
are active:

- `Flutter CI`
- `Flutter Web Pages`

Latest runs on commit `f8321f9f29d49b9d6b0686ffb96e496ef8c37208`:

| Workflow | Result | URL |
| --- | --- | --- |
| Flutter CI | Success | <https://github.com/Iron-Mark/Hackathon-FlowFit/actions/runs/27812413453> |
| Flutter Web Pages | Success | <https://github.com/Iron-Mark/Hackathon-FlowFit/actions/runs/27812413448> |

## Current Automatic Gates

`.github/workflows/flutter-ci.yml` runs automatically on pull requests, pushes
to `main`, pushes to `develop`, pushes to `supabase/**`, and manual dispatch.

The workflow currently covers:

- Flutter dependency restore.
- Advisory release readiness audit.
- Release source safety checks for legacy redirects and privileged SQL.
- `dart analyze --format=machine`.
- `flutter analyze`.
- `flutter test --reporter compact`.
- Flutter web JavaScript release smoke build.
- Public privacy/account-deletion page checks.
- Local static web deployment verification.
- Flutter web Wasm smoke build.
- Android debug APK build.
- Wear OS debug APK build.
- Android release App Bundle smoke build with debug signing and smoke IDs.
- Upload of web, Wasm, web verification, and release-smoke AAB artifacts.

`.github/workflows/flutter-web-pages.yml` runs readiness checks on PRs and
publishes only when production repository variables are valid and the workflow
runs on `main` or by manual dispatch.

The deployment workflow currently covers:

- Production web deploy variable validation.
- `scripts/store_release_build.ps1 -Target Web`.
- GitHub Pages deployment.
- Public deployed site verification with `scripts/verify_web_deployment.ps1`.
- Upload of deployed-site verification evidence.

## Audit Result

The repo already has automatic CI coverage for the same code-quality and
compile gates used before the checkpoint push:

- Analyzer gate: covered.
- Full Flutter test gate: covered.
- Android phone debug build: covered.
- Wear OS debug build: covered.
- Android release bundle compile-smoke: covered.
- Web JS and Wasm compile-smoke: covered.
- Public compliance pages: covered.
- Web deployment verification: covered in Pages workflow when production
  repository variables are configured.

No workflow patch was required for this audit because both workflows are active
and passing on the exact pushed release commit.

## Intentional CI Limits

These are not failures:

- CI does not build the real Play Store AAB because upload signing credentials,
  release Supabase values, and support-inbox verification are secret or
  environment-specific.
- CI does not run strict release audit by default because strict mode requires
  maintainer-owned Supabase, signing, public web, support inbox, and MCP
  release posture inputs.
- CI does not run Supabase advisors or DB lint because those require
  authenticated Supabase CLI access and the project DB password.
- CI does not build iOS IPA because GitHub-hosted Ubuntu lacks macOS/Xcode
  signing.

## Recommended Future Hardening

When release secrets are ready, add a protected manual workflow for production
artifact rebuilds. It should run only by manual dispatch or on protected tags,
use GitHub environments, and require reviewer approval before exposing signing
secrets.

Suggested gates for that future protected workflow:

```powershell
pwsh -NoProfile -File scripts\release_readiness_audit.ps1 `
  -Strict `
  -SupportEmailVerified `
  -OutFile build\store-release-readiness-audit.json

pwsh -NoProfile -File scripts\store_release_build.ps1 `
  -Target Android `
  -RunStrictAudit `
  -SupportEmailVerified

pwsh -NoProfile -File scripts\verify_store_artifacts.ps1 `
  -Strict `
  -RequireArtifact android-play-store-aab `
  -RequireStrictAudit `
  -RequireCurrentCommit
```

Do not add this as an unprotected push workflow. It would expose signing and
release backend inputs to every normal CI run.
