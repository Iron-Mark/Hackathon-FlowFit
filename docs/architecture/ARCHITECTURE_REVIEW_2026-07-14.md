# FlowFit Architecture Review — 2026-07-14

Multi-agent survey of all 211 `lib/` files (53,298 lines) plus the guard-test
constraint map, followed by staged, test-green refactoring. This document
records what the codebase looks like, what was changed, and the ranked
roadmap of what should change next.

## 1. Current state, by the numbers

| Subtree | Files | Lines | Share |
|---|---|---|---|
| lib/screens | 72 | 30,295 | 56.8% |
| lib/services | 26 | 5,508 | 10.3% |
| lib/features | 35 | 5,357 | 10.1% |
| lib/widgets | 16 | 2,882 | 5.4% |
| lib/models | 21 | 2,488 | 4.7% |
| lib/providers | 9 | 1,883 | 3.5% |
| lib/core | 11 | 1,654 | 3.1% |
| lib/presentation | 5 | 1,150 | 2.2% |
| lib/data + lib/domain | 9 | 937 | 1.7% |
| other (theme, utils, root) | 7 | 1,144 | 2.2% |

27 files exceed 500 lines; the largest are `flowfit_landing_page.dart`
(1,212), `wear_heart_rate_screen.dart` (1,153), `active_running_screen.dart`
(1,142), `features/activity_classifier/presentation/tracker_page.dart`
(1,078), and `health_screen.dart` (1,060).

### Four coexisting paradigms

1. **Route-centric `lib/screens/`** — dominant (57% of all code), backed by
   flat type buckets (`services/`, `models/`, `providers/`, `widgets/`).
2. **Feature-first `lib/features/*`** — only 3 of 9 feature dirs were real
   (`activity_classifier`, `wellness`, `yolo_camera`); the other 6 were
   `.gitkeep` scaffolds (removed in Stage 1).
3. **Clean-arch root A** — `lib/core/{config,data,domain,exceptions,utils}`
   (profile v2 stack).
4. **Clean-arch root B** — `lib/{data,domain,presentation}` (auth + profile
   v1 stack).

### Dependency health

- The directory-level import graph is a strict DAG — zero directory cycles.
- Exactly one file-level cycle exists: the `lib/models` workout-session SCC
  (`workout_session.dart` ⇄ `running/walking/resistance_session.dart`).
  It is **guard-mandated**: `supabase_workout_sessions_contract_test.dart`
  requires the polymorphic `case 'running'/'walking'/'resistance':` dispatch
  to live in `workout_session.dart`, so this cycle is accepted.
- DI composition lives in the presentation layer (`presentation/providers/
  providers.dart` + `profile_providers.dart` are the only importers of
  data-layer implementations).
- 19 screen files import `lib/services` directly, bypassing providers.
- `main.dart` imports 77 files and is the sole importer of 63 of them.

### State management

Three systems coexist: Riverpod (49 hand-written providers in 10 files),
the `provider` package (MultiProvider in `main.dart` and
`maps_page_wrapper.dart`), and raw `setState`/singletons
(`DatabaseService.instance`, static `NotificationService`, static
`DeepLinkHandler`). ~24 of the 49 Riverpod providers are pure DI wrappers.

The sharpest findings:

- **Two live `UserProfile` entities** (`lib/domain/entities/` 16 fields vs
  `lib/core/domain/entities/` 23 nullable fields) persisted to the **same
  Supabase table** by two repository stacks, plus a third direct writer in
  `buddy_onboarding_provider.dart`.
- `profileRepositoryProvider` declared twice with different types;
  `sharedPreferencesProvider` three times; buddy profile has three writers.
- Current user id is derived four independent ways; heart rate flows through
  five parallel paths; steps come from three inconsistent sources.
- Workout notifiers `dispose()` shared non-autoDispose services
  (`running_session_provider.dart:311-330`) — latent cross-session bug.
- `health_screen.dart` keeps water/meal/sleep logs in memory only.
- Geofence sanctuaries use an `InMemoryGeofenceRepository` recreated per
  visit — never persisted.

## 2. The guard-test constraint map (read before refactoring)

The release-guard suite pins large parts of the tree by literal path and
literal source text. Violating any of these fails CI:

- **Do not move/rename:** `lib/main.dart`, `lib/main_wear.dart`,
  `lib/secrets.dart(.example)`, `lib/core/config/flowfit_runtime_config.dart`,
  `lib/core/config/supabase_runtime_config.dart`, help/terms/settings/
  delete-account screens, `lib/data/repositories/{auth,profile}_repository.dart`,
  `lib/utils/deep_link_handler.dart`, `lib/models/{workout,running,walking,
  resistance}_session.dart`, the 9 files pinned by
  `workout_session_auth_user_test.dart`, and anything read by
  `release_guard_source_test.dart` setUpAll (~45 files).
