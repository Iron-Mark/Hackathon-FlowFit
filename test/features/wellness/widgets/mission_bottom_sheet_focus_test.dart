import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flowfit/features/wellness/presentation/widgets/mission_bottom_sheet.dart';
// no additional imports required
import 'package:flowfit/features/wellness/data/geofence_repository.dart';
import 'package:flowfit/features/wellness/services/geofence_service.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';

void main() {
  testWidgets('Pressing focus button starts focus overlay', (
    WidgetTester tester,
  ) async {
    final repo = InMemoryGeofenceRepository();
    final service = GeofenceService(repository: repo);

    final mission = GeofenceMission(
      id: 'f1',
      title: 'Focus Mission',
      center: const LatLngSimple(0.0, 0.0),
      radiusMeters: 100,
      type: MissionType.sanctuary,
    );
    await repo.add(mission);

    bool focused = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<GeofenceRepository>.value(value: repo),
            ChangeNotifierProvider<GeofenceService>.value(value: service),
          ],
          child: Scaffold(
            body: MissionBottomSheet(
              repo: repo,
              service: service,
              mapController: null,
              lastCenter: null,
              onAddAtLatLng: (_) {},
              onOpenMission: (_) {},
              onFocusMission: (m) {
                focused = true;
              },
            ),
          ),
        ),
      ),
    );

    // Wait for the initial frame without waiting on draggable-sheet animations.
    await tester.pump();

    // Focus button exists
    final focusButton = find.widgetWithIcon(ElevatedButton, Icons.flag);
    expect(focusButton, findsWidgets);

    // Tap the first focus button
    await tester.tap(focusButton.first);
    // Let UI update only without waiting for background updates
    await tester.pump(const Duration(milliseconds: 200));

    // Verify callback invoked by clicking the icon
    expect(focused, true);
    focused = false;

    // Tap the mission row title which should also focus (primary action now)
    final titleTap = find.text('Focus Mission');
    expect(titleTap, findsOneWidget);
    await tester.tap(titleTap);
    await tester.pump(const Duration(milliseconds: 200));
    expect(focused, true);
  });
}
