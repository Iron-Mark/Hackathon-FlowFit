# FlowFit Documentation Index

Living docs for the maintained fork. Dated packs under `docs/release/` and
`.kiro/specs/` are historical snapshots, not current status.

## Start here

- [README.md](../README.md) - project overview and setup
- [AGENTS.md](../AGENTS.md) - agent workflow, toolchain, and current blockers
- [00_START_HERE.md](00_START_HERE.md) - short navigation paths
- [QUICK_START.md](QUICK_START.md) - local commands
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - common issues
- [brand-voice.md](brand-voice.md) - consumer copy rules (no em dashes)

## Release and store (current)

- [RELEASE_READINESS_RUNBOOK.md](RELEASE_READINESS_RUNBOOK.md) - signing,
  Supabase, web, CI smoke retention, and store gates
- [STORE_SUBMISSION_CHECKLIST.md](STORE_SUBMISSION_CHECKLIST.md) - Play, App
  Store, and Flutter web checklist
- [PLAY_INTERNAL_TEST_RUNBOOK.md](PLAY_INTERNAL_TEST_RUNBOOK.md) - Google Play
  internal testing upload for `com.msiazondev.flowfit`
- [STORE_METADATA_DRAFT.md](STORE_METADATA_DRAFT.md) - listing copy and review
  notes
- [PRIVACY_DATA_MAP.md](PRIVACY_DATA_MAP.md) - data inventory for store privacy
  labels; points to `ios/Runner/PrivacyInfo.xcprivacy`
- [SUPABASE_RECOVERY_RUNBOOK.md](SUPABASE_RECOVERY_RUNBOOK.md) - rebuild on a
  new Supabase project
- [scripts/README.md](scripts/README.md) - script reference, including
  `verify_store_metadata.ps1`, `verify_store_artifacts.ps1`, and
  `verify_offline_app_actions.ps1`

## Architecture

- [architecture/ARCHITECTURE_REVIEW_2026-07-14.md](architecture/ARCHITECTURE_REVIEW_2026-07-14.md)
- [architecture/PROFILE_UNIFICATION_PLAN_2026-07-20.md](architecture/PROFILE_UNIFICATION_PLAN_2026-07-20.md)
- [code/lib/ARCHITECTURE.md](code/lib/ARCHITECTURE.md)

## Presentation (`docs/presentation/`)

- [PRESENTATION_GUIDE_WATCH_AI_INTEGRATION.md](presentation/PRESENTATION_GUIDE_WATCH_AI_INTEGRATION.md)
- [SAMSUNG_TECHNOLOGIES_USED.md](presentation/SAMSUNG_TECHNOLOGIES_USED.md)
- [WEAR_OS_INTEGRATION_SUMMARY.md](presentation/WEAR_OS_INTEGRATION_SUMMARY.md)

## Features and implementation

- [features/](features/) - AI detection, wellness, share
- [implementation/](implementation/) - deeper implementation notes
- [code/lib/](code/lib/) - code-adjacent READMEs

## Historical snapshots (do not treat as current)

Keep for evidence; prefer the living docs above for status.

- [release/MVP_LAUNCH_READINESS_2026-07-02.md](release/MVP_LAUNCH_READINESS_2026-07-02.md)
- [release/FINAL_LAUNCH_EVIDENCE_2026-07-04.md](release/FINAL_LAUNCH_EVIDENCE_2026-07-04.md)
- [release/PLAY_CONSOLE_SUBMISSION_PACK_2026-07-04.md](release/PLAY_CONSOLE_SUBMISSION_PACK_2026-07-04.md)
- [release/RELEASE_HANDOFF_NEXT_ACTIONS_2026-07-04.md](release/RELEASE_HANDOFF_NEXT_ACTIONS_2026-07-04.md)
- [BUILD_STATUS.md](BUILD_STATUS.md) - June 2026 local recovery notes
- [audits/](audits/) and [qa/](qa/) - dated audits

## Scripts (`scripts/`)

Common release helpers: `fetch_fonts.ps1`, `release_preflight.ps1`,
`release_readiness_audit.ps1`, `verify_offline_app_actions.ps1`,
`verify_web_deployment.ps1`, `store_release_build.ps1`,
`verify_store_metadata.ps1`, `verify_store_artifacts.ps1`,
`verify_support_inbox.ps1`, `configure_supabase_mcp.ps1`,
`create_android_upload_keystore.ps1`, `export_android_signing_env.ps1`,
`create_ios_export_options.ps1`. Full list: [scripts/README.md](scripts/README.md).

## Quick paths

### Development

1. [../README.md](../README.md) and [QUICK_START.md](QUICK_START.md)
2. [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
3. Feature notes under [features/](features/)

### Release

1. [AGENTS.md](../AGENTS.md) current status
2. [RELEASE_READINESS_RUNBOOK.md](RELEASE_READINESS_RUNBOOK.md)
3. [STORE_SUBMISSION_CHECKLIST.md](STORE_SUBMISSION_CHECKLIST.md)

### Presentation

1. [presentation/PRESENTATION_GUIDE_WATCH_AI_INTEGRATION.md](presentation/PRESENTATION_GUIDE_WATCH_AI_INTEGRATION.md)

---

Last updated: 2026-08-27
