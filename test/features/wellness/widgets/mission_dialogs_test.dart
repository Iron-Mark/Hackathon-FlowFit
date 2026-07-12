import 'package:flowfit/features/wellness/domain/geofence_mission.dart';
import 'package:flowfit/features/wellness/presentation/widgets/edit_mission_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EditMissionDialog keeps original title when submitted blank', (
    tester,
  ) async {
    GeofenceMission? saved;
    final mission = GeofenceMission(
      id: 'mission-1',
      title: 'Original mission',
      description: 'Before edit',
      center: const LatLngSimple(1, 2),
      radiusMeters: 80,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  saved = await showDialog<GeofenceMission>(
                    context: context,
                    builder: (_) => EditMissionDialog(mission: mission),
                  );
                },
                child: const Text('Open edit'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open edit'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '   ');
    await tester.enterText(find.byType(TextField).at(1), '   ');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.title, 'Original mission');
    expect(saved!.description, isNull);
  });

  testWidgets('EditMissionDialog cancel returns no mission update', (
    tester,
  ) async {
    GeofenceMission? saved;
    var dialogClosed = false;
    final mission = GeofenceMission(
      id: 'mission-1',
      title: 'Original mission',
      description: 'Before edit',
      center: const LatLngSimple(1, 2),
      radiusMeters: 80,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  saved = await showDialog<GeofenceMission>(
                    context: context,
                    builder: (_) => EditMissionDialog(mission: mission),
                  );
                  dialogClosed = true;
                },
                child: const Text('Open edit'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open edit'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Changed mission');
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(dialogClosed, isTrue);
    expect(saved, isNull);
    expect(find.text('Changed mission'), findsNothing);
  });
}
