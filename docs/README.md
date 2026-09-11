# FlowFit Documentation

Start here for maintained-fork setup, verification, release, and feature notes.
Many older topic guides still live under `docs/`; prefer the hubs below for
current status. Dated packs in `docs/release/` are historical evidence only.

## Current hubs

- [Documentation index](INDEX.md) - living vs historical map
- [AGENTS.md](../AGENTS.md) - toolchain, Pages/CI status, store blockers
- [Quick start](QUICK_START.md) - local setup and common commands
- [Release readiness runbook](RELEASE_READINESS_RUNBOOK.md) - signing,
  Supabase, web, CI artifact retention, and store gates
- [Store submission checklist](STORE_SUBMISSION_CHECKLIST.md) - Play, App
  Store, and web checklist
- [Store metadata draft](STORE_METADATA_DRAFT.md) - listing copy
- [Supabase recovery runbook](SUPABASE_RECOVERY_RUNBOOK.md) - rebuilding the
  backend on a new Supabase project
- [Brand voice](brand-voice.md) - consumer copy rules

## Common local commands

```powershell
flutter pub get
pwsh -NoProfile -File scripts\verify_dart_format.ps1
dart analyze --format=machine
flutter analyze
flutter test --reporter compact
flutter build apk --debug --no-pub
flutter build apk --debug -t lib\main_wear.dart --no-pub
flutter build web --release --no-pub
```

The full Flutter test suite is serialized through the repo-level
`dart_test.yaml` so the documented `flutter test --reporter compact` command is
deterministic for the heavier widget and integration-style tests.

For the fast offline button, route, and feature-action smoke:

```powershell
pwsh -NoProfile -File scripts\verify_offline_app_actions.ps1
```

For a local web auth-route smoke after a configured web build:

```powershell
npm ci
npm run web:smoke -- --base-url http://127.0.0.1:8799 --out-file build\web-app-smoke-current.json
```

## Package notes

- Production Android package: `com.msiazondev.flowfit`
- Debug Android package: `com.msiazondev.flowfit.dev`
- Production auth scheme: configured through `FLOWFIT_AUTH_SCHEME`
- Local `lib/secrets.dart` stays ignored; use `lib/secrets.dart.example` for
  the required shape.

Device IDs in older docs are examples from previous local hardware sessions.
Always run `flutter devices` and `adb devices` for the current machine before
copying device-specific commands.
