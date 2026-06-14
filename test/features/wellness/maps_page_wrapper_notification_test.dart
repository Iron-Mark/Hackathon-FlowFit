import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/features/wellness/presentation/maps_page_wrapper.dart';
import 'package:flowfit/features/wellness/data/geofence_repository.dart';
import 'package:flowfit/features/wellness/services/geofence_service.dart';

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
}
