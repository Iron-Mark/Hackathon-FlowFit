import 'package:flowfit/models/walking_route.dart';
import 'package:flowfit/services/calming_route_service.dart';
import 'package:flowfit/services/openroute_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('CalmingRouteService', () {
    const origin = LatLng(14.5995, 120.9842);

    test(
      'generates sorted offline route suggestions from nearby POIs',
      () async {
        final openRouteService = _FakeOpenRouteService([
          POI(
            name: 'Riverside Park',
            location: const LatLng(14.6001, 120.9845),
            category: 'park',
          ),
          POI(
            name: 'Botanical Garden',
            location: const LatLng(14.5988, 120.9838),
            category: 'garden',
          ),
          POI(
            name: 'Bay Walk',
            location: const LatLng(14.5998, 120.985),
            category: 'waterfront',
          ),
          POI(
            name: 'Quiet Reserve',
            location: const LatLng(14.599, 120.984),
            category: 'nature_reserve',
          ),
        ]);
        final service = CalmingRouteService(openRouteService);

        final routes = await service.generateCalmingRoutes(origin);

        expect(routes, hasLength(3));
        expect(routes.map((route) => route.name), [
          'Short Walk',
          'Medium Walk',
          'Long Walk',
        ]);
        expect(routes, isSortedByDescendingCalmScore);
        for (final route in routes) {
          expect(route.id, startsWith('route_'));
          expect(route.routePoints.length, greaterThanOrEqualTo(17));
          expect(route.distance, greaterThan(0));
          expect(route.duration, greaterThan(0));
          expect(route.calmScore, inInclusiveRange(0.0, 1.0));
          expect(route.greenSpacePercentage, inInclusiveRange(0.0, 1.0));
          expect(route.features, containsAll(['park', 'garden', 'waterfront']));
          expect(route.features, contains('quiet'));
          expect(route.description, contains('featuring'));
        }
        expect(openRouteService.requestedRadii, [1000.0, 2000.0, 3000.0]);
        expect(
          openRouteService.requestedCategories,
          everyElement(['park', 'garden', 'waterfront', 'nature_reserve']),
        );
      },
    );

    test(
      'falls back to neighborhood routes when no POIs are available',
      () async {
        final service = CalmingRouteService(_FakeOpenRouteService([]));

        final routes = await service.generateCalmingRoutes(origin);

        expect(routes, hasLength(3));
        for (final route in routes) {
          expect(route.routePoints, hasLength(17));
          expect(route.features, isEmpty);
          expect(route.description, contains('through your neighborhood'));
        }
      },
    );

    test('returns an empty list when POI lookup fails', () async {
      final service = CalmingRouteService(
        _FakeOpenRouteService([], shouldThrow: true),
      );

      await expectLater(service.generateCalmingRoutes(origin), completion([]));
    });
  });
}

final Matcher isSortedByDescendingCalmScore = predicate<List<WalkingRoute>>((
  routes,
) {
  for (var index = 1; index < routes.length; index += 1) {
    if (routes[index - 1].calmScore < routes[index].calmScore) {
      return false;
    }
  }
  return true;
}, 'routes sorted by descending calmScore');

class _FakeOpenRouteService extends OpenRouteService {
  _FakeOpenRouteService(this._pois, {this.shouldThrow = false});

  final List<POI> _pois;
  final bool shouldThrow;
  final requestedRadii = <double>[];
  final requestedCategories = <List<String>>[];

  @override
  Future<List<POI>> searchNearbyPOIs(
    LatLng location, {
    required double radius,
    required List<String> categories,
  }) async {
    requestedRadii.add(radius);
    requestedCategories.add(categories);

    if (shouldThrow) {
      throw OpenRouteServiceException('offline test failure');
    }

    return _pois;
  }
}
