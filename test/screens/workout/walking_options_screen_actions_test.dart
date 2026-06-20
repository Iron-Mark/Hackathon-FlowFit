import 'dart:async';

import 'package:flowfit/providers/running_session_provider.dart';
import 'package:flowfit/screens/workout/walking/walking_options_screen.dart';
import 'package:flowfit/services/gps_tracking_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  Widget buildHarness() {
    return ProviderScope(
      overrides: [
        gpsTrackingServiceProvider.overrideWithValue(_FakeGpsTrackingService()),
      ],
      child: const MaterialApp(home: WalkingOptionsScreen()),
    );
  }

  testWidgets('Create Mission opens target mission setup', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create Mission'));
    await tester.tap(find.text('Create Mission'));
    await tester.pumpAndSettle();

    expect(find.text('Target Distance'), findsOneWidget);
    expect(find.text('Mission Name'), findsOneWidget);
    expect(find.text('Start Mission'), findsOneWidget);
  });

  testWidgets('selected Safety Net type opens safety radius setup', (
    tester,
  ) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Safety Net'));
    await tester.tap(find.text('Safety Net'));
    await tester.ensureVisible(find.text('Create Mission'));
    await tester.tap(find.text('Create Mission'));
    await tester.pumpAndSettle();

    expect(find.text('Safe Zone Radius'), findsOneWidget);
    expect(find.text('Start Mission'), findsOneWidget);
  });
}

class _FakeGpsTrackingService extends GPSTrackingService {
  final StreamController<LatLng> _controller =
      StreamController<LatLng>.broadcast();

  @override
  Stream<LatLng> get locationStream => _controller.stream;

  @override
  Future<LatLng> getCurrentLocation() async => const LatLng(14.5995, 120.9842);

  @override
  Future<void> startTracking() async {}

  @override
  Future<void> stopTracking() async {}

  @override
  void dispose() {
    _controller.close();
  }
}
