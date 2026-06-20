import 'package:flowfit/features/wellness/data/geofence_repository.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';
import 'package:flowfit/features/wellness/presentation/maps_page.dart';
import 'package:flowfit/features/wellness/services/geofence_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as maplat;
import 'package:provider/provider.dart';

void main() {
  testWidgets('WellnessMapsPage creates a mission from the seeded center', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = InMemoryGeofenceRepository();
    final service = GeofenceService(repository: repo);

    addTearDown(service.dispose);
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<GeofenceRepository>.value(value: repo),
            ChangeNotifierProvider<GeofenceService>.value(value: service),
          ],
          child: const WellnessMapsPage(
            initialCenter: maplat.LatLng(14.5995, 120.9842),
            enableLocationServices: false,
            renderMapLayers: false,
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Skip Tutorial'));
    await tester.tap(find.text('Skip Tutorial'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pump();

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Morning sanctuary');
    await tester.tap(find.text('Create'));
    await tester.pump();

    expect(repo.current, hasLength(1));
    expect(repo.current.single.title, 'Morning sanctuary');
    expect(repo.current.single.type, MissionType.sanctuary);
    expect(repo.current.single.center.latitude, 14.5995);
    expect(repo.current.single.center.longitude, 120.9842);
    expect(find.text('Mission added'), findsOneWidget);
  });
}
