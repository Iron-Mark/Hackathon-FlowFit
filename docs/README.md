# FlowFit Documentation

Start here for maintained-fork setup, verification, release, and feature notes.
Older historical implementation notes still exist in `docs/`, but the files
below are the current navigation surface.

## Current Hubs

- [Documentation index](INDEX.md) - full docs map by purpose.
- [Quick start](QUICK_START.md) - local setup and common commands.
- [Release readiness runbook](RELEASE_READINESS_RUNBOOK.md) - signing,
  Supabase, web, and store gates.
- [Supabase recovery runbook](SUPABASE_RECOVERY_RUNBOOK.md) - rebuilding the
  backend on a new Supabase project.
- [Codebase cleanup audit](maintenance/CODEBASE_CLEANUP_AUDIT_2026-06-19.md) -
  latest local verification evidence, hashes, and remaining blockers.
- [Play Store handoff](release/FINAL_RELEASE_HANDOFF_2026-06-19.md) - artifact
  and submission handoff notes.

## Common Local Commands

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

For the fast offline button, route, and feature-action smoke:

```powershell
pwsh -NoProfile -File scripts\verify_offline_app_actions.ps1
```

For a local web auth-route smoke after a configured web build:

```powershell
npm ci
npm run web:smoke -- --base-url http://127.0.0.1:8799 --out-file build\web-app-smoke-current.json
```

## Package Notes

- Production Android package: `com.msiazondev.flowfit`
- Debug Android package: `com.msiazondev.flowfit.dev`
- Production auth scheme: configured through `FLOWFIT_AUTH_SCHEME`
- Local `lib/secrets.dart` stays ignored; use `lib/secrets.dart.example` for
  the required shape.

Device IDs in older docs are examples from previous local hardware sessions.
Always run `flutter devices` and `adb devices` for the current machine before
copying device-specific commands.
