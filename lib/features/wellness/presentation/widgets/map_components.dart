import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as maplat;
import '../../domain/geofence_mission.dart';

fm.Marker buildMissionMarker(GeofenceMission m, VoidCallback onTap) {
  return fm.Marker(
    width: 36,
    height: 36,
    point: maplat.LatLng(m.center.latitude, m.center.longitude),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: m.isActive ? Colors.greenAccent : Colors.redAccent,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4.0)],
        ),
        child: const Icon(Icons.location_on, color: Colors.white, size: 20),
      ),
    ),
  );
}

fm.CircleMarker buildMissionCircle(GeofenceMission m) {
  return fm.CircleMarker(
    point: maplat.LatLng(m.center.latitude, m.center.longitude),
    color: (m.isActive
        ? Colors.greenAccent.withAlpha((0.2 * 255).toInt())
        : Colors.redAccent.withAlpha((0.1 * 255).toInt())),
    borderStrokeWidth: 1.0,
    borderColor: m.isActive ? Colors.green : Colors.red,
    radius: m.radiusMeters.toDouble(),
    useRadiusInMeter: true,
  );
}

fm.Marker buildPreviewMarker(maplat.LatLng latLng) {
  return fm.Marker(
    width: 36,
    height: 36,
    point: latLng,
    child: Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add_location, color: Colors.white, size: 20),
    ),
  );
}

fm.CircleMarker buildPreviewCircle(maplat.LatLng latLng, double radius) {
  return fm.CircleMarker(
    point: latLng,
    color: Colors.blueAccent.withAlpha((0.12 * 255).toInt()),
    borderStrokeWidth: 1.0,
    borderColor: Colors.blueAccent,
    radius: radius.toDouble(),
    useRadiusInMeter: true,
  );
}
