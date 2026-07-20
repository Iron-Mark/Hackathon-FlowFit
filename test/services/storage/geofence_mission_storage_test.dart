import 'dart:convert';

import 'package:flowfit/features/wellness/domain/geofence_mission.dart';
import 'package:flowfit/services/storage/geofence_mission_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

GeofenceMission _mission(
  String id, {
  bool isActive = false,
  GeofenceStatus status = GeofenceStatus.unknown,
}) => GeofenceMission(
  id: id,
  title: 'Mission $id',
  description: 'Description for $id',
  center: const LatLng(14.5995, 120.9842),
  radiusMeters: 75.0,
  type: GeofenceMissionType.target,
  isActive: isActive,
  targetDistanceMeters: 500.0,
  status: status,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saveMissions/loadMissions round-trips mission fields', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = GeofenceMissionStorage(prefs);

    await storage.saveMissions([_mission('m1'), _mission('m2')]);
    final loaded = await storage.loadMissions();

    expect(loaded, hasLength(2));
    final first = loaded.firstWhere((m) => m.id == 'm1');
    expect(first.title, 'Mission m1');
    expect(first.description, 'Description for m1');
    expect(first.center.latitude, closeTo(14.5995, 1e-9));
    expect(first.center.longitude, closeTo(120.9842, 1e-9));
    expect(first.radiusMeters, 75.0);
    expect(first.type, GeofenceMissionType.target);
    expect(first.targetDistanceMeters, 500.0);
  });

  test('save writes a versioned envelope under the wellness key', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = GeofenceMissionStorage(prefs);

    await storage.saveMissions([_mission('m1')]);

    final raw = prefs.getString('wellness_geofence_missions');
    expect(raw, isNotNull);
    final envelope = jsonDecode(raw!) as Map<String, dynamic>;
    expect(envelope['version'], 1);
    expect(envelope['savedAt'], isA<String>());
    expect(DateTime.parse(envelope['savedAt'] as String).isUtc, isTrue);
    expect(envelope['missions'], hasLength(1));
  });

  test('runtime status is stripped on save and unknown after load', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = GeofenceMissionStorage(prefs);

    await storage.saveMissions([_mission('m1', status: GeofenceStatus.inside)]);

    final raw = prefs.getString('wellness_geofence_missions')!;
    final envelope = jsonDecode(raw) as Map<String, dynamic>;
    final missionJson = (envelope['missions'] as List).first as Map;
    expect(missionJson.containsKey('status'), isFalse);

    final loaded = await storage.loadMissions();
    expect(loaded.single.status, GeofenceStatus.unknown);
  });

  test('isActive round-trips faithfully', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = GeofenceMissionStorage(prefs);

    await storage.saveMissions([
      _mission('armed', isActive: true),
      _mission('disarmed', isActive: false),
    ]);
    final loaded = await storage.loadMissions();

    expect(loaded.firstWhere((m) => m.id == 'armed').isActive, isTrue);
    expect(loaded.firstWhere((m) => m.id == 'disarmed').isActive, isFalse);
  });

  test('corrupted payload clears the key and returns empty list', () async {
    SharedPreferences.setMockInitialValues({
      'wellness_geofence_missions': 'not valid json {{{',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = GeofenceMissionStorage(prefs);

    final loaded = await storage.loadMissions();

    expect(loaded, isEmpty);
    expect(prefs.containsKey('wellness_geofence_missions'), isFalse);
  });

  test(
    'parseable envelope with malformed mission entries is cleared',
    () async {
      SharedPreferences.setMockInitialValues({
        'wellness_geofence_missions': jsonEncode({
          'version': 1,
          'savedAt': DateTime.now().toUtc().toIso8601String(),
          'missions': [
            {'title': 'missing id and coordinates'},
          ],
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = GeofenceMissionStorage(prefs);

      final loaded = await storage.loadMissions();

      expect(loaded, isEmpty);
      expect(prefs.containsKey('wellness_geofence_missions'), isFalse);
    },
  );

  test('loadMissions returns empty list when nothing saved', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = GeofenceMissionStorage(prefs);

    expect(await storage.loadMissions(), isEmpty);
  });

  test('clear removes saved missions', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = GeofenceMissionStorage(prefs);

    await storage.saveMissions([_mission('m1')]);
    await storage.clear();

    expect(prefs.containsKey('wellness_geofence_missions'), isFalse);
    expect(await storage.loadMissions(), isEmpty);
  });
}
