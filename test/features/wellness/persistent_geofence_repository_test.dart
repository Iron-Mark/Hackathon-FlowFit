import 'dart:convert';

import 'package:flowfit/features/wellness/data/persistent_geofence_repository.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';
import 'package:flowfit/services/storage/geofence_mission_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage stub whose reads and writes always fail, to prove the repository
/// swallows persistence errors best-effort.
class _ThrowingStorage extends GeofenceMissionStorage {
  _ThrowingStorage(super.prefs);

  @override
  Future<void> saveMissions(List<GeofenceMission> missions) async {
    throw StateError('disk full');
  }

  @override
  Future<List<GeofenceMission>> loadMissions() async {
    throw StateError('read failed');
  }
}

GeofenceMission _mission(String id, {bool isActive = false}) =>
    GeofenceMission(
      id: id,
      title: 'Mission $id',
      center: const LatLng(14.5995, 120.9842),
      radiusMeters: 60.0,
      type: GeofenceMissionType.sanctuary,
      isActive: isActive,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<GeofenceMissionStorage> newStorage() async =>
      GeofenceMissionStorage(await SharedPreferences.getInstance());

  test('add survives a restart into a fresh repository', () async {
    final repo = PersistentGeofenceRepository(await newStorage());
    await repo.hydrate();
    await repo.add(_mission('m1', isActive: true));
    await repo.add(_mission('m2'));

    // Simulate an app restart: brand-new repository over the same prefs.
    final restarted = PersistentGeofenceRepository(await newStorage());
    await restarted.hydrate();

    expect(restarted.current, hasLength(2));
    expect(restarted.getById('m1')!.isActive, isTrue);
    expect(restarted.getById('m2')!.isActive, isFalse);
  });

  test('update persists across restart', () async {
    final repo = PersistentGeofenceRepository(await newStorage());
    await repo.hydrate();
    await repo.add(_mission('m1'));
    await repo.update(
      repo.getById('m1')!.copyWith(title: 'Renamed', isActive: true),
    );

    final restarted = PersistentGeofenceRepository(await newStorage());
    await restarted.hydrate();

    expect(restarted.getById('m1')!.title, 'Renamed');
    expect(restarted.getById('m1')!.isActive, isTrue);
  });

  test('update of an unknown id is a no-op and persists nothing', () async {
    final repo = PersistentGeofenceRepository(await newStorage());
    await repo.hydrate();
    await repo.update(_mission('ghost'));

    final restarted = PersistentGeofenceRepository(await newStorage());
    await restarted.hydrate();

    expect(restarted.current, isEmpty);
  });

  test('delete persists across restart', () async {
    final repo = PersistentGeofenceRepository(await newStorage());
    await repo.hydrate();
    await repo.add(_mission('keep'));
    await repo.add(_mission('drop'));
    await repo.delete('drop');

    final restarted = PersistentGeofenceRepository(await newStorage());
    await restarted.hydrate();

    expect(restarted.current, hasLength(1));
    expect(restarted.getById('keep'), isNotNull);
    expect(restarted.getById('drop'), isNull);
  });

  test('clear persists across restart', () async {
    final repo = PersistentGeofenceRepository(await newStorage());
    await repo.hydrate();
    await repo.add(_mission('m1'));
    await repo.add(_mission('m2'));
    await repo.clear();

    final restarted = PersistentGeofenceRepository(await newStorage());
    await restarted.hydrate();

    expect(restarted.current, isEmpty);
  });

  test('hydrate forces runtime status back to unknown', () async {
    // Legacy-style payload that still carries a persisted status.
    SharedPreferences.setMockInitialValues({
      'wellness_geofence_missions': jsonEncode({
        'version': 1,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'missions': [
          {
            'id': 'm1',
            'title': 'Stale status',
            'latitude': 14.5995,
            'longitude': 120.9842,
            'radius': 60.0,
            'type': 'sanctuary',
            'isActive': true,
            'status': 'inside',
          },
        ],
      }),
    });

    final repo = PersistentGeofenceRepository(await newStorage());
    await repo.hydrate();

    expect(repo.getById('m1')!.status, GeofenceStatus.unknown);
    expect(repo.getById('m1')!.isActive, isTrue);
  });

  test('hydrate is idempotent: no duplicates, no second notify', () async {
    final seed = PersistentGeofenceRepository(await newStorage());
    await seed.hydrate();
    await seed.add(_mission('m1'));

    final repo = PersistentGeofenceRepository(await newStorage());
    var notifications = 0;
    repo.addListener(() => notifications++);

    await repo.hydrate();
    expect(repo.current, hasLength(1));
    expect(notifications, 1);

    await repo.hydrate();
    expect(repo.current, hasLength(1));
    expect(notifications, 1);
  });

  test('persistence errors are swallowed best-effort', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = PersistentGeofenceRepository(_ThrowingStorage(prefs));

    await repo.hydrate();
    expect(repo.current, isEmpty);

    await repo.add(_mission('m1'));
    await repo.update(repo.getById('m1')!.copyWith(title: 'Renamed'));
    await repo.delete('m1');
    await repo.clear();

    // In-memory semantics stay intact even though storage kept failing.
    expect(repo.current, isEmpty);
  });
}
