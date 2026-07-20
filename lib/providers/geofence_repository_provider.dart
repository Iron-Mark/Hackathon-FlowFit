import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/features/wellness/data/geofence_repository.dart';
import 'package:flowfit/features/wellness/data/persistent_geofence_repository.dart';
import 'package:flowfit/providers/shared_preferences_provider.dart';
import 'package:flowfit/services/storage/geofence_mission_storage.dart';

/// App-scoped geofence mission repository, backed by the canonical
/// SharedPreferences provider so a kid's saved zones survive both route pops
/// and app restarts.
///
/// Hydration is kicked off eagerly and unawaited: [PersistentGeofenceRepository]
/// swallows storage failures internally and notifies listeners once persisted
/// missions land, so the '/mission' route can render immediately. The
/// repository is disposed with the owning container — never by an individual
/// route — because it is a shared ChangeNotifier.
final geofenceRepositoryProvider = Provider<GeofenceRepository>((ref) {
  final repository = PersistentGeofenceRepository(
    GeofenceMissionStorage(ref.watch(sharedPreferencesProvider)),
  );
  unawaited(repository.hydrate());
  ref.onDispose(repository.dispose);
  return repository;
});
