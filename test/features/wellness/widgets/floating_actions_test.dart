import 'dart:async';

import 'package:flowfit/features/wellness/presentation/widgets/floating_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as maplat;

void main() {
  testWidgets('FloatingMapActions reports when map controller is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FloatingMapActions(
                mapController: null,
                lastCenter: null,
                onAddAtLatLng: (_) async {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pump();

    expect(find.text('Map is still loading. Try again soon.'), findsOneWidget);
  });

  testWidgets('FloatingMapActions reports when visible center is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FloatingMapActions(
                mapController: null,
                lastCenter: null,
                onAddAtLatLng: (_) async {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('Map center is not ready yet.'), findsOneWidget);
  });

  testWidgets('FloatingMapActions adds at the visible center', (tester) async {
    maplat.LatLng? addedAt;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FloatingMapActions(
                mapController: null,
                lastCenter: const maplat.LatLng(14.5995, 120.9842),
                onAddAtLatLng: (latLng) async {
                  addedAt = latLng;
                },
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(addedAt, isNotNull);
    expect(addedAt!.latitude, 14.5995);
    expect(addedAt!.longitude, 120.9842);
  });

  testWidgets('FloatingMapActions ignores duplicate add taps while pending', (
    tester,
  ) async {
    final addCompleter = Completer<void>();
    var addCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FloatingMapActions(
                mapController: null,
                lastCenter: const maplat.LatLng(14.5995, 120.9842),
                onAddAtLatLng: (_) {
                  addCalls += 1;
                  return addCompleter.future;
                },
              ),
            ],
          ),
        ),
      ),
    );

    final addButton = find.byIcon(Icons.add);
    await tester.tap(addButton);
    await tester.tap(addButton);
    await tester.pump();

    expect(addCalls, 1);

    addCompleter.complete();
    await tester.pump();
  });

  testWidgets(
    'FloatingMapActions ignores duplicate location taps while pending',
    (tester) async {
      final locationCompleter = Completer<maplat.LatLng>();
      var locationCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                FloatingMapActions(
                  mapController: MapController(),
                  lastCenter: null,
                  currentLocationGetter: () {
                    locationCalls += 1;
                    return locationCompleter.future;
                  },
                  onAddAtLatLng: (_) async {},
                ),
              ],
            ),
          ),
        ),
      );

      final centerButton = find.byIcon(Icons.my_location);
      await tester.tap(centerButton);
      await tester.tap(centerButton);
      await tester.pump();

      expect(locationCalls, 1);

      locationCompleter.complete(const maplat.LatLng(14.5995, 120.9842));
      await tester.pump();
    },
  );
}
