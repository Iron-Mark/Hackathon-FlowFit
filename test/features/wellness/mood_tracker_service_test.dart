import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/features/wellness/services/mood_tracker_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flowfit/features/wellness/services/geofence_service.dart';
import 'package:flowfit/features/wellness/data/geofence_repository.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MoodTracker triggers focus to nearest mission', () async {
    final controller = StreamController<MoodState>();
    final repo = InMemoryGeofenceRepository();
    final service = GeofenceService(
      repository: repo,
      positionStreamOverride: null,
    );
    final tracker = MoodTrackerService(
      repository: repo,
      service: service,
      moodStreamOverride: controller.stream,
      currentPositionGetter: () async => Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        headingAccuracy: 0.0,
        altitudeAccuracy: 0.0,
      ),
    );

    final mission = GeofenceMission(
      id: 'm1',
      title: 'Sanctuary',
      center: const LatLngSimple(0.0, 0.0),
      radiusMeters: 100,
      type: MissionType.sanctuary,
    );
    await repo.add(mission);

    final focusEvents = <String>[];
    final sub = service.focusRequests.listen((id) => focusEvents.add(id));

    await tracker.startMonitoring();
    controller.add(MoodState.stressed);
    // Wait a short time to allow the async processing to happen.
    await Future.delayed(const Duration(milliseconds: 100));

    expect(focusEvents.contains('m1'), true);
    final updated = repo.getById('m1');
    expect(updated?.isActive ?? false, true);

    await tracker.stopMonitoring();
    await sub.cancel();
    await controller.close();
  });
}