- **main.dart content pins:** the literal `if (kDebugMode) ...{` gate (first
  occurrence splits release/debug routes for three scanner tests), route keys
  in exact `'/route':` syntax, `SupabaseRuntimeConfig.url/publishableKey/
  validate()`, no `secrets.dart` import, no `DebugRouteMenu` mount. Never
  introduce an earlier `if (kDebugMode)` in the file.
- **Route literals are quadruple-pinned** (main.dart map, pushing screen
  source, tests, and `verify_web_app_smoke.mjs` hash routes).
- **Ordering pins:** several tests assert `indexOf(A) < indexOf(B)` on raw
  source (e.g. `createSession` before `startTracking`), so reordering code
  in pinned files can fail guards without any rename.
- **Whole-directory guards:** no empty interaction handlers anywhere in
  `lib/`; every interactive file stem must be referenced by an action test
  (renames orphan coverage); no `.from('table')` literals outside
  `supabase_tables.dart`; every static pushNamed target must be a registered
  release route.
- **Never introduce a route-name constants class** used as map keys or at
  pushNamed call sites: the guard regexes match string literals only and
  would go silently vacuous (safety net destroyed with no failing test).

## 3. Executed stages (2026-07-14, all with the full 1,154-test suite green)

- **Stage 0 — import normalization.** All 521 relative import/export
  directives across 140 lib files converted to `package:flowfit/...` URIs
  (including multi-URI conditional exports). Makes every future file move a
  deterministic string rewrite and kills basename-collision ambiguity.
  Required updating two pinned import-string assertions in
  `test/providers/workout_session_auth_user_test.dart`.
- **Stage 1 — dead scaffolding + dead providers.** Removed the `.gitkeep`
  placeholder scaffolds (6 empty feature dirs, `lib/shared/*`,
  `lib/core/data/models`; landed via the feat/landing-buddy-and-links merge,
  plus the three redundant markers in populated `lib/core` dirs) and the
  three provably-unreferenced providers (`watchBridgeServiceProvider`,
  `wellnessHistoryProvider`, `manualSyncProvider`). `syncStatusProvider` and
  `pendingSyncCountProvider` are also unused by lib code but are overridden
  in four test files — left in place, flagged for the profile-stack
  unification.
- **Stage 2 — services subdomains.** `lib/services` (26 flat files) grouped
  into `sensors/`, `location/`, `workout/`, `backend/`, `storage/`,
  `wellness/` via `git mv` + repo-wide URI rewrite; the hard-coded path in
  `supabase_workout_sessions_contract_test.dart` updated.
- **Stage 3 — main.dart slimming (extraction shape A).** The
  activity-classifier MultiProvider DI block became
  `lib/app/activity_classifier_scope.dart` (`ActivityClassifierScope`) and
  the secret-redaction helper became `lib/app/startup_error_redactor.dart`
  (357 → 304 lines, provider-package imports out of main.dart).
  `ActivityClassifierScope` was later deleted outright when roadmap item 4
  landed (2026-07-21) — the chain lives in Riverpod providers now.
  `FlowFitPhoneApp`, the verbatim routes map, `buildRunningShareRoute`,
  `MissingWorkoutSessionScreen` (kept: it is exercised only via route text,
  so a new interactive file would trip the surface-coverage guard), and
  Supabase init stay in `main.dart` — zero guard edits needed.

## 4. Deferred roadmap (ranked; each item = one PR-sized effort)

1. **Unify the profile stack (highest value, semantic risk).** Pick the
   `lib/core` UserProfile (offline-first, nullable, kids-mode) as canonical;
   migrate `survey_notifier` off `lib/domain/entities/user_profile.dart` and
   `lib/data/repositories/profile_repository.dart`; route the buddy
   onboarding upsert through the same repository; collapse the duplicate
   `profileRepositoryProvider`/`supabaseClientProvider`/
   `sharedPreferencesProvider` declarations. Constraint: the retry
   expression `Future.delayed(Duration(milliseconds: 100 * attempts))` in
   `data/repositories/profile_repository.dart` is content-pinned — keep the
   file as a shim or update the guard in the same change.
2. **Single user-id + auth source.** Replace the three ad-hoc
   `Supabase.instance.client.auth.currentUser?.id` providers with one
   provider derived from `authNotifierProvider`.
