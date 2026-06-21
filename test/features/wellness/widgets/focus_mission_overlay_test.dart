import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';
import 'package:flowfit/features/wellness/presentation/widgets/focus_mission_overlay.dart';

void main() {
  testWidgets('FocusMissionOverlay wires center, close, start, and speed', (
    WidgetTester tester,
  ) async {
    final mission = GeofenceMission(
      id: 'm1',
      title: 'Test Mission',
      center: const LatLngSimple(0.0, 0.0),
      radiusMeters: 100,
    );
    var centerCalls = 0;
    var unfocusCalls = 0;
    var activateCalls = 0;
    var speed = 1.4;

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
                speedMetersPerSecond: speed,
                onUnfocus: () => unfocusCalls++,
                onCenter: () => centerCalls++,
                onActivate: () async => activateCalls++,
                onDeactivate: () async {},
                onSpeedChanged: (value) => speed = value,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Test Mission'), findsOneWidget);
    expect(find.textContaining('42 m'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.my_location));
    await tester.tap(find.byIcon(Icons.close));
    await tester.drag(find.byType(Slider), const Offset(180, 0));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
    await tester.pumpAndSettle();

    expect(centerCalls, 1);
    expect(unfocusCalls, 1);
    expect(activateCalls, 1);
    expect(speed, isNot(1.4));
  });

  testWidgets('FocusMissionOverlay active button deactivates mission', (
    WidgetTester tester,
  ) async {
    final mission = GeofenceMission(
      id: 'm1',
      title: 'Test Mission',
      center: const LatLngSimple(0.0, 0.0),
      radiusMeters: 100,
    );
    var deactivateCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FocusMissionOverlay(
                mission: mission,
                distanceMeters: 42.0,
                eta: const Duration(minutes: 1),
                isActive: true,
                speedMetersPerSecond: 1.4,
                onUnfocus: () {},
                onCenter: () {},
                onActivate: () async {},
                onDeactivate: () async => deactivateCalls++,
                onSpeedChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Stop'));
    await tester.pumpAndSettle();

    expect(deactivateCalls, 1);
  });
}
