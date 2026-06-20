import 'package:flowfit/features/wellness/presentation/widgets/floating_actions.dart';
import 'package:flutter/material.dart';
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
}
