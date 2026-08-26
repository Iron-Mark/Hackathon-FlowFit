# Start here - FlowFit documentation

Welcome to the FlowFit docs. Prefer living hubs for status; older topic guides
remain for deep dives.

## You are here

```
flowfit/
├── README.md              ← Project overview
├── AGENTS.md              ← Toolchain, Pages/CI status, store blockers
└── docs/
    ├── 00_START_HERE.md   ← You are here
    ├── INDEX.md           ← Living vs historical map
    └── ...
```

## Quick paths

### Get started
1. [GETTING_STARTED.md](GETTING_STARTED.md) or [QUICK_START.md](QUICK_START.md)
2. [WATCH_TO_PHONE_COMPLETE_FLOW.md](WATCH_TO_PHONE_COMPLETE_FLOW.md) for sensor sync
3. [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if something breaks

### Release / store
1. [../AGENTS.md](../AGENTS.md) for current blockers
2. [RELEASE_READINESS_RUNBOOK.md](RELEASE_READINESS_RUNBOOK.md)
3. [STORE_SUBMISSION_CHECKLIST.md](STORE_SUBMISSION_CHECKLIST.md)

### Architecture
1. [ARCHITECTURE_DIAGRAM.md](ARCHITECTURE_DIAGRAM.md)
2. [architecture/ARCHITECTURE_REVIEW_2026-07-14.md](architecture/ARCHITECTURE_REVIEW_2026-07-14.md)
3. [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)

### Browse everything
Go to [INDEX.md](INDEX.md). Dated packs under `release/` and `BUILD_STATUS.md`
are historical snapshots.

## Essential docs

1. [RELEASE_READINESS_RUNBOOK.md](RELEASE_READINESS_RUNBOOK.md)
2. [WATCH_TO_PHONE_COMPLETE_FLOW.md](WATCH_TO_PHONE_COMPLETE_FLOW.md)
3. [PRIVACY_DATA_MAP.md](PRIVACY_DATA_MAP.md)
4. [brand-voice.md](brand-voice.md)

## Troubleshooting

1. [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. [INSTALLATION_TROUBLESHOOTING.md](INSTALLATION_TROUBLESHOOTING.md) - replace
   any `com.example.flowfit` examples with `com.msiazondev.flowfit`
3. [WATCH_CONNECTION_GUIDE.md](WATCH_CONNECTION_GUIDE.md)

## Commands

```bash
flutter pub get
pwsh -NoProfile -File scripts/fetch_fonts.ps1
flutter devices
adb devices
flutter run -d <watch-device-id> -t lib/main_wear.dart
pwsh -NoProfile -File scripts/run_phone.ps1
```

---

Last updated: 2026-08-26
