import 'package:flowfit/features/wellness/domain/geofence_mission.dart';
import 'package:flowfit/features/wellness/presentation/maps_page_wrapper.dart';
import 'package:flowfit/providers/geofence_repository_provider.dart';
import 'package:flowfit/providers/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'missions survive a route unmount via the app-scoped repository',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      Widget wrapperUnderContainer() => UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: MapsPageWrapper(
            autoStartMoodTracker: false,
            enableDeviceServices: false,
          ),
        ),
      );

      await tester.pumpWidget(wrapperUnderContainer());
      await tester.pump();

      expect(find.text('0 missions'), findsOneWidget);

      // Mutate through the shared repository directly — the '/mission' route's
      // creation dialogs are covered by their own focused widget tests.
      await container
          .read(geofenceRepositoryProvider)
          .add(
            GeofenceMission(
              id: 'persist-1',
              title: 'Park Sanctuary',
              center: const LatLng(0, 0),
            ),
          );
      await tester.pump();

      expect(find.text('1 missions'), findsOneWidget);

      // Unmount the route entirely (simulates popping '/mission')...
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();
      expect(find.byType(MapsPageWrapper), findsNothing);

      // ...then remount a fresh wrapper under the SAME container. The mission
      // must still be listed because the repository outlives the route.
      await tester.pumpWidget(wrapperUnderContainer());
      await tester.pump();

      expect(find.text('1 missions'), findsOneWidget);
    },
  );
}
