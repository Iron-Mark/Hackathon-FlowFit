import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flowfit/features/wellness/data/geofence_repository.dart';
import 'package:flowfit/features/wellness/data/geofence_repository.dart'
    show InMemoryGeofenceRepository;
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';
import 'package:flowfit/features/wellness/services/geofence_service.dart';

Position _p(double lat, double lon) => Position(
  latitude: lat,
  longitude: lon,
  timestamp: DateTime.now(),
  accuracy: 1.0,
  altitude: 0.0,
  heading: 0.0,
  speed: 0.0,
  speedAccuracy: 0.0,
  headingAccuracy: 0.0,
  altitudeAccuracy: 0.0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('target mission accumulates distance and completes', () async {
    final controller = StreamController<Position>();
    final repo = InMemoryGeofenceRepository();
    final service = GeofenceService(
      repository: repo,
      positionStreamOverride: controller.stream,
    );

    // mission center at (0,0) and huge radius so inside
    final mission = GeofenceMission(
      id: 't1',
      title: 'Target Test',
      center: const LatLngSimple(0.0, 0.0),
      radiusMeters: 100000,
      type: MissionType.target,
      targetDistanceMeters: 500,
    );
    await repo.add(mission);

    final events = <GeofenceEvent>[];
    service.events.listen((e) => events.add(e));
    await service.startMonitoring(requirePermissions: false);

    // activate mission
    await service.activateMission(mission.id);

    // simulate positions with incremental movement so that distances accumulate
    controller.add(_p(0.0, 0.0));
    await Future.delayed(const Duration(milliseconds: 10));
    // approximate 200m east (lon delta depends on latitude; at equator, 0.0018 deg ~ 200m)
    controller.add(_p(0.0, 0.002));
    await Future.delayed(const Duration(milliseconds: 10));
    controller.add(_p(0.0, 0.004));
    await Future.delayed(const Duration(milliseconds: 10));
    controller.add(_p(0.0, 0.006));
    await Future.delayed(const Duration(milliseconds: 10));

    // wait for events to process
    await Future.delayed(const Duration(milliseconds: 50));

    expect(events.any((e) => e.type == GeofenceEventType.targetReached), true);

    // ensure mission auto-deactivated when target reached
    final updated = repo.getById('t1');
    expect(updated?.isActive ?? false, false);

    await service.stopMonitoring();
    await controller.close();
  });

  test('safetyNet outside alert triggers', () async {
    final controller = StreamController<Position>();
    final repo = InMemoryGeofenceRepository();
    final service = GeofenceService(
      repository: repo,
      positionStreamOverride: controller.stream,
    );

    final mission = GeofenceMission(
      id: 's1',
      title: 'Safety Net',
      center: const LatLngSimple(0.0, 0.0),
      radiusMeters: 50,
      type: MissionType.safetyNet,
      targetDistanceMeters: null,
      isActive: true,
    );
    await repo.add(mission);
    final events = <GeofenceEvent>[];
    service.events.listen((e) => events.add(e));
    await service.startMonitoring(requirePermissions: false);
    await service.activateMission('s1');

    // simulate far away position
    controller.add(_p(1.0, 1.0));
    await Future.delayed(const Duration(milliseconds: 50));
    expect(events.any((e) => e.type == GeofenceEventType.outsideAlert), true);

    await service.stopMonitoring();
    await controller.close();
  });
}
