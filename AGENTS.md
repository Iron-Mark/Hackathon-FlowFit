# AGENTS.md

## Cursor Cloud specific instructions

### Environment

- **Flutter SDK 3.44.0** (Dart 3.12.0) is installed at `/home/ubuntu/flutter`. PATH is configured in `~/.bashrc`.
- The project requires Dart SDK `^3.10.0` — do not downgrade to an older Flutter version.

### Key commands

| Task | Command |
|------|---------|
| Install deps | `flutter pub get` |
| Lint / analyze | `flutter analyze` |
| Format | `dart format .` |
| Run all tests | `flutter test` |
| Run subset | `flutter test test/models/` |

See `README.md` and `.github/copilot-instructions.md` for full developer workflow details.

### Secrets

- `lib/secrets.dart` is gitignored and must exist for compilation. It exports `SupabaseConfig.url` and `SupabaseConfig.anonKey`. A placeholder is created during setup; replace with real values to test Supabase-dependent flows.

### Known pre-existing issues

- `solar_icons` 0.0.5 extends `IconData` (a `final` class in newer Dart SDKs) — causes compilation failures in tests that import `main.dart`.
- `lib/screens/track/track_screen.dart` has syntax errors (unmatched brackets, undefined getters) that also cause compile failures.
- Several `const` constructor usages in `main.dart` are invalid with the current Dart SDK.
- These issues together cause ~42 test failures out of ~505 total tests. The remaining ~463 tests pass.

### Running the app

This is a **Flutter mobile app** targeting Android / Wear OS physical devices. There is no web or desktop entrypoint that can be run headlessly in the cloud VM. The meaningful development loop in this environment is:

1. `flutter pub get` — install dependencies
2. `flutter analyze` — static analysis
3. `flutter test` — run unit/widget tests
4. `dart format .` — check formatting
