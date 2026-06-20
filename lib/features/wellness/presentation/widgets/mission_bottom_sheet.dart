import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as maplat;
import '../../domain/geofence_mission.dart';
import '../../data/geofence_repository.dart';
import '../../services/geofence_service.dart';
// map_components not required here; map markers created at map level

enum _MissionFilter { all, active, target, sanctuary, safetyNet }

class MissionBottomSheet extends StatefulWidget {
  final GeofenceRepository repo;
  final GeofenceService service;
  final fm.MapController? mapController;
  final maplat.LatLng? lastCenter;
  final FutureOr<void> Function(maplat.LatLng) onAddAtLatLng;
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

  @override
  State<MissionBottomSheet> createState() => _MissionBottomSheetState();
}

class _MissionBottomSheetState extends State<MissionBottomSheet> {
  _MissionFilter _filter = _MissionFilter.all;

  List<GeofenceMission> get _filteredMissions {
    return widget.repo.current
        .where((mission) {
          return switch (_filter) {
            _MissionFilter.all => true,
            _MissionFilter.active => mission.isActive,
            _MissionFilter.target => mission.type == MissionType.target,
            _MissionFilter.sanctuary => mission.type == MissionType.sanctuary,
            _MissionFilter.safetyNet => mission.type == MissionType.safetyNet,
          };
        })
        .toList(growable: false);
  }

  String get _filterLabel {
    return switch (_filter) {
      _MissionFilter.all => 'All',
      _MissionFilter.active => 'Active',
      _MissionFilter.target => 'Target',
      _MissionFilter.sanctuary => 'Sanctuary',
      _MissionFilter.safetyNet => 'Safety Net',
    };
  }

  Widget _buildMissionList(BuildContext context, ScrollController controller) {
    final missions = _filteredMissions;

    if (widget.repo.current.isEmpty) {
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

    if (missions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Text(
            'No $_filterLabel missions match this filter.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      itemCount: missions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8.0),
      itemBuilder: (context, index) {
        final m = missions[index];
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
                          : (widget.service.getProgress(m.id) /
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
                        widget.onFocusMission(m);
                      },
                      icon: const Icon(Icons.flag),
                      label: const Text('Focus'),
                    ),
                    const SizedBox(width: 8.0),
                    Transform.scale(
                      scale: 0.72,
                      child: Switch(
                        value: m.isActive,
                        onChanged: (v) async {
                          if (v) {
                            await widget.service.activateMission(m.id);
                          } else {
                            await widget.service.deactivateMission(m.id);
                          }
                          if (mounted) setState(() {});
                        },
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
                      onPressed: () => _confirmDeleteMission(m),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () => widget.onFocusMission(m),
            onLongPress: () => widget.onOpenMission(m),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteMission(GeofenceMission mission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Mission?'),
        content: Text(
          'Delete "${mission.title}" from your local wellness missions?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.repo.delete(mission.id);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${mission.title}" deleted'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete mission. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<_MissionFilter>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption(context, _MissionFilter.all, 'All missions'),
              _buildFilterOption(context, _MissionFilter.active, 'Active only'),
              _buildFilterOption(context, _MissionFilter.target, 'Target'),
              _buildFilterOption(
                context,
                _MissionFilter.sanctuary,
                'Sanctuary',
              ),
              _buildFilterOption(
                context,
                _MissionFilter.safetyNet,
                'Safety Net',
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _filter = selected);
    }
  }

  Widget _buildFilterOption(
    BuildContext context,
    _MissionFilter value,
    String label,
  ) {
    final selected = value == _filter;

    return ListTile(
      title: Text(label),
      trailing: selected ? const Icon(Icons.check) : null,
      selected: selected,
      onTap: () => Navigator.of(context).pop(value),
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
                          _filter == _MissionFilter.all
                              ? '${widget.repo.current.length} missions'
                              : '${_filteredMissions.length} of ${widget.repo.current.length} missions',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _showFilterSheet(context),
                          icon: const Icon(Icons.filter_list),
                          label: Text(_filterLabel),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final center = widget.lastCenter;
                            if (center == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Map center is not ready yet.'),
                                ),
                              );
                              return;
                            }
                            await widget.onAddAtLatLng(center);
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
