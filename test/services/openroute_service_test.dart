import 'dart:convert';

import 'package:flowfit/services/openroute_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('OpenRouteService POI search', () {
    test(
      'requests nearby POIs with buffered GeoJSON and category IDs',
      () async {
        Uri? requestUrl;
        Map<String, dynamic>? requestBody;
        Map<String, String>? requestHeaders;

        final service = OpenRouteService(
          httpClient: MockClient((request) async {
            requestUrl = request.url;
            requestHeaders = request.headers;
            requestBody = jsonDecode(request.body) as Map<String, dynamic>;

            return http.Response(
              jsonEncode({
                'type': 'FeatureCollection',
                'features': [
                  {
                    'type': 'Feature',
                    'geometry': {
                      'type': 'Point',
                      'coordinates': [120.9842, 14.5995],
                    },
                    'properties': {
                      'osm_tags': {'name': 'Rizal Park'},
                      'category_ids': {
                        '280': {'category_name': 'parks'},
                      },
                    },
                  },
                ],
              }),
              200,
            );
          }),
        );

        final pois = await service.searchNearbyPOIs(
          const LatLng(14.5995, 120.9842),
          radius: 1500,
          categories: ['park', 'garden', 'waterfront'],
        );

        expect(requestUrl?.path, '/pois');
        expect(requestHeaders?['Authorization'], OpenRouteService.apiKey);
        expect(requestBody?['request'], 'pois');
        expect(requestBody?['geometry']['geojson']['coordinates'], [
          120.9842,
          14.5995,
        ]);
        expect(requestBody?['geometry']['buffer'], 1500);
        expect(
          requestBody?['filters']['category_ids'],
          containsAll(<int>[272, 280, 340]),
        );
        expect(pois, hasLength(1));
        expect(pois.single.name, 'Rizal Park');
        expect(pois.single.category, 'park');
        expect(pois.single.location.latitude, 14.5995);
        expect(pois.single.location.longitude, 120.9842);
      },
    );

    test('returns an empty list when the API is unavailable', () async {
      final service = OpenRouteService(
        httpClient: MockClient((request) async => http.Response('fail', 503)),
      );

      final pois = await service.searchNearbyPOIs(
        const LatLng(14.5995, 120.9842),
        radius: 1500,
        categories: ['park'],
      );

      expect(pois, isEmpty);
    });

    test('does not call the API for unsupported categories', () async {
      var called = false;
      final service = OpenRouteService(
        httpClient: MockClient((request) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );

      final pois = await service.searchNearbyPOIs(
        const LatLng(14.5995, 120.9842),
        radius: 1500,
        categories: ['unknown'],
      );

      expect(called, isFalse);
      expect(pois, isEmpty);
    });
  });
}
