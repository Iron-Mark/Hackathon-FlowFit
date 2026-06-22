# Copilot / AI Agent Instructions for FlowFit

This file gives concise, actionable guidance to AI coding agents working on FlowFit. Keep edits short and focused — this project prioritizes robust watch ↔ phone sensor data, native Samsung Health integration, and Supabase sync.

## Big picture (what matters)
- FlowFit is a Flutter app with two entry points:
  - `lib/main_wear.dart` — Galaxy Watch (Wear OS) UI and sensors
  - `lib/main.dart` — Android Phone companion UI
- The maintained-fork production Android package/auth scheme is `com.msiazondev.flowfit`.
- Native Android code handles Samsung Health SDK, then sends data to Flutter via MethodChannel/EventChannel:
  - Flutter -> Android MethodChannel (watch): `com.flowfit.watch/data`
  - Android -> Flutter EventChannel (watch heart rate): `com.flowfit.watch/heartrate`
  - Phone listener channels: `com.flowfit.phone/data` and `com.flowfit.phone/heartrate` (Flutter # side)
- Native manager implementation is in `android/app/src/main/kotlin/com/msiazondev/flowfit/HealthTrackingManager.kt` and the Flutter bridge is `lib/services/watch_bridge.dart`.
- Data flows:
  - Sensor reading (native Samsung Health) -> HealthTrackingManager -> EventChannel -> Flutter `WatchBridgeService` -> UI / Supabase
  - Watch messages can transfer via Wearable Data Layer to the Phone app which uses `PhoneDataListener` to receive data
- Supabase backend sync uses the canonical recovery schema and the `SupabaseService` class in `lib/services/supabase_service.dart`. Prefer `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` via Dart defines or ignored `.env.release`; `lib/secrets.dart` remains an ignored local fallback using the same publishable key shape.

## Feature-first Clean Architecture (strongly recommended)
- This repo's features are best implemented and extended using a feature-first, clean architecture approach: group code by feature rather than by layer. This keeps changes localized, makes code review easier, and helps map features across platform, domain, and data layers.
- For each new feature (e.g., heart_rate / sleep / workout / nutrition): create `lib/features/<feature>/` with the following suggested structure:
  - `domain/` – Use-cases, business logic (pure Dart), domain models/interfaces
  - `data/` – Repositories, data sources (Supabase, local storage), DTOs and mappers
  - `platform/` – Platform-specific implementations (watch bridge wrappers, method channel integration) and native bindings
  - `presentation/` – Widgets, screens, view models, providers
  - `test/` – Unit and integration tests for the feature
- Example: Heart rate feature layout (recommended):
  - `lib/features/heart_rate/domain/heart_rate_usecases.dart`
  - `lib/features/heart_rate/data/heart_rate_repository.dart` (exposes an interface `HeartRateRepository` and a `SupabaseHeartRateRepository` implementation)
  - `lib/features/heart_rate/platform/watch_bridge_impl.dart` (implements `HeartRateRepository` by delegating to `WatchBridgeService`)
  - `lib/features/heart_rate/presentation/heart_rate_screen.dart`
  - `test/features/heart_rate/` – tests for domain/usecase and platform mocks
- Map current files into the feature-first approach:
  - `lib/models/heart_rate_data.dart`, `lib/services/watch_bridge.dart` and the native `HealthTrackingManager.kt` are part of the **heart_rate** feature; new work should favor `lib/features/heart_rate/` locations while keeping private/shared models in `lib/models/` when used across features.
  - `lib/services/supabase_service.dart` is a cross-cutting data provider — expose a `Repository` interface per feature and implement it through `supabase_service.dart` or `lib/features/<feature>/data/supabase_repository.dart`.

### Why feature-first? (Practical reasons for this repo)
- Sensor features (heart-rate, sleep, workout) require platform and domain logic tied to a single product concern. Grouping them by feature reduces cross-file changes and limits native platform plumbing to a single place.
- Tests become focused: unit tests for domain logic can run in CI without mocking platform channels, and platform-specific tests are isolated under the feature's `test/` folder.
- When refactoring native code, a feature boundary maps directly to the native class (`HealthTrackingManager`) and Flutter bridge (`WatchBridgeService`). This reduces accidental coupling.

## Key files to review before making changes
- Flutter entry points: `lib/main.dart`, `lib/main_wear.dart`
- Flutter bridging and services: `lib/services/watch_bridge.dart`, `lib/services/phone_data_listener.dart`, `lib/services/supabase_service.dart`
- Android native integration: `android/app/src/main/kotlin/com/msiazondev/flowfit/MainActivity.kt`, `HealthTrackingManager.kt`
- Models: `lib/models/heart_rate_data.dart`, `lib/models/sensor_status.dart`, `lib/models/sensor_error.dart`
- UI grouped by platform: `lib/screens/wear/` (watch) and `lib/screens/` (phone)
- Tests: `test/services/watch_bridge_test.dart` (use as canonical example for mocking Method/Event channels)
- Useful docs: `docs/QUICK_START.md`, `docs/WEAR_OS_SETUP.md`, `README.md` and the `scripts/` folder

## Developer workflows & commands (do this first)
- Install dependencies: `flutter pub get`
- Run watch app (watch must be connected, watch-specific entry):
  - `flutter run -d <watch-device-id> -t lib/main_wear.dart` or `scripts\run_watch.bat`
- Run phone app:
  - `flutter run -d <phone-device-id> -t lib/main.dart` or `scripts\run_phone.bat`
- Build & install (automated): `scripts\build_and_install.bat`
- Run unit tests: `flutter test` (or `flutter test test/services/watch_bridge_test.dart`) – tests rely on `TestDefaultBinaryMessengerBinding` for channel mocking
- Static analysis: `flutter analyze` and code format with `dart format .`

### Testing guidance
- Follow `test/services/watch_bridge_test.dart` as the canonical example for mocking MethodChannel and EventChannel interactions.
- Use `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler` and `setMockStreamHandler`.
- Add tests for error mapping: PlatformException -> SensorError and for invalid stream payloads.

## Conventions & implementation patterns
- Always use `MethodChannel` for request/response and `EventChannel` for streaming sensor data. See `WatchBridgeService` and `MainActivity.kt` for exact naming and method names.
  - Methods exposed via `com.flowfit.watch/data`:
    - `requestPermission`, `checkPermission`, `connectWatch`, `disconnectWatch`, `isWatchConnected`, `startHeartRate`, `stopHeartRate`, `getCurrentHeartRate`
- Error mapping: Platform exceptions are mapped to a `SensorError` with `SensorErrorCode` (e.g., `PERMISSION_DENIED`, `SERVICE_UNAVAILABLE`, `TIMEOUT`). Ensure new platform errors are mapped accordingly.
- Use `Logger` package for debug output instead of prints; follow `WatchBridgeService` for logger setup.
- Heart rate JSON format: Use `HeartRateData` model {@see lib/models/heart_rate_data.dart}; `timestamp` uses epoch milliseconds, `status` is `SensorStatus` or a string.
- Tests for channels: Use `TestDefaultBinaryMessengerBinding` with `setMockMethodCallHandler` and `setMockStreamHandler` like `test/services/watch_bridge_test.dart`.

### Implementation conventions (feature-first)
- Domain logic (pure Dart) must live under `lib/features/<feature>/domain` and must **not** depend on platform code or Flutter UI. Keep it pure so it can be unit-tested easily.
- Repositories are interfaces (abstract classes) in `domain/` and implemented in `data/` or platform-specific folders. When accessing platform features (e.g., sensors), the repository implementation should inject a platform adapter.
- Platform adapters wrap `MethodChannel`/`EventChannel` and should be implemented in `lib/features/<feature>/platform/` and/or in `lib/services/` if shared across features (e.g., `watch_bridge.dart`).
- UI code must be under `lib/features/<feature>/presentation` and rely on domain use-cases and provider/view-model patterns (the repo uses `Provider`).

## Native Android notes
- `HealthTrackingManager` handles Samsung Health SDK and sends heart-rate data via EventChannel sink (`com.flowfit.watch/heartrate`). If you add new features requiring native changes:
  - Update `HealthTrackingManager.kt` and add method handlers in `MainActivity.kt`.
  - Add or update AAR dependencies in `android/app/libs` and `android/app/build.gradle.kts`.
  - Keep AndroidManifest permission declarations: `BODY_SENSORS`, `FOREGROUND_SERVICE`, `WAKE_LOCK`, `ACTIVITY_RECOGNITION`.
- When changing permissions flow, ensure `MainActivity.kt` `requestPermission` and `onRequestPermissionsResult` behavior is honored and tests updated.

## Supabase & secrets
- Never commit Supabase service-role keys, secret keys, database passwords, or `lib/secrets.dart`.
- Preferred local/release inputs are `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`, passed through Dart defines by `scripts/store_release_build.ps1`.
- For local fallback only, copy `lib/secrets.dart.example` to ignored `lib/secrets.dart` and populate the Project URL plus publishable key from the Supabase dashboard.
- Schema changes belong in `supabase/migrations/20260614062844_recreate_flowfit_backend.sql` or a new Supabase CLI-created migration, with docs/runbooks updated in the same change.
- `SupabaseService` in `lib/services/supabase_service.dart` is implemented for the current `heart_rate` table; keep table names aligned with the canonical migration and add tests when changing sync behavior.

## Common pitfalls for autopilot changes
- Watch vs Phone entrypoints: Always use `-t lib/main_wear.dart` for watch; otherwise you may run phone UI incorrectly on watch devices.
- ADB device ids change; prefer `adb devices` to verify and update `scripts/run_*.bat` if needed.
- Do not commit secrets to repository. Follow `.gitignore` for `lib/secrets.dart`, `.env.release`, Android upload keys, and Apple signing files.
- Event streaming expects non-null field `timestamp` and `status` formats; malformed JSON from native will break `HeartRateData.fromJson` — follow the model format exactly.

- Native changes often require updates to tests with mocked MethodChannel handlers. If you add a new method channel method, add a corresponding mock handler in `test/services/*`.

## How to implement a new sensor-backed feature
Follow feature-first steps below as an alternative to the 'generic' flow above:
1. Create `lib/features/<feature>/domain` — define interfaces and use-cases (e.g., `StartHeartRateUseCase`, `GetLatestHeartRate`), and domain models.
2. Create `lib/features/<feature>/data` — implement an interface `HeartRateRepository` and a `SupabaseHeartRateRepository` if persistence is required. Add DTOs and mapping functions.
3. Create `lib/features/<feature>/platform` — adapter(s) for `WatchBridgeService` or `MainActivity.kt` method channel. Keep `MethodChannel` and `EventChannel` in one place in the feature.
4. Create `lib/features/<feature>/presentation` — screens, widgets, and view models that use the domain use-cases.
5. Add unit tests under `test/features/<feature>/` for domain logic and platform integration tests that mock channels.
6. Wire the new feature into the app by providing the repository implementations using existing `Provider` patterns.

### Migration Note
- This repo currently has `lib/models/` and `lib/services/` with cross-cutting modules. When moving to feature-first, don't immediately refactor everything; instead:
  - Add new features under `lib/features/` and implement feature-local repositories that wrap existing code in `lib/services/`.
  - Over time, refactor shared services into per-feature adapters (e.g., keep `supabase_service.dart` but implement `FeatureRepository` on top of it).
  - Update tests to reference the feature folder tests to ensure behavior parity.

## Helpful examples
- See `test/services/watch_bridge_test.dart` — canonical tests for method channel behavior and event streams.
- See `android/app/src/main/kotlin/com/msiazondev/flowfit/MainActivity.kt` — method names and EventChannel usage directly correspond to Flutter service methods.

---
If anything in these instructions is unclear, incomplete, or you want more examples (e.g., expand test examples or add CI steps), please ask and I will refine the file.
