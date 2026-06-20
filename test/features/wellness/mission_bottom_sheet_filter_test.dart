import 'package:flowfit/features/wellness/data/geofence_repository.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';
import 'package:flowfit/features/wellness/presentation/widgets/mission_bottom_sheet.dart';
import 'package:flowfit/features/wellness/services/geofence_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('mission filter narrows the visible mission list', (
    tester,
  ) async {
    final repo = InMemoryGeofenceRepository();
    final service = GeofenceService(repository: repo);

    await repo.add(
      GeofenceMission(
        id: 'target-1',
        title: 'Target Walk',
        center: const LatLngSimple(0, 0),
        type: MissionType.target,
        targetDistanceMeters: 100,
      ),
    );
    await repo.add(
      GeofenceMission(
        id: 'sanctuary-1',
        title: 'Calm Place',
        center: const LatLngSimple(1, 1),
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
          child: Scaffold(
            body: MissionBottomSheet(
              repo: repo,
              service: service,
              mapController: null,
              lastCenter: null,
              onAddAtLatLng: (_) {},
              onOpenMission: (_) {},
              onFocusMission: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Target Walk'), findsOneWidget);
    expect(find.text('2 missions'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'All'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Target'));
    await tester.pumpAndSettle();

    expect(find.text('Target Walk'), findsOneWidget);
    expect(find.text('Calm Place'), findsNothing);
    expect(find.text('1 of 2 missions'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Target'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sanctuary'));
    await tester.pumpAndSettle();

    expect(find.text('Target Walk'), findsNothing);
    expect(find.text('Calm Place'), findsOneWidget);
    expect(find.text('1 of 2 missions'), findsOneWidget);

    service.dispose();
    repo.dispose();
  });

  testWidgets('mission delete can be cancelled', (tester) async {
    final repo = InMemoryGeofenceRepository();
    final service = GeofenceService(repository: repo);
    await _seedMission(repo);

    await _pumpMissionBottomSheet(tester, repo: repo, service: service);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delete Mission?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(repo.getById('target-1'), isNotNull);
    expect(find.text('Target Walk'), findsOneWidget);

    service.dispose();
    repo.dispose();
  });

  testWidgets('mission delete confirms before removing the mission', (
    tester,
  ) async {
    final repo = InMemoryGeofenceRepository();
    final service = GeofenceService(repository: repo);
    await _seedMission(repo);

    await _pumpMissionBottomSheet(tester, repo: repo, service: service);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repo.getById('target-1'), isNull);
    expect(find.text('Target Walk'), findsNothing);
    expect(find.text('"Target Walk" deleted'), findsOneWidget);

    service.dispose();
    repo.dispose();
  });

  testWidgets('mission delete failure keeps the mission visible', (
    tester,
  ) async {
    final repo = _FailingDeleteGeofenceRepository();
    final service = GeofenceService(repository: repo);
    await _seedMission(repo);

    await _pumpMissionBottomSheet(tester, repo: repo, service: service);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repo.getById('target-1'), isNotNull);
    expect(find.text('Target Walk'), findsOneWidget);
    expect(find.text('Could not delete mission. Try again.'), findsOneWidget);

    service.dispose();
    repo.dispose();
  });
}

Future<void> _pumpMissionBottomSheet(
  WidgetTester tester, {
  required GeofenceRepository repo,
  required GeofenceService service,
}) async {
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
            onFocusMission: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _seedMission(GeofenceRepository repo) {
  return repo.add(
    GeofenceMission(
      id: 'target-1',
      title: 'Target Walk',
      center: const LatLngSimple(0, 0),
      type: MissionType.target,
      targetDistanceMeters: 100,
    ),
  );
}

class _FailingDeleteGeofenceRepository extends InMemoryGeofenceRepository {
  @override
  Future<void> delete(String id) async {
    throw StateError('delete failed');
  }
}
