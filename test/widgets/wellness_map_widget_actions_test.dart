import 'dart:async';

import 'package:flowfit/models/wellness_state.dart';
import 'package:flowfit/services/gps_tracking_service.dart';
import 'package:flowfit/widgets/wellness/wellness_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets('location disclosure decline shows retry and retry loads map', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final gpsService = _FakeGpsTrackingService(hasPermission: false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 430,
            height: 500,
            child: WellnessMapWidget(
              state: WellnessState.calm,
              gpsService: gpsService,
            ),
          ),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.text('Use Location for Wellness Missions?'), findsOneWidget);

    await tester.tap(find.text('Not Now'));
    await _pumpFrames(tester);

    expect(
      find.text(
        'Location access is needed for wellness routes, walking paths, and geofence missions.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    gpsService.hasPermission = true;
    await tester.tap(find.text('Retry'));
    await _pumpFrames(tester, 6);

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(gpsService.currentLocationCalls, 1);
    expect(gpsService.startTrackingCalls, 1);
  });

  testWidgets(
    'location disclosure continue requests permission and loads map',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final gpsService = _FakeGpsTrackingService(hasPermission: false);
      gpsService.requestPermissionResult = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 430,
              height: 500,
              child: WellnessMapWidget(
                state: WellnessState.calm,
                gpsService: gpsService,
              ),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.text('Use Location for Wellness Missions?'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await _pumpFrames(tester, 6);

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(gpsService.permissionRequestCalls, 1);
      expect(gpsService.currentLocationCalls, 1);
      expect(gpsService.startTrackingCalls, 1);
    },
  );

  testWidgets('clear path action resets tracked GPS path', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final gpsService = _FakeGpsTrackingService(hasPermission: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 430,
            height: 500,
            child: WellnessMapWidget(
              state: WellnessState.calm,
              gpsService: gpsService,
            ),
          ),
        ),
      ),
    );
    await _pumpFrames(tester, 6);

    expect(find.byType(FlutterMap), findsOneWidget);

    gpsService.emit(const LatLng(14.6000, 120.9850));
    gpsService.emit(const LatLng(14.6010, 120.9860));
    await _pumpFrames(tester);

    expect(find.text('3 points'), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await _pumpFrames(tester);

    expect(find.text('3 points'), findsNothing);
    expect(find.byIcon(Icons.clear), findsNothing);
  });
}

Future<void> _pumpFrames(WidgetTester tester, [int frameCount = 3]) async {
  for (var i = 0; i < frameCount; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _FakeGpsTrackingService extends GPSTrackingService {
  _FakeGpsTrackingService({required this.hasPermission});

  final StreamController<LatLng> _controller =
      StreamController<LatLng>.broadcast();
  bool hasPermission;
  bool? requestPermissionResult;
  var permissionRequestCalls = 0;
  var currentLocationCalls = 0;
  var startTrackingCalls = 0;
  var stopTrackingCalls = 0;
  var disposed = false;

  void emit(LatLng location) {
    _controller.add(location);
  }

  @override
  Stream<LatLng> get locationStream => _controller.stream;

  @override
  Future<bool> hasLocationPermission() async => hasPermission;

  @override
  Future<bool> requestLocationPermission() async {
    permissionRequestCalls++;
    hasPermission = requestPermissionResult ?? hasPermission;
    return hasPermission;
  }

  @override
  Future<LatLng> getCurrentLocation() async {
    currentLocationCalls++;
    return const LatLng(14.5995, 120.9842);
  }

  @override
  Future<void> startTracking() async {
    startTrackingCalls++;
  }

  @override
  Future<void> stopTracking() async {
    stopTrackingCalls++;
  }

  @override
  double calculateRouteDistance(List<LatLng> routePoints) =>
      routePoints.length.toDouble();

  @override
  void dispose() {
    disposed = true;
    _controller.close();
  }
}
