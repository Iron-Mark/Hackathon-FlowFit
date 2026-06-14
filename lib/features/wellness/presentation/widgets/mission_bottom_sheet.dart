import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as maplat;
import '../../domain/geofence_mission.dart';
import '../../data/geofence_repository.dart';
import '../../services/geofence_service.dart';
// map_components not required here; map markers created at map level

class MissionBottomSheet extends StatelessWidget {
  final GeofenceRepository repo;
  final GeofenceService service;
  final fm.MapController? mapController;
  final maplat.LatLng? lastCenter;
  final void Function(maplat.LatLng) onAddAtLatLng;
  final void Function(GeofenceMission) onOpenMission;
  final void Function(GeofenceMission) onFocusMission;

  const MissionBottomSheet({
    required this.repo,
    required this.service,
    required this.mapController,
    required this.lastCenter,
    required this.onAddAtLatLng,
    required this.onOpenMission,
    required this.onFocusMission,
    super.key,
  });

  Widget _buildMissionList(BuildContext context, ScrollController controller) {
    if (repo.current.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Text(
            'No missions yet. Long-press on the map or tap Add to create a mission.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      itemCount: repo.current.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8.0),
      itemBuilder: (context, index) {
        final m = repo.current[index];
        return Card(
          elevation: 2.2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            title: Text(
              m.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4.0),
                Text('${m.type.name} • ${m.radiusMeters.toStringAsFixed(0)} m'),
                if (m.type == MissionType.target)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: LinearProgressIndicator(
                      value:
                          (m.targetDistanceMeters == null ||
                              m.targetDistanceMeters == 0)
                          ? 0.0
                          : (service.getProgress(m.id) /
                                    (m.targetDistanceMeters ?? 1.0))
                                .clamp(0.0, 1.0),
                    ),
                  ),
              ],
            ),
            trailing: SizedBox(
              width: 180,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Make focus a primary action with a big, clear affordance
                    ElevatedButton.icon(
                      onPressed: () {
                        onFocusMission(m);
                      },
                      icon: const Icon(Icons.flag),
                      label: const Text('Focus'),
                    ),
                    const SizedBox(width: 8.0),
                    Transform.scale(
                      scale: 0.72,
                      child: Switch(
                        value: m.isActive,
                        onChanged: (v) => v
                            ? service.activateMission(m.id)
                            : service.deactivateMission(m.id),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      iconSize: 20,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async => await repo.delete(m.id),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () => onFocusMission(m),
            onLongPress: () => onOpenMission(m),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.28,
      minChildSize: 0.12,
      maxChildSize: 0.85,
      builder: (BuildContext context, ScrollController controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18.0),
              topRight: Radius.circular(18.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.12 * 255).toInt()),
                blurRadius: 8.0,
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12.0),
              Container(
                width: 48.0,
                height: 6.0,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              const SizedBox(height: 8.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Missions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${repo.current.length} missions',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            // TODO: Implement filters in future iterations
                          },
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Filter'),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final center = lastCenter;
                            if (center != null) onAddAtLatLng(center);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildMissionList(context, controller)),
            ],
          ),
        );
      },
    );
  }
}
