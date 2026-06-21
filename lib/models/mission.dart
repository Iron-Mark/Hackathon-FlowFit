import 'package:latlong2/latlong.dart';

/// Mission type enumeration
enum MissionType {
  target,
  sanctuary,
  safetyNet;

  String get displayName {
    switch (this) {
      case MissionType.target:
        return 'Target';
      case MissionType.sanctuary:
        return 'Sanctuary';
      case MissionType.safetyNet:
        return 'Safety Net';
    }
  }

  String get description {
    switch (this) {
      case MissionType.target:
        return 'Walk X meters from starting point';
      case MissionType.sanctuary:
        return 'Reach a specific GPS coordinate';
      case MissionType.safetyNet:
        return 'Stay within radius (elder care)';
    }
  }
}

/// Location-based walking mission
///
/// Defines a goal for walking workouts such as reaching a specific
/// location or walking a certain distance.
class Mission {
  /// Unique mission identifier
  final String id;

  /// Type of mission
  final MissionType type;

  /// Target GPS location
  final LatLng targetLocation;

  /// Target distance in meters (for target missions)
  final double? targetDistance;

  /// Radius in meters (for safety net missions)
  final double? radius;

  /// Mission name
  final String name;

  /// Optional mission description
  final String? description;

  Mission({
    required this.id,
    required this.type,
    required this.targetLocation,
    this.targetDistance,
    this.radius,
    required this.name,
    this.description,
  });

  /// Checks if mission is completed based on current location
  bool isCompleted(LatLng currentLocation) {
    final distance = _calculateDistance(currentLocation, targetLocation);

    switch (type) {
      case MissionType.target:
        return targetDistance != null && distance >= targetDistance!;
      case MissionType.sanctuary:
        return distance <= 50; // within 50m
      case MissionType.safetyNet:
        return radius != null && distance <= radius!;
    }
  }

  /// Calculates distance between two GPS coordinates in meters
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  /// Creates a Mission from JSON
  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as String,
      type: MissionType.values.byName(json['type'] as String),
      targetLocation: LatLng(
        json['target_latitude'] as double,
        json['target_longitude'] as double,
      ),
      targetDistance: json['target_distance'] as double?,
      radius: json['radius'] as double?,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  /// Converts this Mission to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'target_latitude': targetLocation.latitude,
      'target_longitude': targetLocation.longitude,
      if (targetDistance != null) 'target_distance': targetDistance,
      if (radius != null) 'radius': radius,
      'name': name,
      if (description != null) 'description': description,
    };
  }

  @override
  String toString() {
    return 'Mission(id: $id, type: ${type.displayName}, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mission &&
        other.id == id &&
        other.type == type &&
        other.targetLocation == targetLocation &&
        other.targetDistance == targetDistance &&
        other.radius == radius &&
        other.name == name &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      type,
      targetLocation,
      targetDistance,
      radius,
      name,
      description,
    );
  }
}
