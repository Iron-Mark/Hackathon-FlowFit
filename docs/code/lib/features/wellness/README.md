# Wellness Feature — Mission Engine (Geofence)

This feature provides a unified geofence-based mission engine for wellness-focused features in FlowFit. It supports three primary mission types:

- Target (Fitness): Accumulate distance as users move away from a starting point; reach a target distance to complete the mission.
- Sanctuary (Mental): Reach a specific coordinate to trigger a mission "success" or journaling flow.
- Safety Net (Elderly): Alerts if the user steps outside a specified safety radius.

Core components:

- `GeofenceMission` (domain model) — mission metadata and runtime state
 - `GeofenceRepository` (data interface) — abstracts storage for missions
 - `PersistentGeofenceRepository` — SharedPreferences-backed storage used by the app's `/mission` route (via `geofenceRepositoryProvider`)
 - `InMemoryGeofenceRepository` — in-memory fallback used when no Riverpod `ProviderScope` is available (bare widget tests)
- `GeofenceService` — listens to device location, handles events, tracks progress, and emits `GeofenceEvent`s (entered, exited, targetReached, outsideAlert)
- `WellnessMapsPage` — `flutter_map` widget for creating, editing, and managing missions; shows markers and geofence circles

How to use

1. This feature uses `flutter_map` with the shared FlowFit map tile config. The
   default is CARTO Voyager. Override `FLOWFIT_MAP_TILE_URL_TEMPLATE` and
   optional `FLOWFIT_MAP_TILE_SUBDOMAINS` for a production tile provider.
2. Add the page via router: `GoRoute(path: '/wellness', builder: (ctx, state) => MapsPageWrapper())`
3. Persistent storage is wired by default: under a Riverpod `ProviderScope`, `MapsPageWrapper` reads the app-scoped `geofenceRepositoryProvider` (a `PersistentGeofenceRepository` backed by SharedPreferences). Without a scope it falls back to the in-memory repository.

Notes & Next Steps

- Background geofencing requires native implementations on Android/iOS.
 - Missions persist locally via SharedPreferences (`PersistentGeofenceRepository`). Swap in a local DB or cloud backend (e.g., Supabase) only if cross-device sync is needed.
- Add UI for editing existing Missions.
- Add local notifications to alert the user for safety net events or mission completions.
Wellness Mission Engine (Geofence)

Overview:
- This feature provides a single maps-based mission engine concentrating on geofencing logic.
- Goals:
  - Centralize geofence-driven experiences (fitness/mental health/safety) in one place.

Mission types:
- Target (Fitness): Track cumulative distance traveled while active. When `targetDistanceMeters` is reached, mission completes.
- Sanctuary (Mental Health): Represents a place users should reach. Entering the radius marks active success.
- Safety Net (Elderly/Emergency): If a user leaves the radius, the system raises an "outside" alert.

Files:
- `domain/geofence_mission.dart` — Model definitions (MissionType, GeofenceMission, LatLngSimple).
- `data/geofence_repository.dart` — In-memory repository for creative iteration and local testing.
- `services/geofence_service.dart` — Runs `geolocator` streams, detects enter/exit/alerts and emits events.
- `presentation/maps_page.dart` — Map UI with mission listing, creation by long-press, and basic interactions.
- `presentation/maps_page_wrapper.dart` — Helper wrapper that wires repository and service as `Provider` instances.

Integration:
- Add `MapsPageWrapper()` to your route (an example `/wellness` route is present in `lib/shared/navigation/app_router.dart`).
 - This feature uses `flutter_map` and the shared FlowFit tile provider config; do not point production builds at public `tile.openstreetmap.org`.
- Local persistence ships via `PersistentGeofenceRepository` + `geofenceRepositoryProvider`; replace with a local DB or Supabase-backed implementation only if cross-device sync is needed.

Notes:
- This implementation is foreground-only; background geofencing requires platform-specific work and is out-of-scope for this initial iteration.
 - Provided to be an accessible starting point for the Mission Engine described in the feature request.

Foreground Location Scope
-------------------------
Release builds currently use foreground location only. `GeofenceService`
updates mission state from the active `geolocator` position stream while the
app is open, and Android/iOS release manifests intentionally do not request
background location. Do not add background-geofence claims to store copy until
native Android/iOS registration and event delivery are implemented and tested on
real devices.
