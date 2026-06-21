import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/features/wellness/presentation/maps_page_wrapper.dart';
import 'package:flowfit/features/wellness/data/geofence_repository.dart';
import 'package:flowfit/features/wellness/services/geofence_service.dart';
import 'package:flutter/material.dart';

void main() {
  test('wellness notification tap payloads request mission focus', () async {
    final repo = InMemoryGeofenceRepository();
    final service = GeofenceService(repository: repo);
    final events = <String>[];
    final sub = service.focusRequests.listen(events.add);

    routeWellnessNotificationTap('focus:m1', service);
    routeWellnessNotificationTap('add_sanctuary', service);
    routeWellnessNotificationTap('', service);

    await pumpEventQueue();

    expect(events, ['m1', 'add_sanctuary']);

    await sub.cancel();
    service.dispose();
    repo.dispose();
  });

  testWidgets('device-free wrapper renders wellness map actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MapsPageWrapper(
          autoStartMoodTracker: false,
          enableDeviceServices: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(MapsPageWrapper), findsOneWidget);
    expect(find.text('Missions'), findsOneWidget);
    expect(find.text('0 missions'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.byTooltip('Hide'), findsOneWidget);
    expect(
      find.text(
        'No missions yet. Long-press on the map or tap Add to create a mission.',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Skip Tutorial'));
    await tester.pump();
    await tester.tap(find.text('Skip Tutorial'));
    await tester.pump();

    await tester.tap(find.byTooltip('Hide'));
    await tester.pump();

    expect(find.text('Missions'), findsNothing);
    expect(find.byTooltip('Show'), findsOneWidget);
  });
}
