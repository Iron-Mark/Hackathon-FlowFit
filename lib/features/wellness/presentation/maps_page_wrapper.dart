import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:provider/provider.dart';
import 'package:flowfit/providers/geofence_repository_provider.dart';
import 'package:flowfit/services/sensors/watch_bridge.dart';
import 'package:flowfit/models/heart_rate_data.dart' as hr_model;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as maplat;
import 'package:flowfit/features/wellness/data/geofence_repository.dart';
import 'package:flowfit/features/wellness/services/geofence_service.dart';
import 'package:flowfit/features/wellness/presentation/maps_page.dart';
import 'package:flowfit/features/wellness/services/notification_service.dart';
import 'package:flowfit/features/wellness/services/mood_tracker_service.dart';

void routeWellnessNotificationTap(String payload, GeofenceService service) {
  if (payload.isEmpty) return;
  if (payload.startsWith('focus:')) {
    final id = payload.replaceFirst('focus:', '');
    service.requestFocus(id);
  } else if (payload == 'add_sanctuary') {
    service.requestFocus('add_sanctuary');
  }
}

class MapsPageWrapper extends StatefulWidget {
  final bool autoStartMoodTracker;
  final bool enableDeviceServices;

  const MapsPageWrapper({
    super.key,
    this.autoStartMoodTracker = true,
    this.enableDeviceServices = true,
  });

  @override
  State<MapsPageWrapper> createState() => _MapsPageWrapperState();
}

class _MapsPageWrapperState extends State<MapsPageWrapper> {
  late final GeofenceRepository _repo;
  late final bool _ownsRepo;
  late final GeofenceService _service;
  WatchBridgeService? _watchBridge;
  late final MoodTrackerService _moodTracker;
  StreamSubscription<String>? _notificationTapSub;

  @override
  void initState() {
    super.initState();
    // Prefer the app-scoped persistent repository when a Riverpod
    // ProviderScope is available (the production route table). Widget tests
    // that pump the wrapper bare — or scopes without a SharedPreferences
    // override — fall back to a route-owned in-memory repository unchanged.
    try {
      _repo = ProviderScope.containerOf(
        context,
        listen: false,
      ).read(geofenceRepositoryProvider);
      _ownsRepo = false;
    } catch (_) {
      _repo = InMemoryGeofenceRepository();
      _ownsRepo = true;
    }
    _service = GeofenceService(repository: _repo);
    final watchBridge = widget.enableDeviceServices
        ? WatchBridgeService()
        : null;
    _watchBridge = watchBridge;

    // transform heart rate stream to mood stream using a simple heuristic
    Stream<MoodState> hrToMood(Stream<hr_model.HeartRateData> s) {
      // default threshold for stress
      const baseThreshold = 100.0;
      return s.map((hr) {
        final bpm = hr.bpm ?? 0;
        if (bpm >= baseThreshold) return MoodState.stressed;
        if (bpm < 70) return MoodState.calm;
        return MoodState.neutral;
      });
    }

    _moodTracker = MoodTrackerService(
      repository: _repo,
      service: _service,
      moodStreamOverride: watchBridge == null
          ? const Stream<MoodState>.empty()
          : hrToMood(watchBridge.heartRateStream),
      currentPositionGetter: widget.enableDeviceServices
          ? () async => await Geolocator.getCurrentPosition()
          : null,
    );
    if (widget.enableDeviceServices) {
      // Initialize notifications and start mood tracking (best-effort)
      NotificationService.init();
      // Start watch permission/connection monitoring and attempt to start HR tracking
      watchBridge?.startPermissionMonitoring();
      watchBridge?.startConnectionMonitoring();
      try {
        watchBridge?.connectToWatch().then((connected) {
          if (connected) watchBridge.startHeartRateTracking();
        });
      } catch (_) {}
    }
    if (widget.autoStartMoodTracker) {
      _moodTracker.startMonitoring();
    }
    _notificationTapSub = NotificationService.onNotificationTap.listen((
      payload,
    ) {
      routeWellnessNotificationTap(payload, _service);
    });
  }

  @override
  void dispose() {
    _notificationTapSub?.cancel();
    unawaited(
      _moodTracker.stopMonitoring().catchError((
        Object error,
        StackTrace stack,
      ) {
        debugPrint('MapsPageWrapper: stopMonitoring failed: $error');
      }),
    );
    _watchBridge?.stopPermissionMonitoring();
    _watchBridge?.stopConnectionMonitoring();
    _service.dispose();
    // Only dispose a repository this route created. The provider-scoped repo
    // is a shared ChangeNotifier owned by the app container; disposing it on
    // route pop would break every later '/mission' visit.
    if (_ownsRepo) {
      _repo.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GeofenceRepository>.value(value: _repo),
        ChangeNotifierProvider<GeofenceService>.value(value: _service),
        Provider<MoodTrackerService>.value(value: _moodTracker),
      ],
      child: WellnessMapsPage(
        initialCenter: widget.enableDeviceServices
            ? null
            : const maplat.LatLng(0, 0),
        enableLocationServices: widget.enableDeviceServices,
        renderMapLayers: widget.enableDeviceServices,
      ),
    );
  }
}

// How to use:
// - Add `MapsPageWrapper()` to your application's routing for `wellness` category.
// - This feature uses `flutter_map` plus the shared FlowFit map tile config.
// - Under a Riverpod `ProviderScope` the wrapper reads the app-scoped
//   persistent repository (`geofenceRepositoryProvider`); without one it
//   falls back to a route-local `InMemoryGeofenceRepository`.
