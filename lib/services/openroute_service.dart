import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Service for OpenRouteService API integration
class OpenRouteService {
  static const String apiKey = '5b3ce35978511000001cf62248';
  static const String baseUrl = 'https://api.openrouteservice.org';

  static const Map<String, int> _categoryIdsByName = {
    'garden': 272,
    'nature_reserve': 279,
    'nature reserve': 279,
    'park': 280,
    'beach': 332,
    'water': 340,
    'waterfront': 340,
    'picnic_site': 625,
    'picnic site': 625,
    'viewpoint': 627,
  };

  static const Map<int, String> _categoryNamesById = {
    272: 'garden',
    279: 'nature_reserve',
    280: 'park',
    332: 'beach',
    340: 'waterfront',
    625: 'picnic_site',
    627: 'viewpoint',
  };

  final http.Client _httpClient;
  DefaultCacheManager? _cacheManager;

  OpenRouteService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  DefaultCacheManager get _mapTileCache =>
      _cacheManager ??= DefaultCacheManager();

  /// Encodes a list of GPS coordinates into a polyline string
  Future<String> encodePolyline(List<LatLng> points) async {
    if (points.isEmpty) return '';

    try {
      final coordinates = points.map((p) => [p.longitude, p.latitude]).toList();

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/v2/directions/foot-walking/geojson'),
        headers: {'Authorization': apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode({'coordinates': coordinates}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['routes'][0]['geometry'] as String;
      } else if (response.statusCode == 429) {
        throw OpenRouteServiceException('Rate limit exceeded');
      } else {
        throw OpenRouteServiceException(
          'Failed to encode polyline: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw OpenRouteServiceException('Error encoding polyline: $e');
    }
  }

  /// Decodes a polyline string into a list of GPS coordinates
  List<LatLng> decodePolyline(String encoded) {
    if (encoded.isEmpty) return [];

    // Simple polyline decoding algorithm
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  /// Gets a map tile URL for the given coordinates and zoom level
  String getMapTileUrl(int x, int y, int zoom) {
    return 'https://tile.openstreetmap.org/$zoom/$x/$y.png';
  }

  /// Fetches and caches a map tile
  Future<String?> getMapTile(int x, int y, int zoom) async {
    try {
      final url = getMapTileUrl(x, y, zoom);
      final file = await _mapTileCache.getSingleFile(url);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Calculates bounding box for a list of route points
  Map<String, double> calculateBounds(List<LatLng> routePoints) {
    if (routePoints.isEmpty) {
      return {'minLat': 0.0, 'maxLat': 0.0, 'minLng': 0.0, 'maxLng': 0.0};
    }

    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;

    for (final point in routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }

  /// Searches for nearby POIs
  Future<List<POI>> searchNearbyPOIs(
    LatLng location, {
    required double radius,
    required List<String> categories,
  }) async {
    final categoryIds = _resolveCategoryIds(categories);
    if (categoryIds.isEmpty) return [];

    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/pois'),
        headers: {'Authorization': apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'request': 'pois',
          'geometry': {
            'geojson': {
              'type': 'Point',
              'coordinates': [location.longitude, location.latitude],
            },
            'buffer': radius.round().clamp(100, 5000),
          },
          'filters': {'category_ids': categoryIds},
          'limit': 20,
        }),
      );

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return [];

      final features = decoded['features'];
      if (features is! List) return [];

      return features.map(_parsePOIFeature).whereType<POI>().take(20).toList();
    } catch (e) {
      return [];
    }
  }

  List<int> _resolveCategoryIds(List<String> categories) {
    final ids = <int>{};

    for (final category in categories) {
      final normalized = category.trim().toLowerCase().replaceAll('-', '_');
      final id =
          _categoryIdsByName[normalized] ??
          _categoryIdsByName[normalized.replaceAll('_', ' ')];
      if (id != null) {
        ids.add(id);
      }
    }

    return ids.toList(growable: false);
  }

  POI? _parsePOIFeature(dynamic feature) {
    if (feature is! Map<String, dynamic>) return null;

    final geometry = feature['geometry'];
    if (geometry is! Map<String, dynamic>) return null;

    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) return null;

    final longitude = _asDouble(coordinates[0]);
    final latitude = _asDouble(coordinates[1]);
    if (longitude == null || latitude == null) return null;

    final properties = feature['properties'] is Map<String, dynamic>
        ? feature['properties'] as Map<String, dynamic>
        : <String, dynamic>{};
    final categoryId = _extractCategoryId(properties['category_ids']);
    final category = _categoryNamesById[categoryId] ?? 'point_of_interest';

    return POI(
      name: _extractPOIName(properties, category),
      location: LatLng(latitude, longitude),
      category: category,
    );
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _extractCategoryId(dynamic categoryIds) {
    if (categoryIds is Map) {
      for (final key in categoryIds.keys) {
        final id = int.tryParse(key.toString());
        if (id != null && _categoryNamesById.containsKey(id)) {
          return id;
        }
      }
    }

    if (categoryIds is List) {
      for (final value in categoryIds) {
        final id = value is int ? value : int.tryParse(value.toString());
        if (id != null && _categoryNamesById.containsKey(id)) {
          return id;
        }
      }
    }

    return null;
  }

  String _extractPOIName(Map<String, dynamic> properties, String category) {
    final directName = properties['name'];
    if (directName is String && directName.trim().isNotEmpty) {
      return directName.trim();
    }

    final osmTags = properties['osm_tags'];
    if (osmTags is Map) {
      final osmName = osmTags['name'];
      if (osmName is String && osmName.trim().isNotEmpty) {
        return osmName.trim();
      }
    }

    return category
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  /// Clears the map tile cache
  Future<void> clearCache() async {
    await _mapTileCache.emptyCache();
  }
}

/// Point of Interest model
class POI {
  final String name;
  final LatLng location;
  final String category;

  POI({required this.name, required this.location, required this.category});
}

/// Exception thrown when OpenRouteService API fails
class OpenRouteServiceException implements Exception {
  final String message;
  OpenRouteServiceException(this.message);

  @override
  String toString() => 'OpenRouteServiceException: $message';
}
