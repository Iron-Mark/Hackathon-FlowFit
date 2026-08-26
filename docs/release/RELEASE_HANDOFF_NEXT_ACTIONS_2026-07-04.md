# FlowFit Release Handoff — Next Actions (2026-07-04)

> Historical snapshot from 2026-07-04. For current status use
> [AGENTS.md](../../AGENTS.md) and
> [STORE_SUBMISSION_CHECKLIST.md](../STORE_SUBMISSION_CHECKLIST.md).

## Status as of 2026-07-04 (in-repo completed)

- Landing marketing page exists and is wired as web entry (`/`) in `lib/main.dart` and `lib/screens/landing/flowfit_landing_page.dart`.
- GitHub Pages verification: `build/web-deployment-verification-final-check.json` shows 15/15 checks passed.
- Local launch evidence is aligned to current artifact set in the current run set:
  - AAB SHA-256: `dfee10776f5eab4de1d323ff2f7a30bf334fe619ebf309f44a1da785ee7c01ec`
  - AAB size: `115,238,170` bytes
  - Main commit tracked in launch docs: `ac16770e0a5585c341bbe1ecef2736b5c91abf86`
  - Store metadata strict check: `48 pass, 0 warn, 0 fail`
- Release audit status: `build/store-release-readiness-audit.json` summary `77 pass, 1 warn, 0 fail` (warn is local Docker CLI missing for local backend validation).
- Working tree is intentionally dirty while preparing the release docs (`3` launch-related edits + this file), including `-AllowDirtyManifest` build context.

## What’s still blocked (requires external setup)

- Android phone smoke check (`scripts/verify_android_phone_smoke.ps1`) requires a connected Android device or emulator.
- Wear smoke check (`scripts/verify_wear_emulator_smoke.ps1`) requires a connected Wear device or emulator.
- Live auth smoke check (`scripts/verify_android_live_auth_smoke.ps1`) currently fails because `smokeEmail` is empty in invocation.
- Full console submission remains manual:
  - Google Play Console upload + listing/data safety/release notes
  - iOS/TestFlight flow on macOS/Xcode

## Recommended next actions

1. Connect Android phone and Wear test targets, then rerun in one pass:
   - `pwsh -NoProfile -File scripts\verify_android_phone_smoke.ps1`
   - `pwsh -NoProfile -File scripts\verify_wear_emulator_smoke.ps1`
   - `pwsh -NoProfile -File scripts\verify_android_live_auth_smoke.ps1 -SmokeEmail <email>` 
2. Run Play Console upload flow using:
   - `docs/release/PLAY_CONSOLE_SUBMISSION_PACK_2026-07-04.md`
3. Run iOS handoff after macOS/Xcode access:
   - `scripts/store_release_build.ps1 -Target All -RunStrictAudit -SupportEmailVerified`
4. Re-run `verify_store_metadata.ps1` and `verify_web_deployment.ps1` if any public config changes.

## Useful evidence files to keep pinned

- `build/store-release-artifacts.json`
- `build/store-release-artifact-verification.json`
- `build/store-release-readiness-audit.json`
- `build/release-status-snapshot-final-cycle.md`
- `build/web-deployment-verification-final-check.json`
- `build/android-phone-smoke-final.json`
- `build/wear-emulator-smoke-final.json`
- `build/android-live-auth-smoke-final.json`
- `build/store-metadata-verification-final.json`
- `docs/release/FINAL_LAUNCH_EVIDENCE_2026-07-04.md`
- `docs/release/PLAY_CONSOLE_SUBMISSION_PACK_2026-07-04.md`
- `docs/STORE_METADATA_DRAFT.md`
