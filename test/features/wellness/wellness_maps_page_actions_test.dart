import 'package:flowfit/features/wellness/data/geofence_repository.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';
import 'package:flowfit/features/wellness/presentation/maps_page.dart';
import 'package:flowfit/features/wellness/services/geofence_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
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

  testWidgets('WellnessMapsPage falls back when startup location fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final originalGeolocator = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = _ThrowingGeolocatorPlatform();
    addTearDown(() => GeolocatorPlatform.instance = originalGeolocator);

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
            enableLocationServices: true,
            renderMapLayers: false,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Skip Tutorial'));
    await tester.tap(find.text('Skip Tutorial'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pump();

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Fallback sanctuary');
    await tester.tap(find.text('Create'));
    await tester.pump();

    expect(repo.current, hasLength(1));
    expect(repo.current.single.title, 'Fallback sanctuary');
    expect(repo.current.single.center.latitude, 0);
    expect(repo.current.single.center.longitude, 0);
  });

  testWidgets('WellnessMapsPage focuses and toggles a seeded mission', (
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

    await repo.add(
      GeofenceMission(
        id: 'focus-1',
        title: 'Focus park',
        center: const LatLngSimple(14.5995, 120.9842),
        radiusMeters: 80,
        type: MissionType.sanctuary,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<GeofenceRepository>.value(value: repo),
            ChangeNotifierProvider<GeofenceService>.value(value: service),
          ],
          child: const WellnessMapsPage(
            initialCenter: maplat.LatLng(14.6, 120.985),
            enableLocationServices: false,
            renderMapLayers: false,
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Skip Tutorial'));
    await tester.tap(find.text('Skip Tutorial'));
    await tester.pumpAndSettle();

    expect(find.text('Focus park'), findsOneWidget);

    await tester.longPress(find.text('Focus park'));
    await tester.pumpAndSettle();

    expect(find.text('Focus & Navigate'), findsOneWidget);

    await tester.tap(find.text('Focus & Navigate'));
    await tester.pumpAndSettle();

    expect(repo.getById('focus-1')!.isActive, isTrue);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.textContaining('m • ETA'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Stop'));
    await tester.pumpAndSettle();

    expect(repo.getById('focus-1')!.isActive, isFalse);
    expect(find.text('Start'), findsOneWidget);

    await tester.drag(find.byType(Slider), const Offset(120, 0));
    await tester.pump();

    expect(find.textContaining('m/s'), findsWidgets);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
    await tester.pumpAndSettle();

    expect(repo.getById('focus-1')!.isActive, isTrue);
    expect(find.text('Stop'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Start'), findsNothing);
  });
}

class _ThrowingGeolocatorPlatform extends GeolocatorPlatform {
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    throw StateError('location unavailable');
  }
}
