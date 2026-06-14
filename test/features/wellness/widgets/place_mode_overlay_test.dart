import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as maplat;
import 'package:flowfit/features/wellness/presentation/widgets/place_mode_overlay.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';

void main() {
  testWidgets('PlaceModeOverlay shows fields and buttons', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              PlaceModeOverlay(
                visible: true,
                latLng: const maplat.LatLng(1.0, 1.0),
                radius: 100,
                titleController: controller,
                type: MissionType.sanctuary,
                onRadiusChanged: (_) {},
                onTypeChanged: (_) {},
                onCancel: () {},
                onConfirm: () {},
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
  });
}
