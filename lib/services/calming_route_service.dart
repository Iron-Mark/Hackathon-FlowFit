import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/walking_route.dart';
import 'openroute_service.dart' show OpenRouteService, POI;

/// Service for generating calming walking routes
class CalmingRouteService {
  final OpenRouteService _openRouteService;

  // Route configurations
  static const List<RouteConfig> _routeConfigs = [
    RouteConfig(distance: 1.0, duration: 12, name: 'Short Walk'),
    RouteConfig(distance: 2.0, duration: 25, name: 'Medium Walk'),
    RouteConfig(distance: 3.0, duration: 37, name: 'Long Walk'),
  ];

  CalmingRouteService(this._openRouteService);

  /// Generates calming routes near the given location
  Future<List<WalkingRoute>> generateCalmingRoutes(LatLng location) async {
    try {
      final routes = <WalkingRoute>[];

      // Generate routes for each configuration
      for (final config in _routeConfigs) {
        final route = await _generateRoute(location, config);
        if (route != null) {
          routes.add(route);
        }
      }

      // Sort by calm score (highest first)
      routes.sort((a, b) => b.calmScore.compareTo(a.calmScore));

      // Return top 3
      return routes.take(3).toList();
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Generates a single route
  Future<WalkingRoute?> _generateRoute(
    LatLng location,
    RouteConfig config,
  ) async {
    try {
      // Search for nearby POIs (parks, gardens, waterfront)
      final pois = await _openRouteService.searchNearbyPOIs(
        location,
        radius: config.distance * 1000, // Convert km to meters
        categories: ['park', 'garden', 'waterfront', 'nature_reserve'],
      );

      // Generate circular route
      final routePoints = _generateCircularRoute(
        location,
        config.distance,
        pois,
      );

      // Calculate route metrics
      final greenSpacePercentage = _calculateGreenSpacePercentage(
        routePoints,
        pois,
      );
      final calmScore = _calculateCalmScore(
        greenSpacePercentage: greenSpacePercentage,
        routePoints: routePoints,
        pois: pois,
      );

      // Extract features
      final features = _extractFeatures(pois);

      return WalkingRoute(
        id: 'route_${config.name.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
        name: config.name,
        routePoints: routePoints,
        distance: config.distance,
        duration: config.duration,
        calmScore: calmScore,
        greenSpacePercentage: greenSpacePercentage,
        description: _generateDescription(config, features),
        features: features,
      );
    } catch (e) {
      return null;
    }
  }

  /// Generates a circular route around the starting location
  List<LatLng> _generateCircularRoute(
    LatLng center,
    double distanceKm,
    List<POI> pois,
  ) {
    final points = <LatLng>[];
    final radiusKm = distanceKm / (2 * pi);
    const numPoints = 16; // 16 points for smooth circle

    // Generate circular path
    for (int i = 0; i <= numPoints; i++) {
      final angle = (i / numPoints) * 2 * pi;
      final lat = center.latitude + (radiusKm / 111.0) * cos(angle);
      final lng =
          center.longitude +
          (radiusKm / (111.0 * cos(center.latitude * pi / 180))) * sin(angle);
      points.add(LatLng(lat, lng));
    }

    // Adjust route to pass through nearby POIs
    if (pois.isNotEmpty) {
      points.addAll(_adjustRouteForPOIs(points, pois));
    }

    return points;
  }

  /// Adjusts route to pass through interesting POIs
  List<LatLng> _adjustRouteForPOIs(List<LatLng> baseRoute, List<POI> pois) {
    // Simple implementation: add POI locations as waypoints
    final adjusted = <LatLng>[...baseRoute];

    for (final poi in pois.take(3)) {
      // Insert POI at closest point in route
      int closestIndex = 0;
      double minDistance = double.infinity;

      for (int i = 0; i < adjusted.length; i++) {
        final distance = _calculateDistance(adjusted[i], poi.location);
        if (distance < minDistance) {
          minDistance = distance;
          closestIndex = i;
        }
      }

      adjusted.insert(closestIndex + 1, poi.location);
    }

    return adjusted;
  }

  /// Calculates green space percentage along route
  double _calculateGreenSpacePercentage(
    List<LatLng> routePoints,
    List<POI> pois,
  ) {
    if (pois.isEmpty) return 0.2; // Default 20% if no POI data

    int greenPoints = 0;
    const double proximityThreshold = 0.1; // 100 meters

    for (final point in routePoints) {
      for (final poi in pois) {
        if (_calculateDistance(point, poi.location) < proximityThreshold) {
          greenPoints++;
          break;
        }
      }
    }

    return (greenPoints / routePoints.length).clamp(0.0, 1.0);
  }

  /// Calculates calm score for route
  double _calculateCalmScore({
    required double greenSpacePercentage,
    required List<LatLng> routePoints,
    required List<POI> pois,
  }) {
    // Weighted scoring algorithm
    const double greenSpaceWeight = 0.4;
    const double lowTrafficWeight = 0.3;
    const double safetyWeight = 0.2;
    const double scenicWeight = 0.1;

    final greenScore = greenSpacePercentage;
    final trafficScore = _estimateLowTraffic(routePoints);
    final safetyScore = _estimateSafety(routePoints, pois);
    final scenicScore = _estimateScenicValue(pois);

    return (greenScore * greenSpaceWeight +
            trafficScore * lowTrafficWeight +
            safetyScore * safetyWeight +
            scenicScore * scenicWeight)
        .clamp(0.0, 1.0);
  }

  /// Estimates low traffic score (higher is better)
  double _estimateLowTraffic(List<LatLng> routePoints) {
    // Simplified: assume routes with more points are more winding (less traffic)
    return (routePoints.length / 20.0).clamp(0.0, 1.0);
  }

  /// Estimates safety score
  double _estimateSafety(List<LatLng> routePoints, List<POI> pois) {
    // Simplified: more POIs nearby = safer
    return (pois.length / 10.0).clamp(0.0, 1.0);
  }

  /// Estimates scenic value
  double _estimateScenicValue(List<POI> pois) {
    // Count scenic POI types
    final scenicTypes = ['waterfront', 'park', 'garden', 'nature_reserve'];
    final scenicCount = pois
        .where((poi) => scenicTypes.contains(poi.category))
        .length;
    return (scenicCount / 5.0).clamp(0.0, 1.0);
  }

  /// Extracts feature tags from POIs
  List<String> _extractFeatures(List<POI> pois) {
    final features = <String>{};

    for (final poi in pois) {
      if (poi.category == 'park') features.add('park');
      if (poi.category == 'waterfront') features.add('waterfront');
      if (poi.category == 'garden') features.add('garden');
      if (poi.category == 'nature_reserve') features.add('quiet');
    }

    return features.toList();
  }

  /// Generates route description
  String _generateDescription(RouteConfig config, List<String> features) {
    if (features.isEmpty) {
      return 'A ${config.name.toLowerCase()} through your neighborhood';
    }

    final featureText = features.take(2).join(' and ');
    return 'A ${config.name.toLowerCase()} featuring $featureText';
  }

  /// Calculates distance between two points in kilometers
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }
}

/// Route configuration
class RouteConfig {
  final double distance; // km
  final int duration; // minutes
  final String name;

  const RouteConfig({
    required this.distance,
    required this.duration,
    required this.name,
  });
}
