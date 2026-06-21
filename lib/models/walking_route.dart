import 'package:latlong2/latlong.dart';

/// Walking route model for calming route suggestions
class WalkingRoute {
  final String id;
  final String name;
  final List<LatLng> routePoints;
  final double distance; // in kilometers
  final int duration; // in minutes
  final double calmScore; // 0.0 to 1.0
  final double greenSpacePercentage; // 0.0 to 1.0
  final String? description;
  final List<String> features; // e.g., ['park', 'waterfront', 'quiet']

  WalkingRoute({
    required this.id,
    required this.name,
    required this.routePoints,
    required this.distance,
    required this.duration,
    required this.calmScore,
    required this.greenSpacePercentage,
    this.description,
    this.features = const [],
  }) : assert(distance >= 0, 'Distance must be non-negative'),
       assert(duration >= 0, 'Duration must be non-negative'),
       assert(
         calmScore >= 0.0 && calmScore <= 1.0,
         'Calm score must be between 0 and 1',
       ),
       assert(
         greenSpacePercentage >= 0.0 && greenSpacePercentage <= 1.0,
         'Green space percentage must be between 0 and 1',
       );

  /// Route difficulty level based on distance
  String get difficulty {
    if (distance < 1.5) return 'Easy';
    if (distance < 2.5) return 'Moderate';
    return 'Challenging';
  }

  /// Estimated calories burned (rough estimate)
  int get estimatedCalories {
    // Rough estimate: 50 calories per km
    return (distance * 50).round();
  }

  /// Creates a copy with updated fields
  WalkingRoute copyWith({
    String? id,
    String? name,
    List<LatLng>? routePoints,
    double? distance,
    int? duration,
    double? calmScore,
    double? greenSpacePercentage,
    String? description,
    List<String>? features,
  }) {
    return WalkingRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      routePoints: routePoints ?? this.routePoints,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      calmScore: calmScore ?? this.calmScore,
      greenSpacePercentage: greenSpacePercentage ?? this.greenSpacePercentage,
      description: description ?? this.description,
      features: features ?? this.features,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'route_points': routePoints
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
      'distance': distance,
      'duration': duration,
      'calm_score': calmScore,
      'green_space_percentage': greenSpacePercentage,
      if (description != null) 'description': description,
      'features': features,
    };
  }

  /// Creates from JSON
  factory WalkingRoute.fromJson(Map<String, dynamic> json) {
    return WalkingRoute(
      id: json['id'] as String,
      name: json['name'] as String,
      routePoints: (json['route_points'] as List)
          .map(
            (point) => LatLng(
              (point['lat'] as num).toDouble(),
              (point['lng'] as num).toDouble(),
            ),
          )
          .toList(),
      distance: (json['distance'] as num).toDouble(),
      duration: json['duration'] as int,
      calmScore: (json['calm_score'] as num).toDouble(),
      greenSpacePercentage: (json['green_space_percentage'] as num).toDouble(),
      description: json['description'] as String?,
      features: (json['features'] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  String toString() {
    return 'WalkingRoute(name: $name, distance: ${distance.toStringAsFixed(1)}km, duration: ${duration}min, calmScore: ${calmScore.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalkingRoute &&
        other.id == id &&
        other.name == name &&
        other.distance == distance &&
        other.duration == duration &&
        other.calmScore == calmScore &&
        other.greenSpacePercentage == greenSpacePercentage;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      distance,
      duration,
      calmScore,
      greenSpacePercentage,
    );
  }
}
