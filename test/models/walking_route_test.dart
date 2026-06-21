import 'package:flowfit/models/walking_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('WalkingRoute', () {
    WalkingRoute route({double distance = 2.0}) {
      return WalkingRoute(
        id: 'route-1',
        name: 'Park Loop',
        routePoints: const [LatLng(14.5995, 120.9842), LatLng(14.6, 120.99)],
        distance: distance,
        duration: 25,
        calmScore: 0.82,
        greenSpacePercentage: 0.7,
        description: 'A medium walk featuring park and waterfront',
        features: const ['park', 'waterfront'],
      );
    }

    test('derives difficulty and estimated calories from distance', () {
      expect(route(distance: 1.4).difficulty, 'Easy');
      expect(route(distance: 1.5).difficulty, 'Moderate');
      expect(route(distance: 2.4).difficulty, 'Moderate');
      expect(route(distance: 2.5).difficulty, 'Challenging');

      expect(route(distance: 2.25).estimatedCalories, 113);
    });

    test('round-trips JSON and accepts integer route coordinates', () {
      final parsed = WalkingRoute.fromJson({
        'id': 'route-json',
        'name': 'Integer Coordinate Loop',
        'route_points': [
          {'lat': 14, 'lng': 120},
          {'lat': 14.5, 'lng': 120.5},
        ],
        'distance': 1,
        'duration': 12,
        'calm_score': 0.6,
        'green_space_percentage': 0.4,
        'features': ['park'],
      });

      expect(parsed.routePoints.first.latitude, 14.0);
      expect(parsed.routePoints.first.longitude, 120.0);
      expect(parsed.distance, 1.0);
      expect(parsed.calmScore, 0.6);

      final encoded = route().toJson();
      final roundTripped = WalkingRoute.fromJson(encoded);

      expect(roundTripped, route());
      expect(roundTripped.routePoints, route().routePoints);
      expect(roundTripped.features, route().features);
      expect(roundTripped.description, route().description);
    });

    test('copyWith updates selected fields without losing route context', () {
      final copied = route().copyWith(
        name: 'Garden Loop',
        distance: 3.0,
        features: const ['garden'],
      );

      expect(copied.id, 'route-1');
      expect(copied.name, 'Garden Loop');
      expect(copied.distance, 3.0);
      expect(copied.duration, 25);
      expect(copied.features, ['garden']);
      expect(copied.description, route().description);
    });

    test(
      'rejects invalid scores and negative measurements in debug builds',
      () {
        expect(
          () => WalkingRoute(
            id: 'bad-distance',
            name: 'Bad Distance',
            routePoints: const [],
            distance: -0.1,
            duration: 10,
            calmScore: 0.5,
            greenSpacePercentage: 0.5,
          ),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => WalkingRoute(
            id: 'bad-score',
            name: 'Bad Score',
            routePoints: const [],
            distance: 1,
            duration: 10,
            calmScore: 1.1,
            greenSpacePercentage: 0.5,
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );
  });
}
