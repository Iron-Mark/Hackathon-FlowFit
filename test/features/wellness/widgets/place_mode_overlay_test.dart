import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as maplat;
import 'package:flowfit/features/wellness/presentation/widgets/place_mode_overlay.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';

void main() {
  testWidgets('PlaceModeOverlay wires edit, radius, type, cancel, and create', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var radius = 100.0;
    var selectedType = MissionType.sanctuary;
    var cancelCalls = 0;
    var confirmCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              PlaceModeOverlay(
                visible: true,
                latLng: const maplat.LatLng(1.0, 1.0),
                radius: radius,
                titleController: controller,
                type: selectedType,
                onRadiusChanged: (value) => radius = value,
                onTypeChanged: (value) {
                  if (value != null) {
                    selectedType = value;
                  }
                },
                onCancel: () => cancelCalls++,
                onConfirm: () => confirmCalls++,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(1)); // Title field
    expect(find.text('Radius'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.byType(DropdownButton<MissionType>), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Morning walk');
    await tester.drag(find.byType(Slider), const Offset(120, 0));
    await tester.pump();

    await tester.tap(find.byType(DropdownButton<MissionType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(MissionType.target.name).last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));
    await tester.pumpAndSettle();

    expect(controller.text, 'Morning walk');
    expect(radius, isNot(100));
    expect(selectedType, MissionType.target);
    expect(cancelCalls, 1);
    expect(confirmCalls, 1);
  });
}
