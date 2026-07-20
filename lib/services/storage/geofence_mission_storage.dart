import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';

/// Service for local persistence of wellness geofence missions
///
/// Stores the full mission list as a single versioned JSON envelope so the
/// kid's saved zones survive app restarts. The runtime-only `status` field
/// is stripped on save because inside/outside must be re-derived from live
/// location after every launch.
class GeofenceMissionStorage {
  static const String _missionsKey = 'wellness_geofence_missions';

  final SharedPreferences _prefs;

  GeofenceMissionStorage(this._prefs);

  /// Save the mission list, replacing whatever was stored before.
  Future<void> saveMissions(List<GeofenceMission> missions) async {
    final envelope = {
      'version': 1,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'missions': missions.map((mission) {
        final json = mission.toJson();
        // Status is runtime-derived; never persist it.
        json.remove('status');
        return json;
      }).toList(),
    };

    await _prefs.setString(_missionsKey, jsonEncode(envelope));
  }

  /// Load missions from local storage.
  ///
  /// A corrupted or unparseable payload is cleared and an empty list is
  /// returned so a bad write can never wedge the wellness map.
  Future<List<GeofenceMission>> loadMissions() async {
    final raw = _prefs.getString(_missionsKey);
    if (raw == null) return [];

    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final missions = envelope['missions'] as List;
      return missions
          .map((m) => GeofenceMission.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If parsing fails, clear corrupted data
      await clear();
      return [];
    }
  }

  /// Clear saved missions from local storage
  Future<void> clear() async {
    await _prefs.remove(_missionsKey);
  }
}
