# FlowFit Profile-Stack Unification — Staged Migration Plan

> **Status (2026-07-20): Stages 1–5 EXECUTED and green** (commits f04f923,
> f75e5df, 55c8119, 9afa9cb, 05b1fc1 — full suite green at every stage; the
> suite went 1,154 → 1,114 as Stack A's shape tests retired with their
> subjects). One deviation from this plan: SurveyNotifier's repository
> dependency was severed in Stage 3 instead of Stage 4, because the five
> re-pointed routing suites otherwise needed throwaway Stack A overrides.
> Stage 6 (buddy writer alignment + stale-replay guard) is deliberately NOT
> executed yet — it adds a repository member (fake/mock churn) and changes
> offline replay semantics, so it ships as its own session per the ordering
> rationale below.

Repo root: `C:\Codes Local\Hackathons (Workspace)\11-27-25 - FlowFit - OldStLabs`. All paths below are relative to it. Gate for every stage: `flutter test` — full 1,154-test suite green before merge.

---

## 1. Target architecture

### 1.1 One entity: Stack B's core `UserProfile` (`lib/core/domain/entities/user_profile.dart`), unmodified in shape

Stack B's entity wins outright; no merged shape is needed:

- **It can represent every real row.** The DB (`supabase/migrations/20260614062844_recreate_flowfit_backend.sql:36-68`) allows NULL for every body/survey column, and Buddy onboarding + the migration backfill *create* rows where full_name/age/gender/weight/height are NULL. Stack A's entity (10 required non-nullable fields) cannot represent those rows; its model coerces them to `age: 0, gender: '', weight: 0, height: 0`, which violates the `user_profiles_age_valid` / `gender_valid` / `weight_valid` / `height_valid` CHECK constraints on any write-back. Stack A is structurally incapable of round-tripping the table.
- **It covers all 21 client-writable columns** (incl. `nickname`, `wellness_goals`, `notifications_enabled`, `is_kids_mode`, which Stack A lacks entirely) and correctly never writes `created_at` (pinned by `test/core/domain/entities/user_profile_test.dart:212-243`), whereas Stack A stamps client `now()` into `created_at` on every upsert.
- **It carries the offline-first machinery** (`isSynced`, local persistence, sync queue) that production already depends on — the live survey-completion path is Stack B (`survey_daily_targets_screen.dart:230-244`, `survey_intro_screen.dart:432-438`).
- **Stack A's write path is dead code**: `SurveyNotifier.submitSurvey` / `createProfile` / `updateProfile` / `getProfile` have zero call sites in lib/ and test/. The only live Stack A behavior is 3 `hasCompletedSurvey` backend reads (splash/welcome/login routing), which is a one-method port.

Two entity quirks are carried forward deliberately (not silently changed): the constructor-vs-fromJson `isKidsMode` default mismatch (true vs false) and the handler forcing `isKidsMode: true` on survey completion — see Risk Register R7.

### 1.2 One repository: core `ProfileRepository` interface + `ProfileRepositoryImpl`

`lib/core/domain/repositories/profile_repository.dart` + `lib/core/data/repositories/profile_repository_impl.dart`, extended with one new method:

```dart
/// Backend-truth onboarding check (replaces Stack A's hasCompletedSurvey).
/// SELECT survey_completed FROM user_profiles WHERE user_id = ?; null row => false.
/// Throws BackendSyncException on network/backend failure (routing screens catch and
/// keep today's stay-on-splash / snackbar behavior).
Future<bool> hasCompletedSurveyOnBackend(String userId);
```

