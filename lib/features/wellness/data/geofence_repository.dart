import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../domain/geofence_mission.dart';

abstract class GeofenceRepository extends ChangeNotifier {
  Future<List<GeofenceMission>> getAll();
  List<GeofenceMission> get current;
  GeofenceMission? getById(String id);
  Future<void> add(GeofenceMission mission);
  Future<void> update(GeofenceMission mission);
  Future<void> delete(String id);
  Future<void> clear();
}

/// Simple in-memory repository for geofence missions.
class InMemoryGeofenceRepository extends GeofenceRepository {
  final Map<String, GeofenceMission> _store = {};

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
  }

  @override
  Future<void> update(GeofenceMission mission) async {
    if (!_store.containsKey(mission.id)) return;
    _store[mission.id] = mission;
    notifyListeners();
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
    notifyListeners();
  }

  @override
  Future<void> clear() async {
    _store.clear();
    notifyListeners();
  }
}
