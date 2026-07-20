import 'dart:collection';
import 'package:flowfit/features/wellness/data/geofence_repository.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';
import 'package:flowfit/services/storage/geofence_mission_storage.dart';

/// Geofence repository backed by [GeofenceMissionStorage].
///
/// Mirrors [InMemoryGeofenceRepository] semantics with a write-through to
/// SharedPreferences on every mutation so missions survive app restarts.
/// Persistence failures are swallowed best-effort: the in-memory cache is
/// the source of truth for the running session, and a storage hiccup must
/// never surface as an error while a kid is using the map.
class PersistentGeofenceRepository extends GeofenceRepository {
  PersistentGeofenceRepository(this._storage);

  final GeofenceMissionStorage _storage;
  final Map<String, GeofenceMission> _store = {};
  bool _hydrated = false;

  /// Load persisted missions once; subsequent calls are no-ops.
  ///
  /// The user's arm/disarm choice ([GeofenceMission.isActive]) round-trips
  /// faithfully, but every loaded mission's runtime status is forced back
  /// to [GeofenceStatus.unknown] so inside/outside is re-derived from live
  /// location instead of a stale snapshot.
  Future<void> hydrate() async {
    if (_hydrated) return;
    _hydrated = true;

    List<GeofenceMission> loaded;
    try {
      loaded = await _storage.loadMissions();
    } catch (e) {
      // Best-effort: treat unreadable storage as a fresh start.
      loaded = [];
    }

    for (final mission in loaded) {
      mission.status = GeofenceStatus.unknown;
      _store[mission.id] = mission;
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      await _storage.saveMissions(_store.values.toList());
    } catch (e) {
      // Best-effort: never let a storage failure break the session.
    }
  }

  @override
  Future<List<GeofenceMission>> getAll() async =>
      UnmodifiableListView(_store.values);

  @override
  List<GeofenceMission> get current => UnmodifiableListView(_store.values);

  @override
  GeofenceMission? getById(String id) => _store[id];

  @override
  Future<void> add(GeofenceMission mission) async {
    _store[mission.id] = mission;
    notifyListeners();
    await _persist();
  }

  @override
  Future<void> update(GeofenceMission mission) async {
    if (!_store.containsKey(mission.id)) return;
    _store[mission.id] = mission;
    notifyListeners();
    await _persist();
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
    notifyListeners();
    await _persist();
  }

  @override
  Future<void> clear() async {
    _store.clear();
    notifyListeners();
    await _persist();
  }
}