3. **Consolidate wellness into `lib/features/wellness/`.** Today wellness is
   split across `features/wellness` (15 files), `screens/wellness` (3),
   `widgets/wellness` (6), `services/wellness*`, and a provider. Move
   screens/widgets/services under the feature; fix the geofence persistence
   gap (InMemoryGeofenceRepository) while there.
4. **Retire the `provider` package.** Convert the two MultiProvider sites
   (main.dart TFLite chain, maps_page_wrapper) to Riverpod; then only one
   state system remains beside plain setState.
5. **Split the god screens** (five files >1,000 lines) into
   screen + controller + section widgets. Do these one at a time; each is
   covered by action tests keyed to file stems, so split into NEW files while
   keeping the stem file as the screen shell.
6. **Fix the shared-service dispose bug** in the three workout notifiers
   (dispose of shared timer/GPS/HR services owned by non-autoDispose
   providers).
7. **Model hygiene quick wins:** rename one of the two `MissionType` enums;
   drop `LatLngSimple` for latlong2's `LatLng`; merge `heart_rate_data.dart`
   into `tracked_data.dart`; rename `models/permission_status.dart` to stop
   shadowing permission_handler.
8. **Optional — route-table extraction (shape B).** Move the routes map to
   `lib/app/routes.dart` keeping string keys and the exact
   `if (kDebugMode) ...{` text, updating the five hard-coded `lib/main.dart`
   scanner paths (`navigation_route_guard_test.dart:83/93/186`,
   `release_route_surface_test.dart:16`, smoke test:272). Low payoff until
   the god screens shrink; skip unless main.dart grows again.

### Execution status (updated 2026-07-21)

- **Item 1 — profile stack: executed 2026-07-20/21.** Stages 1–6 per
  `PROFILE_UNIFICATION_PLAN_2026-07-20.md`; the deferred
  `patchBackendProfile` repository member landed 2026-07-21 and the buddy
  onboarding write now routes through it.
- **Item 2 — single user-id source: executed 2026-07-20**
  (auth-reactive `currentUserIdProvider`).
- **Item 3 — wellness consolidation: resolved 2026-07-21 as a *logical*
  consolidation.** Guard pins anchor files in three of the four wellness
  locations, so the physical layout deliberately stays; the real defects
  shipped instead: geofence missions now persist
  (`GeofenceMissionStorage` + `PersistentGeofenceRepository` + app-scoped
  `geofenceRepositoryProvider` — previously destroyed on every screen
  exit), and the wellness history save/load round-trip was fixed
  (`Map.toString` written but query-string parsed; now JSON).
- **Item 4 — retire the provider package: executed 2026-07-21.** Wellness
  site via constructor injection, classifier chain via Riverpod
  (`ActivityClassifierScope` deleted, `main.dart` unwrapped), dependency
  removed from pubspec with the full suite green and a debug APK build as
  the Kotlin-compile proof.
- **Item 5 — god screens: executed 2026-07-20/21, all five.** landing,
  health, wear, tracker, and active-running each split into a shell (stem
  kept, pinned literals in place) plus public widgets under a sibling
  `widgets/` directory; active-running's detection pipeline extracted to
  `running_activity_detection.dart`.
- **Item 6 — shared-service dispose bug: executed 2026-07-15.**
- **Item 7 — model hygiene: largely executed 2026-07-15** (see the roadmap
  batch notes); leftovers are cosmetic.
- **Item 8 — route-table extraction: still deliberately skipped.**
- Also shipped 2026-07-21 beyond this roadmap: sync-queue dead-letter
  park/restore (R8) and the `isKidsMode` fromJson default aligned to true
  (R7's hazard half — the DB default/backfill remains a product decision).
- New follow-ups surfaced by the work: dead-letter store is not cleared on
  account deletion; `phoneDataListenerProvider` exists twice (classifier
  chain vs `running_session_provider`, kept deliberately via a `hide` to
  preserve two-instance semantics); the 320-sample buffer pipeline is still
  duplicated between tracker (inline) and running (extracted controller).

## 5. Standing conventions going forward

- All lib imports use `package:flowfit/...` form (Stage 0); keep it that way.
- New services go under a `lib/services/<subdomain>/`; new features get a
  `lib/features/<name>/` module only when code actually exists.
- Before moving/renaming ANY file, grep `test/scripts/`, `test/routes/`,
  `test/providers/workout_session_auth_user_test.dart`, and
  `scripts/verify_offline_app_actions.ps1` for its basename.
