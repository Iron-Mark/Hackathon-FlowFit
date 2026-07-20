// Kept minimal imports; enums and data classes used across the feature
import 'package:latlong2/latlong.dart';

enum GeofenceMissionType { target, sanctuary, safetyNet }

enum GeofenceStatus { unknown, inside, outside }

class GeofenceMission {
  final String id;
  String title;
  String? description;
  LatLng center;
  double radiusMeters;
  GeofenceMissionType type;
  bool isActive;
  double? targetDistanceMeters; // Only for target missions

  // Runtime only
  GeofenceStatus status;

  GeofenceMission({
    required this.id,
    required this.title,
    this.description,
    required this.center,
    this.radiusMeters = 50.0,
    this.type = GeofenceMissionType.sanctuary,
    this.isActive = false,
    this.targetDistanceMeters,
    this.status = GeofenceStatus.unknown,
  });

  GeofenceMission copyWith({
    String? title,
    String? description,
    LatLng? center,
    double? radiusMeters,
    GeofenceMissionType? type,
    bool? isActive,
    double? targetDistanceMeters,
    GeofenceStatus? status,
  }) {
    return GeofenceMission(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      center: center ?? this.center,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      targetDistanceMeters: targetDistanceMeters ?? this.targetDistanceMeters,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'latitude': center.latitude,
    'longitude': center.longitude,
    'radius': radiusMeters,
    'type': type.name,
    'isActive': isActive,
    'targetDistance': targetDistanceMeters,
    'status': status.name,
  };

  factory GeofenceMission.fromJson(Map<String, dynamic> json) {
    return GeofenceMission(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      center: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      radiusMeters: (json['radius'] as num?)?.toDouble() ?? 50.0,
      type: GeofenceMissionType.values.firstWhere(
        (t) => t.name == (json['type'] as String?),
        orElse: () => GeofenceMissionType.sanctuary,
      ),
      isActive: (json['isActive'] as bool?) ?? false,
      targetDistanceMeters: (json['targetDistance'] as num?)?.toDouble(),
      status: GeofenceStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String?),
        orElse: () => GeofenceStatus.unknown,
      ),
    );
  }
}
