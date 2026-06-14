import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';
import 'package:flowfit/features/wellness/presentation/widgets/focus_mission_overlay.dart';

void main() {
  testWidgets('FocusMissionOverlay shows title, distance and buttons', (
    WidgetTester tester,
  ) async {
    final mission = GeofenceMission(
      id: 'm1',
      title: 'Test Mission',
      center: const LatLngSimple(0.0, 0.0),
      radiusMeters: 100,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FocusMissionOverlay(
                mission: mission,
                distanceMeters: 42.0,
                eta: const Duration(minutes: 1),
                isActive: false,
                speedMetersPerSecond: 1.4,
                onUnfocus: () {},
                onCenter: () {},
                onActivate: () async {},
                onDeactivate: () async {},
                onSpeedChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Test Mission'), findsOneWidget);
    expect(find.textContaining('42 m'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });
}
