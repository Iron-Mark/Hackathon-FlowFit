import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../domain/geofence_mission.dart';
import '../data/geofence_repository.dart';
import 'geofence_service.dart';
import 'notification_service.dart';

enum MoodState { calm, neutral, stressed }

/// A background-capable mood tracker service that listens to a mood stream
/// and triggers auto-focus on the nearest mission if the user appears stressed.
/// NOTE: This service expects a supplied [moodStream] or test override. In
/// production, hook this up to a real AI model / classifier.
class MoodTrackerService {
  final GeofenceRepository repository;
  final GeofenceService service;
  final Stream<MoodState>? moodStreamOverride;
  final Future<Position> Function()? currentPositionGetter;
  StreamSubscription<MoodState>? _moodSub;

  MoodTrackerService({
    required this.repository,
    required this.service,
    this.moodStreamOverride,
    this.currentPositionGetter,
  });

  Stream<MoodState> _getMoodStream() {
    if (moodStreamOverride != null) return moodStreamOverride!;
    // Fallback: no stream available. We return a stream that never emits.
    return const Stream<MoodState>.empty();
  }

  Future<void> startMonitoring() async {
    await NotificationService.init();
    _moodSub ??= _getMoodStream().listen((mood) async {
      if (mood == MoodState.stressed) {
        await _onStressed();
      }
    });
  }

  Future<void> stopMonitoring() async {
    await _moodSub?.cancel();
    _moodSub = null;
  }

  Future<void> _onStressed() async {
    try {
      final pos = await (currentPositionGetter != null
          ? currentPositionGetter!()
          : Geolocator.getCurrentPosition());
      final current = await repository.getAll();
      if (current.isEmpty) {
        // Prompt to add sanctuary
        await NotificationService.showNotification(
          title: 'Feeling stressed?',
          body: 'Add a Sanctuary nearby to relax',
          id: 999,
          payload: 'add_sanctuary',
        );
        return;
      }

      // find nearest
      double bestDist = double.infinity;
      GeofenceMission? best;
      for (final m in current) {
        final dist = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          m.center.latitude,
          m.center.longitude,
        );
        if (dist < bestDist) {
          bestDist = dist;
          best = m;
        }
      }
      if (best != null) {
        // Activate and request UI focus
        await service.activateMission(best.id);
        // Show a notification allowing user to open the app and focus
        await NotificationService.showNotification(
          title: 'Stress detected',
          body: 'Start focus at ${best.title}?',
          id: 998,
          payload: 'focus:${best.id}',
        );
        // Request focus via GeofenceService stream so UI can respond if active
        service.requestFocus(best.id);
      }
    } catch (e) {
      // ignore errors — mood tracker is best-effort
    }
  }
}
