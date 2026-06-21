import 'package:flowfit/features/wellness/domain/geofence_mission.dart';
import 'package:flowfit/features/wellness/presentation/widgets/map_components.dart';
import 'package:flowfit/features/wellness/presentation/widgets/map_tutorial_overlay.dart';
import 'package:flowfit/features/wellness/presentation/widgets/top_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as maplat;

void main() {
  testWidgets('MapTutorialOverlay dismisses from primary and skip actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var dismissCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapTutorialOverlay(onDismiss: () => dismissCalls++),
        ),
      ),
    );

    expect(find.textContaining('Welcome to Map Missions'), findsOneWidget);

    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
    await tester.pump();

    await tester.ensureVisible(find.text('Skip Tutorial'));
    await tester.tap(find.widgetWithText(TextButton, 'Skip Tutorial'));
    await tester.pump();

    expect(dismissCalls, 2);
  });

  testWidgets('TopActionButton exposes tooltip and invokes tap action', (
    tester,
  ) async {
    var tapCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TopActionButton(
              icon: Icons.my_location,
              label: 'Center map',
              onTap: () => tapCalls++,
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Center map'), findsOneWidget);

    await tester.tap(find.byTooltip('Center map'));
    await tester.pump();

    expect(tapCalls, 1);
  });

  testWidgets('map_components mission marker uses position and handles taps', (
    tester,
  ) async {
    var tapCalls = 0;
    final mission = GeofenceMission(
      id: 'mission-1',
      title: 'Park loop',
      center: const LatLngSimple(14.5995, 120.9842),
      radiusMeters: 80,
    );
    final marker = buildMissionMarker(mission, () => tapCalls++);

    expect(marker.point.latitude, 14.5995);
    expect(marker.point.longitude, 120.9842);
    expect(marker.width, 36);
    expect(marker.height, 36);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: marker.child)),
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(tapCalls, 1);
  });

  test('map_components preview marker and circles preserve map geometry', () {
    const previewPoint = maplat.LatLng(14.6, 120.98);
    final previewMarker = buildPreviewMarker(previewPoint);
    final previewCircle = buildPreviewCircle(previewPoint, 125);
    final missionCircle = buildMissionCircle(
      GeofenceMission(
        id: 'mission-1',
        title: 'Park loop',
        center: const LatLngSimple(14.5995, 120.9842),
        radiusMeters: 80,
      ),
    );

    expect(previewMarker.point, previewPoint);
    expect(previewCircle.point, previewPoint);
    expect(previewCircle.radius, 125);
    expect(missionCircle.point.latitude, 14.5995);
    expect(missionCircle.point.longitude, 120.9842);
    expect(missionCircle.radius, 80);
  });
}
