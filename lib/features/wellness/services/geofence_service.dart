import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/geofence_mission.dart';
import 'notification_service.dart';
import '../data/geofence_repository.dart';

enum GeofenceEventType { entered, exited, targetReached, outsideAlert }

class GeofenceEvent {
  final String missionId;
  final GeofenceEventType type;
  final Position position;
  final double? value; // optional value like progress distance

  GeofenceEvent({
    required this.missionId,
    required this.type,
    required this.position,
    this.value,
  });
}

class GeofenceService extends ChangeNotifier {
  final GeofenceRepository repository;
  final StreamController<String> _focusRequestController =
      StreamController.broadcast();
  StreamSubscription<Position>? _positionSub;
  final Stream<Position>? _positionStreamOverride;
  final StreamController<GeofenceEvent> _eventController =
      StreamController.broadcast();

  // For target missions we track lastPos and cumulative distances
  final Map<String, Position> _lastPositionForMission = {};
  final Map<String, double> _cumulativeDistanceForMission = {};

  GeofenceService({
    required this.repository,
    Stream<Position>? positionStreamOverride,
  }) : _positionStreamOverride = positionStreamOverride;

  Stream<GeofenceEvent> get events => _eventController.stream;

  Stream<String> get focusRequests => _focusRequestController.stream;

  double getProgress(String missionId) =>
      _cumulativeDistanceForMission[missionId] ?? 0.0;

  Future<void> startMonitoring({bool requirePermissions = true}) async {
    if (requirePermissions) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        // bail
        return;
      }
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // small filter
    );
    _positionSub ??=
        (_positionStreamOverride ??
                Geolocator.getPositionStream(
                  locationSettings: locationSettings,
                ))
            .listen((pos) async {
              await _handlePosition(pos);
            });
  }

  Future<void> stopMonitoring() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }

  Future<void> activateMission(String id) async {
    final mission = repository.getById(id);
    if (mission == null) return;
    await repository.update(
      mission.copyWith(isActive: true, status: GeofenceStatus.unknown),
    );
    _cumulativeDistanceForMission[id] = 0.0;
    _lastPositionForMission.remove(id);
    notifyListeners();
  }

  Future<void> deactivateMission(String id) async {
    final mission = repository.getById(id);
    if (mission == null) return;
    await repository.update(mission.copyWith(isActive: false));
    _cumulativeDistanceForMission.remove(id);
    _lastPositionForMission.remove(id);
    notifyListeners();
  }

  /// Called to request the UI to open focus for a mission (by id).
  void requestFocus(String missionId) {
    _focusRequestController.add(missionId);
  }

  Future<void> _handlePosition(Position pos) async {
    final missions = (await repository.getAll())
        .where((m) => m.isActive)
        .toList();
    for (final m in missions) {
      final dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        m.center.latitude,
        m.center.longitude,
      );

      final isInside = dist <= m.radiusMeters;
      final prev = m.status;

      // Update repository mission status
      await repository.update(
        m.copyWith(
          status: isInside ? GeofenceStatus.inside : GeofenceStatus.outside,
        ),
      );

      // Enter/Exit detection
      if (prev != GeofenceStatus.inside && isInside) {
        _eventController.add(
          GeofenceEvent(
            missionId: m.id,
            type: GeofenceEventType.entered,
            position: pos,
          ),
        );
      }
      if (prev == GeofenceStatus.inside && !isInside) {
        _eventController.add(
          GeofenceEvent(
            missionId: m.id,
            type: GeofenceEventType.exited,
            position: pos,
          ),
        );
      }

      // Special behavior per mission type
      if (m.type == MissionType.safetyNet && !isInside) {
        // If outside and safety net active, alert
        _eventController.add(
          GeofenceEvent(
            missionId: m.id,
            type: GeofenceEventType.outsideAlert,
            position: pos,
            value: dist,
          ),
        );
        // Show local notification
        NotificationService.showNotification(
          title: '${m.title} - Outside',
          body:
              'You are ${dist.toStringAsFixed(1)} m outside the safety radius.',
        );
      }

      if (m.type == MissionType.target) {
        // accumulate distance travelled while active
        final lastPos = _lastPositionForMission[m.id];
        if (lastPos != null) {
          final delta = Geolocator.distanceBetween(
            lastPos.latitude,
            lastPos.longitude,
            pos.latitude,
            pos.longitude,
          );
          _cumulativeDistanceForMission[m.id] =
              (_cumulativeDistanceForMission[m.id] ?? 0.0) + delta;
          final reached =
              (m.targetDistanceMeters ?? double.infinity) <=
              (_cumulativeDistanceForMission[m.id] ?? 0);
          _eventController.add(
            GeofenceEvent(
              missionId: m.id,
              type: GeofenceEventType.targetReached,
              position: pos,
              value: _cumulativeDistanceForMission[m.id],
            ),
          );
          if (reached) {
            // Show notification for target reached
            NotificationService.showNotification(
              title: '${m.title} - Target reached',
              body:
                  'Good job! You reached ${m.targetDistanceMeters?.toStringAsFixed(0) ?? 0} m',
            );
          }
          if (reached) {
            // consider deactivating or notify the mission complete
            await repository.update(m.copyWith(isActive: false));
          }
        }
        _lastPositionForMission[m.id] = pos;
      }
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _eventController.close();
    _focusRequestController.close();
    super.dispose();
  }
}
