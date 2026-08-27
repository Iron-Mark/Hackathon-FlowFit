# AGENTS.md

## Maintained Fork Workflow

### Environment

- Use **Flutter SDK 3.41.9 stable** for CI/release verification; current local
  evidence uses Dart 3.11.5. The `pubspec.yaml` constraint `sdk: "^3.10.0"` is
  the Dart SDK constraint, not a Flutter version.
- Do not downgrade below the repo's CI toolchain without updating
  `.github/workflows/flutter-ci.yml`, release docs, and verification evidence.

### Key commands

| Task | Command |
|------|---------|
| Install deps | `flutter pub get` |
| Lint / analyze | `flutter analyze` |
| Format | `pwsh -NoProfile -File scripts/verify_dart_format.ps1` |
| Run all tests | `flutter test` |
| Run subset | `flutter test test/models/` |

See `README.md` and `.github/copilot-instructions.md` for full developer workflow details.

### Secrets

- Preferred release/local configuration is `--dart-define=SUPABASE_URL=...`
  and `--dart-define=SUPABASE_PUBLISHABLE_KEY=...`, or equivalent
  `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` environment values consumed by
  the release scripts.
- `lib/secrets.dart` is gitignored and is only an optional local fallback. When
  used, copy `lib/secrets.dart.example`; it exports `SupabaseConfig.url`,
  `SupabaseConfig.publishableKey`, and the deprecated
  `SupabaseConfig.anonKey` compatibility alias.
- Never put service-role, secret, or server-only Supabase keys in Flutter code
  or committed files.

### Current status

- Flutter web, Android phone, and Wear OS build paths ship on `main`.
- Parent-supervise copy covers landing, welcome, signup, login, email
  verification, password reset, delete account, and store metadata. The
  `/age-gate` is self-attested only and is not verifiable parental consent.
- GitHub Pages is live at
  `https://iron-mark.github.io/Hackathon-FlowFit/` (including `privacy.html`
  and `account-deletion.html`) as of 2026-08-26 on `0537627`. Pages deploy
  vars substitute a verified support inbox; committed source still uses the
  `support@flowfit.com` replacement token.
- CI keeps large web/Wasm/AAB smoke trees short-lived (failure or
  `workflow_dispatch` only). Weekly
  `.github/workflows/prune-ci-smoke-artifacts.yml` reclaims older copies.
- Store release remains blocked on owner inputs: independent live
  `verify_flowfit_backend.sql` evidence for
  `supabase/migrations/20260821000000_harden_support_deletion_and_auth.sql`
  (owner reported applying it on 2026-08-25), Supabase MCP OAuth or access
  token for live verify, dashboard auth email templates, mailbox smoke,
  Android upload signing, macOS/Xcode signing, and Families/Kids legal
  decision ([docs/FAMILIES_KIDS_OPTIONS.md](docs/FAMILIES_KIDS_OPTIONS.md)).
  Play internal testing steps:
  [docs/PLAY_INTERNAL_TEST_RUNBOOK.md](docs/PLAY_INTERNAL_TEST_RUNBOOK.md).
  Tracker: https://github.com/Iron-Mark/Hackathon-FlowFit/issues/10
- Run fresh `flutter analyze` and `flutter test` before reporting pass/fail.

### Running the app

This is a **Flutter app** targeting Android phone, Wear OS, and Flutter web.
The meaningful development loop is:

1. `flutter pub get` — install dependencies
2. `flutter analyze` — static analysis
3. `flutter test` — run unit/widget tests
4. `flutter build web --release --no-pub` — verify the default JavaScript web
   release path when Supabase Dart defines are supplied
   - Use `pwsh -NoProfile -File scripts/store_release_build.ps1 -Target Web -WebWasm`
     when the web handoff should produce a Flutter WebAssembly artifact.
5. `flutter build apk --debug --no-pub` — verify the Android phone path
6. `flutter build apk --debug -t lib/main_wear.dart --no-pub` — verify the
   Wear OS path
7. `pwsh -NoProfile -File scripts/verify_dart_format.ps1` — check tracked Dart formatting
