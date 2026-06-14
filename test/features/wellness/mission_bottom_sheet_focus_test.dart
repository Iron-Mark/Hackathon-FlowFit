import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/features/wellness/data/geofence_repository.dart';
import 'package:provider/provider.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';
import 'package:flowfit/features/wellness/presentation/widgets/focus_mission_overlay.dart';
import 'package:flowfit/features/wellness/presentation/widgets/mission_bottom_sheet.dart';
import 'package:flowfit/features/wellness/services/geofence_service.dart';

void main() {
  testWidgets('Pressing Focus & Navigate triggers FocusMissionOverlay', (
    WidgetTester tester,
  ) async {
    final repo = InMemoryGeofenceRepository();
    final service = GeofenceService(repository: repo);
    final mission = GeofenceMission(
      id: 'm1',
      title: 'Test M',
      center: const LatLngSimple(0.0, 0.0),
      radiusMeters: 50,
    );
    await repo.add(mission);

    await tester.pumpWidget(
      MaterialApp(
        home: _MissionFocusHarness(repo: repo, service: service),
      ),
    );
    await tester.pump();

    final flagFinder = find.widgetWithIcon(ElevatedButton, Icons.flag).first;
    expect(flagFinder, findsOneWidget);

    await tester.tap(flagFinder);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(FocusMissionOverlay), findsOneWidget);
    expect(find.text('Test M'), findsWidgets);

    service.dispose();
    repo.dispose();
  });
}

class _MissionFocusHarness extends StatefulWidget {
  const _MissionFocusHarness({required this.repo, required this.service});

  final GeofenceRepository repo;
  final GeofenceService service;

  @override
  State<_MissionFocusHarness> createState() => _MissionFocusHarnessState();
}

class _MissionFocusHarnessState extends State<_MissionFocusHarness> {
  GeofenceMission? _focusedMission;

  @override
  Widget build(BuildContext context) {
    final focusedMission = _focusedMission;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GeofenceRepository>.value(value: widget.repo),
        ChangeNotifierProvider<GeofenceService>.value(value: widget.service),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            MissionBottomSheet(
              repo: widget.repo,
              service: widget.service,
              mapController: null,
              lastCenter: null,
              onAddAtLatLng: (_) {},
              onOpenMission: (_) {},
              onFocusMission: (mission) {
                setState(() => _focusedMission = mission);
              },
            ),
            if (focusedMission != null)
              FocusMissionOverlay(
                mission: focusedMission,
                distanceMeters: 0,
                eta: Duration.zero,
                isActive: focusedMission.isActive,
                speedMetersPerSecond: 1.4,
                onUnfocus: () => setState(() => _focusedMission = null),
                onCenter: () {},
                onActivate: () {},
                onDeactivate: () {},
                onSpeedChanged: (_) {},
              ),
          ],
        ),
      ),
    );
  }
}