The existing `hasCompletedSurvey` (local-profile-exists, impl :475-492) keeps its semantics — routing must be backend truth (fresh install on a second device must route to /dashboard even with an empty local store, exactly as today). Implementation detail: read the column with `response?['survey_completed'] == true` — never `as bool` cast (the column is NOT NULL, but this also removes Stack A's cast-crash class of failure).

### 1.3 One DI wiring

End state:
- `lib/presentation/providers/profile_providers.dart` is the single home of `supabaseClientProvider`, `sharedPreferencesProvider`, `profileRepositoryProvider` (Stack B, `FutureProvider<ProfileRepository>`), `syncQueueServiceProvider`, `surveyCompletionHandlerProvider`, `profileNotifierProvider`, `syncStatusProvider`.
- `providers.dart` keeps only auth (`authRepositoryProvider`, `authNotifierProvider`) and `surveyNotifierProvider`, and its `export 'profile_providers.dart'` (line 12) stops being a shadowing trap because the local duplicates at :17 and :38 are deleted.
- `sharedPreferencesProvider` collapses from three declarations to one canonical + one thin alias (Stage 5).
- `lib/providers/current_user_id_provider.dart` (new) is the single auth-identity source.

### 1.4 One auth-reactive `currentUserIdProvider`

New file `lib/providers/current_user_id_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Raw Supabase auth events. Broadcast stream — coexists safely with the
/// existing listeners in deep_link_handler.dart:46 and email_verification_screen.dart:65.
final supabaseAuthEventsProvider = StreamProvider<AuthState>(
  (ref) => Supabase.instance.client.auth.onAuthStateChange,
);

/// Single source of truth for the signed-in user id. Rebuilds on every auth
/// event (INITIAL_SESSION / SIGNED_IN / SIGNED_OUT / TOKEN_REFRESHED), so it can
/// never cache a stale/null id for the process lifetime.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(supabaseAuthEventsProvider); // invalidation source
  return Supabase.instance.client.auth.currentUser?.id; // live read at rebuild
});
```

**Invalidation mechanism**: `ref.watch(supabaseAuthEventsProvider)` makes `currentUserIdProvider` rebuild whenever the stream emits; the body then performs a *live* read of `currentUser`. This fixes the confirmed null-poisoning (signed-out cold start caching null forever) and the user-A→user-B misattribution, with no manual subscription lifecycle to manage. It deliberately does NOT derive from `authNotifierProvider` (which requires splash-only `initialize()` and would couple workout providers to Stack A presentation).

**How the guard pins survive** (`test/providers/workout_session_auth_user_test.dart` — all pins are substring checks on file text):

`lib/providers/running_session_provider.dart:38-40` is rewritten *in place*, same name, same file, same `Provider<String?>` type:

```dart
final workoutSessionUserIdProvider = Provider<String?>((ref) {
  // Delegate to the auth-reactive source; the trailing live read keeps the
  // pre-first-emission window covered and is real executable code.
  return ref.watch(currentUserIdProvider) ??
      Supabase.instance.client.auth.currentUser?.id;
});
```

- Pin :38 `contains('workoutSessionUserIdProvider')` — name unchanged. ✅
- Pin :39-42 `contains('Supabase.instance.client.auth.currentUser?.id')` — the literal remains in running_session_provider.dart as live code (the `??` fallback), not a comment. ✅
- Pin :43 `contains('requireWorkoutSessionUserId')` and :45-55 `contains('requireWorkoutSessionUserId(_readCurrentUserId)')` in all three session providers — `requireWorkoutSessionUserId` (running_session_provider.dart:42-50) and the three notifier call sites are untouched. ✅
- Pin :25-33 `isNot(contains('current-user-id'))` across 9 files — no such string introduced. ✅
- The 4 `overrideWithValue` sites (`test/screens/workout/resistance_split_start_flow_test.dart:20,56,97`, `test/screens/workout/mission_creation_screen_actions_test.dart:122`) keep working because it remains a plain `Provider<String?>`; overridden instances never execute the body, so tests never touch `Supabase.instance`. ✅
- Consumers need zero changes: all three session notifiers inject `readCurrentUserId: () => ref.read(workoutSessionUserIdProvider)` (running:345, resistance:290, walking:241) — late-bound closures now see fresh values because the provider rebuilds on auth events.

`buddyCustomizationCurrentUserIdProvider` (`lib/providers/buddy_profile_provider.dart:9-11`, same poisoning bug) and `buddyPendingSyncUserIdProvider` (`lib/widgets/buddy_pending_sync_listener.dart:7-9`, inconsistently autoDispose) become one-line delegates: `Provider<String?>((ref) => ref.watch(currentUserIdProvider))`. Their `overrideWithValue` pins (`test/screens/profile/buddy_customization_screen_test.dart:154`, `test/app/flowfit_phone_app_navigation_smoke_test.dart:306`) survive because the type is unchanged.

---

## 2. Column-level data-safety analysis (the three write paths vs the real schema)

Schema: 23 columns; CHECKs enforced on new writes (added NOT VALID); `updated_at` owned by BEFORE UPDATE trigger; `is_kids_mode`/`survey_completed`/`notifications_enabled` NOT NULL with defaults; no `is_synced` column.

| Column | Stack A (dead writer) | Stack B `toSupabaseJson` (live) | Buddy upsert (live) | Hazard |
|---|---|---|---|---|
| user_id | ✔ | ✔ | ✔ | — |
| full_name | ✔ (`''` if missing) | ✔ incl. NULL | ✗ (omitted) | B NULLs it if unset locally |
| age | ✔ (`0` → CHECK violation) | ✔ incl. NULL | conditional (omitted when null) | A write fails on kids rows; B can NULL a Buddy-set age |
| gender / weight / height | ✔ (`''`/`0` → CHECK violations) | ✔ incl. NULL | ✗ | A constraint bombs; B NULL-clobber |
| height_unit / weight_unit / activity_level / goals / daily_* targets / profile_image_url | ✔ | ✔ incl. NULL | ✗ | B NULL-clobber of anything not in local copy |
| wellness_goals | ✗ | ✔ incl. NULL | conditional (empty list dropped) | **B replay NULLs Buddy's wellness_goals** |
| notifications_enabled | ✗ | ✔ as `?? false` — never null | conditional | **B silently writes `false` over Buddy's `true`** |
| nickname | ✗ (read-only fallback) | ✔ incl. NULL | conditional | **B replay NULLs Buddy's nickname** |
| is_kids_mode | ✗ (DB default false) | ✔ always (entity default true; handler forces true) | ✔ always `true` | tri-writer conflict; last writer wins (see R7) |
| survey_completed | ✔ | ✔ | ✔ always `true` | Buddy flips the routing flag unconditionally (pre-existing, pinned) |
| created_at | ✔ **client now() on every write — clobbers creation time** | ✗ (pinned excluded) | ✗ | fixed by deleting Stack A |
| updated_at | ✔ client now() | ✔ client now() (trigger overwrites on UPDATE) | ✗ (trigger sets) | mixed clocks; stale Buddy replay looks "newest" (R6) |

**The concrete clobber the plan must fix** (Stage 2): survey completes offline → Stack B profile (nickname=null, wellness_goals=null, notifications_enabled coerced false) sits in the global `'sync_queue'` → Buddy onboarding later sets nickname/wellness_goals/notifications_enabled → queue replays minutes later → `saveBackendProfile` upserts all 21 keys including the NULLs/false → **Buddy fields wiped**. Fix: strip null-valued keys from the backend payload at the single choke point `ProfileRepositoryImpl.saveBackendProfile` (impl:254-264 — the sync queue's `_syncItem` also funnels through it), and stop coercing `notifications_enabled` to false (make it nullable in the payload so it strips). Since the entity's `copyWith` never nulls fields and `updateField` never sets null, no legitimate "clear this column" flow is lost.

**Migration/backfill needed: none.** The schema is already a superset of the unified entity; no rows were ever created by the dead Stack A write path, so there is nothing to repair. `created_at` values already clobbered historically are unrecoverable and harmless (only display/analytics). RLS is per-user and unchanged.

---

## 3. Stages

Each stage is an independently shippable commit/PR with the full suite green.

### Stage 1 — Auth-reactive identity (`currentUserIdProvider`)

Lowest risk, zero schema impact, fixes a live bug (poisoned null user id) independently of the profile unification.

**Files changed**
- NEW `lib/providers/current_user_id_provider.dart` — `supabaseAuthEventsProvider` + `currentUserIdProvider` (code in §1.4).
- `lib/providers/running_session_provider.dart:38-40` — delegate body with `?? Supabase.instance.client.auth.currentUser?.id` fallback (keeps both pinned literals as live code).
- `lib/providers/buddy_profile_provider.dart:9-11` — `buddyCustomizationCurrentUserIdProvider` delegates to `currentUserIdProvider`.
- `lib/widgets/buddy_pending_sync_listener.dart:7-9` — `buddyPendingSyncUserIdProvider` delegates (drops the inconsistent autoDispose; nothing pins it).

**Tests**
- NEW `test/providers/current_user_id_provider_test.dart` — with `supabaseAuthEventsProvider` overridden by a controllable stream: (a) id is re-read after an emission (poisoned-null regression test: start null, emit, assert non-null via an overridable indirection or by asserting rebuild count), (b) `workoutSessionUserIdProvider` reflects `currentUserIdProvider` when the latter is overridden.
- Must stay green untouched: `test/providers/workout_session_auth_user_test.dart` (all substring pins satisfied by construction), `resistance_split_start_flow_test.dart:20,56,97`, `mission_creation_screen_actions_test.dart:122`, `buddy_customization_screen_test.dart:154`, `flowfit_phone_app_navigation_smoke_test.dart:306`.

**Guard pins affected**: none removed; every literal in `workout_session_auth_user_test.dart` remains verbatim in its pinned file.

**Rollback**: revert the single commit. No persisted data or wire format touched.

### Stage 2 — Harden the surviving write path (null-strip + queue test)

Do this *before* Stack B becomes the only writer, so the clobber window closes first.

**Files changed**
- `lib/core/domain/entities/user_profile.dart:151-175` — `toSupabaseJson`: change `'notifications_enabled': notificationsEnabled ?? false` to `notificationsEnabled` (nullable).
- `lib/core/data/repositories/profile_repository_impl.dart:254-264` — `saveBackendProfile`: `final payload = profile.toSupabaseJson()..removeWhere((_, v) => v == null);` before `.upsert(payload, onConflict: 'user_id')`. This single choke point covers direct saves, the survey handler, and every `SyncQueueService._syncItem` replay.
- (No change to `toJson` — local storage keeps full-fidelity nulls, pinned by `user_profile_test.dart:165-210`.)

**Tests to update / add**
- `test/core/domain/entities/user_profile_test.dart:245-255` — "notifications_enabled defaults to false" becomes "is null when unset" (and, if any toSupabaseJson test asserts `containsKey` for a null field, it still passes — key presence in `toSupabaseJson` is unchanged; only the repo strips).
- NEW `test/core/data/repositories/profile_repository_backend_payload_test.dart` — payload of a sparse profile contains no null-valued keys; contains `user_id`, `is_kids_mode`, `survey_completed`; never contains `created_at`.
- NEW `test/services/backend/sync_queue_service_test.dart` — first-ever unit test for `SyncQueueService`: enqueue replaces per-user item, replay calls `saveBackendProfile` then marks local `isSynced: true`, backoff `5s * 2^(retryCount-1)`, and the silent-discard-after-5 behavior documented as a pinned expectation (see R8 for the follow-up).
- Must stay green: `survey_completion_handler_test.dart` (asserts `toSupabaseJson()['survey_completed'] == true` — unaffected), `profile_repository_local_test.dart`, `profile_notifier_test.dart`.

**Guard pins affected**: none. The `Future.delayed(100 * attempts)` pin lives in Stack A's test and is untouched this stage.

**Rollback**: revert commit. Worst case while deployed: a field genuinely meant to be cleared isn't cleared server-side — no flow does this today, so effectively risk-free; reverting restores byte-identical old payloads.

### Stage 3 — Route onboarding reads onto the unified repository

**Files changed**
- `lib/core/domain/repositories/profile_repository.dart` — add `Future<bool> hasCompletedSurveyOnBackend(String userId);` (§1.2).
- `lib/core/data/repositories/profile_repository_impl.dart` — implement: `.from(SupabaseTables.userProfiles).select('survey_completed').eq('user_id', userId).maybeSingle().timeout(10s)`; `row == null → false`; `row['survey_completed'] == true`; map errors to `BackendSyncException` like its siblings.
- `lib/presentation/notifiers/profile_notifier.dart:336` region — add the method to `_UnavailableProfileRepository` (throws, like every other member).
- `lib/screens/splash_screen.dart:121-123`, `lib/screens/auth/welcome_screen.dart:40-42`, `lib/screens/auth/login_screen.dart:80-82` — replace `ref.read(profileRepositoryProvider).hasCompletedSurvey(...)` with `(await ref.read(profile_providers.profileRepositoryProvider.future)).hasCompletedSurveyOnBackend(...)` (all three call sites are already async; import with the existing `as profile_providers` prefix convention). Error handling is unchanged: any throw hits the existing catch blocks (splash retry UI at :100-107; welcome/login snackbars). Also switch `login_screen.dart:130`'s `supabaseClientProvider` usage to the profile_providers one (same body) to sever the last Stack A provider read.

**Tests to update** (swap the fake's target provider; assertions unchanged)
- `test/screens/splash_screen_test.dart:118` (+ fake at :183-214) — fake now implements core `ProfileRepository` (or extends a small shared `_FakeCoreProfileRepository` stubbing `hasCompletedSurveyOnBackend`), overriding `profile_providers.profileRepositoryProvider.overrideWith((ref) async => fake)`. Route assertions (:20-29 dashboard, :32-44 age-gate + userId arg, :46-75 error/retry) unchanged.
- `test/screens/auth/welcome_screen_actions_test.dart:21`, `test/integration/login_flow_test.dart:187`, `test/integration/auth_flow_test.dart:87` (fake :221-243), `test/app/flowfit_phone_app_navigation_smoke_test.dart:305` (fake :383) — same mechanical swap. Note the last two *also* already override the Stack B provider in places — consolidate to one override.
- NEW: repo-level unit test for `hasCompletedSurveyOnBackend` null-row/false/true/error mapping (mock client or source-shape test consistent with the repo's existing test style).
- Mockito codegen: `test/screens/profile/profile_refresh_*_test.mocks.dart` pin the full core interface via `@GenerateMocks([ProfileRepository])` — **re-run `build_runner`** in this stage (interface gained a method).

**Guard pins affected**: none. Stack A source is untouched, so `profile_repository_test.dart` still passes; `release_guard_source_test.dart:1712-1721` ('user_profiles' in backend SQL) unaffected.

**Rollback**: revert commit; screens fall back to Stack A reads (still present until Stage 4 — this ordering is why deletion is a separate stage).

### Stage 4 — Delete Stack A (entity, model, repo, interface, dead write path, duplicate providers)

After Stage 3, Stack A has zero production call sites; only `surveyNotifierProvider`'s vestigial constructor dependency instantiates it.

**Files changed/deleted**
- `lib/presentation/notifiers/survey_notifier.dart` — remove the `IProfileRepository` field, the constructor parameter, and dead `submitSurvey` (:259-324). SurveyNotifier becomes the pure SharedPreferences-backed form-state holder it already is in practice (loadSurveyData/updateSurveyData/validators/reset untouched).
- `lib/presentation/providers/providers.dart` — `surveyNotifierProvider` (:62-66) constructs `SurveyNotifier()`; DELETE local `profileRepositoryProvider` (:38-41) and local `supabaseClientProvider` (:17-19) — after deletion, the `export 'profile_providers.dart'` (:12) transparently supplies the identical `supabaseClientProvider` to existing importers (auth wiring keeps working; the shadowing trap dies).
- DELETE `lib/domain/entities/user_profile.dart`, `lib/data/models/user_profile_model.dart`, `lib/data/repositories/profile_repository.dart`, `lib/domain/repositories/i_profile_repository.dart`.

**Tests to delete (in the same commit as their subjects — this is the pin resolution)**
- `test/data/repositories/profile_repository_test.dart` — **this is the explicit disposition of the `Future.delayed(Duration(milliseconds: 100 * attempts))` pin (:41-46)**: the pin is a source-text assertion on a retry path that nothing has ever executed in production; it is deleted together with `lib/data/repositories/profile_repository.dart` in one commit so the guard never observes source-without-test or test-without-source. It is NOT in `release_guard_source_test.dart` (verified: that file's nearest pins are the survey_back_navigation filename at :2461 and the user_profiles SQL list at :1712-1721), so no release-guard edit is needed. The retry behavior worth keeping (bounded retries + backoff) already exists in the surviving stack as SyncQueueService's tested backoff (Stage 2's new test).
- `test/domain/entities/user_profile_test.dart` (~45 Stack A shape tests), `test/data/user_profile_model_test.dart` (Buddy partial-row parsing — the scenario stays covered by core `user_profile_test.dart`'s snake_case/missing-optionals cases :99-145).

**Tests to update** (they override Stack A's provider only to feed SurveyNotifier — drop the override, keep every assertion)
- `test/integration/survey_back_navigation_test.dart:36-54` (do NOT rename this file — `release_guard_source_test.dart:2461` pins the filename in the offline smoke manifest), `test/integration/profile_onboarding_integration_test.dart:81-100`, `test/screens/onboarding/survey_basic_info_actions_test.dart:193`, `test/screens/onboarding/survey_measurements_activity_actions_test.dart:457-495` — remove the Stack A `profileRepositoryProvider.overrideWithValue(...)` lines and any now-unused fake classes/imports; the Stack B override blocks stay. All surveyData assertions (:106-108/:161-165/:202-215; :47-51; :81-87/:118-124/:213 etc.) are untouched.

**Guard pins affected**: backoff pin retired with its file (above); `release_guard_source_test.dart:2461` respected by not renaming; `survey_named_route_contract_test.dart` unaffected (screens' navigation untouched).

**Rollback**: single `git revert` restores all four lib files + three test files; no data migration to unwind (the deleted code wrote nothing in production).

### Stage 5 — DI consolidation (one wiring)

**Files changed**
- NEW `lib/providers/shared_preferences_provider.dart` — canonical `sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw StateError('Override in main/tests'))`.
- `lib/main.dart:121` — override the canonical provider (it already awaits the instance for the wellness override; same value, one override).
- `lib/providers/wellness_state_provider.dart:222` — delete the local declaration; import the canonical (consumers unchanged — same sync type).
- `lib/providers/buddy_offline_storage_provider.dart:6` — delete the local FutureProvider; the storage provider reads the canonical sync provider.
- `lib/presentation/providers/profile_providers.dart:17` — keep the name/type for override compatibility but delegate: `FutureProvider<SharedPreferences>((ref) async => ref.watch(sharedPreferencesProvider))` — existing `.overrideWith` test sites keep working; prod resolves via main's override instead of a second `getInstance()`.

**Tests**
- Audit every test constructing widgets that transitively read prefs without overriding a repo/notifier: buddy onboarding/offline tests and any wellness widget tests must add `sharedPreferencesProvider.overrideWithValue(mockPrefs)` (they already use `SharedPreferences.setMockInitialValues`, so this is mechanical). Grep targets: `buddy_offline_storage`, `wellness_state_provider`, `sharedPreferencesProvider.overrideWith` across test/.
- `test/screens/delete_account_flow_test.dart:42-58` — unaffected (pins delete_account_screen source strings `user_profile_$userId` / `sync_queue_$userId` / `survey_data`, none of which change; local key formats are frozen throughout this plan).

**Guard pins affected**: none.

**Rollback**: revert commit; three independent prefs providers return. This stage is pure wiring — split it further (wellness first, buddy second) if the test churn is larger than expected.

### Stage 6 (recommended follow-up) — Buddy writer alignment + stale-replay guard

Fold the third writer under the one repository and close the stale-replay hole:

- `lib/providers/buddy_onboarding_provider.dart:423-443` — route the upsert through `ProfileRepositoryImpl` via a new `Future<void> patchBackendProfile(Map<String, dynamic> partialPayload)` (semantics identical to today's partial upsert; after Stage 2 the main save path is also effectively a patch, so the two writers finally share retry/timeout/error mapping).
- Stale-replay guard in `syncPendingProfile` (:375-403): before replaying a persisted `BuddyOnboardingState`, fetch the backend row's `updated_at`; skip (and clear) the pending payload if the row was updated after the payload was queued — this defuses the "DB trigger makes the stale replay look newest" laundering described in the writers-auth report.
- **Tests to update in the same commit**: `test/providers/buddy_onboarding_profile_key_test.dart` (pins exact payload map :46-54, `onConflict: 'user_id'`, `survey_completed: true`, and replay-before-clear ordering :82-108) — payload content assertions survive; the call-shape assertions move to the repo method.
- Rollback: revert; Buddy returns to its self-contained upsert, which is still safe post-Stage 2.

---

## 4. Test strategy summary

| Stage | Primary safety net |
|---|---|
| 1 | Source-pin suite `workout_session_auth_user_test` (unchanged, passes by construction) + new provider invalidation unit test + 6 existing overrideWithValue widget suites prove type compatibility |
| 2 | Entity toSupabaseJson tests + new payload-strip repo test + first SyncQueueService unit test; `survey_completion_handler_test` proves survey semantics unchanged |
| 3 | The 5 routing suites (splash/welcome/login/auth-flow/nav-smoke) re-pointed but asserting identical routes/snackbars/retry UI; mockito regen compiles or the stage fails fast |
| 4 | Compiler (deleted symbols cannot be referenced), 4 updated survey suites re-assert form-state behavior without Stack A, release_guard filename pin :2461 still satisfied |
| 5 | Full suite (any missed prefs consumer throws StateError loudly in tests, not silently) |
| 6 | buddy_onboarding_profile_key_test updated payload/ordering pins + new stale-replay test |

Every stage ends with `flutter test` (all 1,154) and `flutter analyze`.

---

## 5. Risk register

| # | Risk | Blast radius | Which stage's tests catch it |
|---|---|---|---|
| R1 | `currentUserIdProvider`'s StreamProvider touches `Supabase.instance` in a widget test that never initialized Supabase and forgot an override | Test-only crash; prod unaffected | Stage 1: full-suite run — any un-overridden consumer fails loudly with the Supabase-not-initialized error; the 6 known override sites are enumerated above |
| R2 | Null-strip (Stage 2) changes server state for a flow that *relied* on null-overwrite (none found — copyWith/updateField cannot produce nulls) | A field that should have been cleared persists | Stage 2 payload test documents the new contract; profile_notifier/handler tests prove all live flows unchanged |
| R3 | `hasCompletedSurveyOnBackend` behaves differently from Stack A's read under edge conditions (missing row, backend NULL, network error) | Wrong route at login/splash (dashboard vs age-gate) — highest user-visible blast radius in the plan | Stage 3: the 5 routing suites pin all three outcomes incl. error UI (splash_screen_test :20-75, login_flow_test :118-159, welcome :88-104); new repo unit test pins null-row→false |
| R4 | Stage 4 deletion breaks a hidden Stack A consumer (import via `providers.dart` shadowing) | Compile failure — zero runtime risk | Compiler + full suite; the grep audit in this plan found only the enumerated sites (providers.dart, survey_notifier, the 3 routing screens fixed in Stage 3, login's supabaseClientProvider) |
| R5 | Deleting `profile_repository_test.dart` removes the only pin on retry/backoff behavior anywhere | None functionally (the pinned path was dead), but retry coverage regresses | Stage 2's new SyncQueueService test lands *before* Stage 4, so the surviving stack's backoff is pinned first |
| R6 | Buddy stale replay still clobbers newer edits until Stage 6 ships | nickname/age/wellness_goals/notifications_enabled reverted to onboarding-time values on cold start | Pre-existing behavior, unchanged by Stages 1–5 (explicitly out of their blast radius); Stage 6's replay-guard test pins the fix |
| R7 | `is_kids_mode` semantics remain incoherent (survey handler forces true at survey_completion_handler.dart:70; entity constructor default true vs fromJson false; Buddy forces true; DB default false) — this plan deliberately preserves it | Adult/kids dashboard tab selection depends on last writer | Not fixed here: it is a product decision, not a refactor. Flagged for a dedicated change with its own tests (dashboard_initial_tab_property_test and handler tests currently pin today's behavior, so any accidental change in Stages 2–4 fails those suites) |
| R8 | SyncQueueService still silently discards after 5 retries (local left isSynced:false, nothing re-enqueues) | Backend copy of one profile silently stale | Stage 2's new test pins the current discard so any future fix is deliberate; recommended follow-up: re-enqueue on next app start from `hasPendingSync` |
| R9 | Stage 5 prefs consolidation misses a consumer that self-initialized prefs | StateError at first read — loud, immediate | Stage 5 full-suite run; the throwing canonical provider is designed to fail fast rather than silently self-init |
| R10 | Mockito codegen drift after interface change (Stage 3) | profile_refresh_*_test compile failures | Caught at analyze/compile in Stage 3; build_runner step is listed in the stage |

Ordering rationale: Stage 1 is independent and fixes a live bug; Stage 2 closes the data-clobber window *before* Stack B becomes the sole writer; Stage 3 moves reads before Stage 4 deletes their old source (so a Stage 3 revert always has a working fallback); Stage 5 is pure wiring with no schema exposure; Stage 6 is the only stage touching Buddy's pinned payload and is isolated so its test churn cannot destabilize the deletion stages.