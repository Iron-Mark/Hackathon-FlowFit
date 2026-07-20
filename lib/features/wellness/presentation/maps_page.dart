import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as maplat;
// import 'dart:io'; // import/export removed
// import 'dart:convert'; // import/export removed
// import 'package:path_provider/path_provider.dart'; // import/export removed
import 'package:geolocator/geolocator.dart';
import 'package:flowfit/core/config/flowfit_runtime_config.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';
import 'package:flowfit/features/wellness/data/geofence_repository.dart';
import 'package:flowfit/features/wellness/services/geofence_service.dart';
import 'package:flowfit/features/wellness/presentation/widgets/place_mode_overlay.dart';
import 'package:flowfit/features/wellness/presentation/widgets/map_components.dart';
import 'package:flowfit/features/wellness/presentation/widgets/focus_mission_overlay.dart';
import 'package:flowfit/features/wellness/presentation/widgets/top_action_button.dart';
import 'package:flowfit/features/wellness/presentation/widgets/floating_actions.dart';
import 'package:flowfit/features/wellness/presentation/widgets/mission_bottom_sheet.dart';
import 'package:flowfit/features/wellness/presentation/widgets/edit_mission_dialog.dart';
import 'package:flowfit/features/wellness/presentation/widgets/map_tutorial_overlay.dart';

class WellnessMapsPage extends StatefulWidget {
  final maplat.LatLng? initialCenter;
  final bool enableLocationServices;
  final bool renderMapLayers;

  /// Injected mission repository. When null the page owns a private
  /// [InMemoryGeofenceRepository] for its lifetime.
  final GeofenceRepository? repository;

  /// Injected geofence service. When null the page owns a private
  /// [GeofenceService] bound to its repository.
  final GeofenceService? service;

  const WellnessMapsPage({
    super.key,
    this.initialCenter,
    this.enableLocationServices = true,
    this.renderMapLayers = true,
    this.repository,
    this.service,
  });

  @override
  State<WellnessMapsPage> createState() => _WellnessMapsPageState();
}

class _WellnessMapsPageState extends State<WellnessMapsPage> {
  static const maplat.LatLng _fallbackInitialCenter = maplat.LatLng(0, 0);

  fm.MapController? _mapController;
  maplat.LatLng? _initialCenter;
  maplat.LatLng? _lastCenter;
  StreamSubscription<GeofenceEvent>? _eventsSub;
  StreamSubscription<String>? _focusRequestsSub;
  bool _missionsVisible = true;
  bool _showTutorial = true; // Show tutorial on first visit
  // Place mode state
  bool _isPlacingMission = false;
  maplat.LatLng? _placingLatLng;
  double _placingRadius = 50.0;
  GeofenceMissionType _placingType = GeofenceMissionType.sanctuary;
  double? _placingTargetDistance;
  // Title for place-mode is stored in `_placingTitleController.text`
  final TextEditingController _placingTitleController = TextEditingController();
  // Focused mission state for 'start activity' mode
  GeofenceMission? _focusedMission;
  Timer? _focusTimer;
  double _focusedDistanceMeters = 0.0;
  Duration _focusedEta = Duration.zero;
  double _focusSpeedMps = 1.4; // default walking speed
  bool _locationStartupFailed = false;

  // Resolved once per State: injected via the widget, or a page-owned
  // fallback so the page still works when constructed bare.
  late final GeofenceRepository _repo;
  late final GeofenceService _service;
  bool _ownsRepo = false;
  bool _ownsService = false;

  @override
  void initState() {
    super.initState();
    final injectedRepo = widget.repository;
    if (injectedRepo != null) {
      _repo = injectedRepo;
    } else {
      _repo = InMemoryGeofenceRepository();
      _ownsRepo = true;
    }
    final injectedService = widget.service;
    if (injectedService != null) {
      _service = injectedService;
    } else {
      _service = GeofenceService(repository: _repo);
      _ownsService = true;
    }
    final initialCenter = widget.initialCenter;
    if (initialCenter != null) {
      _initialCenter = initialCenter;
      _lastCenter = initialCenter;
    }
    if (widget.enableLocationServices) {
      _initLocation();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _subscribeToService(startMonitoring: false);
      });
    }
  }

  Future<void> _initLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final center = maplat.LatLng(pos.latitude, pos.longitude);
      setState(() {
        _initialCenter = center;
        _lastCenter = center;
      });
      // Move map if controller already exists (no-op if controller == null)
      _mapController?.move(center, 16.0);

      await _subscribeToService(startMonitoring: true);
    } catch (e) {
      if (!mounted) return;
      final fallbackCenter = _initialCenter ?? _fallbackInitialCenter;
      setState(() {
        _initialCenter = fallbackCenter;
        _lastCenter = fallbackCenter;
        _locationStartupFailed = true;
      });
      _mapController?.move(fallbackCenter, 16.0);
      await _subscribeToService(startMonitoring: false);
    }
  }

  Future<void> _subscribeToService({required bool startMonitoring}) async {
    if (_eventsSub != null || _focusRequestsSub != null) return;

    final service = _service;
    if (startMonitoring) {
      await service.startMonitoring();
    }
    _eventsSub = service.events.listen((event) {
      final m = _repo.getById(event.missionId);
      if (m == null) return;
      final message = _buildEventMessage(m, event);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });
    // Listen for focus requests (e.g., pushed by MoodTrackerService or notifications)
    _focusRequestsSub = service.focusRequests.listen((id) async {
      if (id == 'add_sanctuary') {
        // Prompt user to start place mode at current location
        if (!widget.enableLocationServices && _initialCenter != null) {
          _startPlacingAtLatLng(_initialCenter!);
          return;
        }
        try {
          final pos = await Geolocator.getCurrentPosition();
          if (!mounted) return;
          _startPlacingAtLatLng(maplat.LatLng(pos.latitude, pos.longitude));
          return;
        } catch (_) {
          return;
        }
      }
      final mission = _repo.getById(id);
      if (mission != null) {
        // Start focus mode for this mission
        _startFocusMission(mission);
      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _eventsSub?.cancel();
    _focusRequestsSub?.cancel();
    _placingTitleController.dispose();
    _focusTimer?.cancel();
    // Only dispose the fallback instances this State created; injected
    // repo/service are owned by whoever constructed the page.
    if (_ownsService) {
      _service.dispose();
    }
    if (_ownsRepo) {
      _repo.dispose();
    }
    super.dispose();
  }

  String _buildEventMessage(GeofenceMission m, GeofenceEvent event) {
    switch (event.type) {
      case GeofenceEventType.entered:
        return '${m.title} - entered';
      case GeofenceEventType.exited:
        return '${m.title} - exited';
      case GeofenceEventType.targetReached:
        return '${m.title} - progress ${(event.value ?? 0).toStringAsFixed(1)} m';
      case GeofenceEventType.outsideAlert:
        return '${m.title} - outside ${(event.value ?? 0).toStringAsFixed(1)} m';
    }
  }

  Future<void> _addGeofenceAtLatLng(maplat.LatLng latLng) async {
    // Begin 'place mode' so user can pick exact location/radius on the map
    _startPlacingAtLatLng(latLng);
  }

  void _handleMissionTap(GeofenceMission m) {
    _mapController?.move(
      maplat.LatLng(m.center.latitude, m.center.longitude),
      16.0,
    );
    _showMissionActions(m);
  }

  void _startPlacingAtLatLng(maplat.LatLng latLng) {
    setState(() {
      _isPlacingMission = true;
      _placingLatLng = latLng;
      _placingRadius = 50.0;
      _placingType = GeofenceMissionType.sanctuary;
      _placingTargetDistance = null;
      _placingTitleController.text = '';
    });
    // Keep map centered on chosen point
    _mapController?.move(latLng, 16.0);
  }

  void _cancelPlaceMode() {
    setState(() {
      _isPlacingMission = false;
      _placingLatLng = null;
    });
  }

  Future<void> _confirmPlaceMode() async {
    if (_placingLatLng == null) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final title = _placingTitleController.text.trim();
    final mission = GeofenceMission(
      id: id,
      title: title.isEmpty ? 'Mission $id' : title,
      description: null,
      center: _placingLatLng!,
      radiusMeters: _placingRadius,
      type: _placingType,
      isActive: false,
      targetDistanceMeters: _placingType == GeofenceMissionType.target
          ? _placingTargetDistance
          : null,
    );
    await _repo.add(mission);
    if (!mounted) return;
    setState(() {
      _isPlacingMission = false;
      _placingLatLng = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Mission added')));
  }

  // Focus a mission in the UI and start periodic updates for ETA/distance
  Future<void> _startFocusMission(GeofenceMission mission) async {
    _focusTimer?.cancel();
    // ensure mission is active
    try {
      await _service.activateMission(mission.id);
    } catch (_) {}
    if (!mounted) return;
    final focusedMission = _repo.getById(mission.id) ?? mission;
    setState(() {
      _focusedMission = focusedMission;
      // hide missions to focus map UI
      _missionsVisible = false;
    });
    // center on mission
    _mapController?.move(
      maplat.LatLng(
        focusedMission.center.latitude,
        focusedMission.center.longitude,
      ),
      16.0,
    );
    _updateFocusMetrics();
    _focusTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _updateFocusMetrics(),
    );
  }

  void _stopFocusMission() {
    _focusTimer?.cancel();
    setState(() {
      _focusedMission = null;
      _focusedDistanceMeters = 0.0;
      _focusedEta = Duration.zero;
    });
  }

  Future<void> _updateFocusMetrics() async {
    final m = _focusedMission;
    if (m == null) return;
    if (!widget.enableLocationServices) {
      final center = _initialCenter;
      final dist = center == null
          ? 0.0
          : const maplat.Distance().as(
              maplat.LengthUnit.Meter,
              center,
              maplat.LatLng(m.center.latitude, m.center.longitude),
            );
      final etaSec = (dist / _focusSpeedMps).round();
      if (!mounted) return;
      setState(() {
        _focusedDistanceMeters = dist;
        _focusedEta = Duration(seconds: etaSec);
      });
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final dist = const maplat.Distance().as(
        maplat.LengthUnit.Meter,
        maplat.LatLng(pos.latitude, pos.longitude),
        maplat.LatLng(m.center.latitude, m.center.longitude),
      );
      final etaSec = (dist / _focusSpeedMps).round();
      setState(() {
        _focusedDistanceMeters = dist;
        _focusedEta = Duration(seconds: etaSec);
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild everything that reads repo/service state (markers, circles,
    // mission sheet, focus overlay) whenever either notifies listeners.
    return ListenableBuilder(
      listenable: Listenable.merge([_repo, _service]),
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final repo = _repo;
    final service = _service;

    final markers = <fm.Marker>[];
    final circles = <fm.CircleMarker>[];
    final focusedMission = _focusedMission == null
        ? null
        : repo.getById(_focusedMission!.id) ?? _focusedMission;

    if (widget.renderMapLayers) {
      for (final m in repo.current) {
        markers.add(buildMissionMarker(m, () => _handleMissionTap(m)));
        circles.add(buildMissionCircle(m));
      }

      // preview candidate marker + circle if placing a mission
      if (_isPlacingMission && _placingLatLng != null) {
        markers.add(buildPreviewMarker(_placingLatLng!));
        circles.add(buildPreviewCircle(_placingLatLng!, _placingRadius));
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Full-screen map
          Positioned.fill(
            child: _initialCenter == null
                ? const Center(child: CircularProgressIndicator())
                : !widget.renderMapLayers
                ? ColoredBox(color: Theme.of(context).colorScheme.surface)
                : fm.FlutterMap(
                    mapController: _mapController ??= fm.MapController(),
                    options: fm.MapOptions(
                      initialCenter: _initialCenter!,
                      initialZoom: 16.0,
                      onLongPress: (tapPosition, latlng) =>
                          _addGeofenceAtLatLng(
                            maplat.LatLng(latlng.latitude, latlng.longitude),
                          ),
                      onTap: (tapPosition, latlng) {
                        if (_isPlacingMission) {
                          setState(
                            () => _placingLatLng = maplat.LatLng(
                              latlng.latitude,
                              latlng.longitude,
                            ),
                          );
                        }
                      },
                      onPositionChanged: (pos, _) {
                        setState(() => _lastCenter = pos.center);
                      },
                    ),
                    children: [
                      fm.TileLayer(
                        urlTemplate: FlowFitRuntimeConfig.mapTileUrlTemplate,
                        subdomains: FlowFitRuntimeConfig.mapTileSubdomains,
                        userAgentPackageName: FlowFitRuntimeConfig.authScheme,
                      ),
                      const CurrentLocationLayer(
                        alignPositionOnUpdate: AlignOnUpdate.always,
                        alignDirectionOnUpdate: AlignOnUpdate.never,
                      ),
                      fm.CircleLayer(circles: circles),
                      fm.MarkerLayer(markers: markers),
                    ],
                  ),
          ),
          // (Focus overlay moved below so it can be placed above the bottom sheet)

          // top overlay controls (back, import/export)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withAlpha((0.8 * 255).toInt()),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Row(
                    children: [
                      TopActionButton(
                        icon: _missionsVisible ? Icons.close : Icons.list,
                        onTap: () async => setState(
                          () => _missionsVisible = !_missionsVisible,
                        ),
                        label: _missionsVisible ? 'Hide' : 'Show',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          FloatingMapActions(
            mapController: _mapController,
            lastCenter: _lastCenter,
            onAddAtLatLng: (lat) async => await _addGeofenceAtLatLng(lat),
          ),

          PlaceModeOverlay(
            visible: _isPlacingMission,
            latLng: _placingLatLng,
            radius: _placingRadius,
            titleController: _placingTitleController,
            type: _placingType,
            onRadiusChanged: (v) => setState(() => _placingRadius = v),
            onTypeChanged: (t) => setState(
              () => _placingType = t ?? GeofenceMissionType.sanctuary,
            ),
            onCancel: _cancelPlaceMode,
            onConfirm: () async => await _confirmPlaceMode(),
          ),

          // Bottom sheet with missions (draggable)
          if (_missionsVisible)
            MissionBottomSheet(
              repo: repo,
              service: service,
              mapController: _mapController,
              lastCenter: _lastCenter,
              onAddAtLatLng: (lat) async => await _addGeofenceAtLatLng(lat),
              onOpenMission: (m) => _showMissionActions(m),
              // Make Focus & Navigate the primary action: request a UI focus via the
              // GeofenceService stream so it behaves the same as MoodTrackerService
              // invoked focus requests (and works even when triggered from notifications).
              onFocusMission: (m) => service.requestFocus(m.id),
            ),

          // Focus overlay when a mission is selected for navigation (positioned above bottom sheet)
          if (focusedMission != null)
            FocusMissionOverlay(
              mission: focusedMission,
              distanceMeters: _focusedDistanceMeters,
              eta: _focusedEta,
              isActive: focusedMission.isActive,
              speedMetersPerSecond: _focusSpeedMps,
              onUnfocus: _stopFocusMission,
              onCenter: () => _mapController?.move(
                maplat.LatLng(
                  focusedMission.center.latitude,
                  focusedMission.center.longitude,
                ),
                16.0,
              ),
              onActivate: () async {
                await _service.activateMission(focusedMission.id);
                if (mounted) {
                  setState(() {
                    _focusedMission =
                        _repo.getById(focusedMission.id) ?? focusedMission;
                  });
                }
              },
              onDeactivate: () async {
                await _service.deactivateMission(focusedMission.id);
                if (mounted) {
                  setState(() {
                    _focusedMission =
                        _repo.getById(focusedMission.id) ?? focusedMission;
                  });
                }
              },
              onSpeedChanged: (v) => setState(() {
                _focusSpeedMps = v;
                _updateFocusMetrics();
              }),
            ),

          // Tutorial overlay (shows on first visit)
          if (_showTutorial)
            MapTutorialOverlay(
              onDismiss: () => setState(() => _showTutorial = false),
            ),

          if (_locationStartupFailed)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 72, left: 16, right: 72),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: const Text(
                    'Location unavailable. Map opened at the fallback center.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Import and export functionality removed — no longer exposed in the UI.

  // Mission list logic moved to MissionBottomSheet widget

  void _showMissionActions(GeofenceMission mission) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(mission.title),
                  subtitle: Text(mission.description ?? ''),
                ),
                ListTile(
                  leading: const Icon(Icons.play_arrow),
                  title: const Text('Activate'),
                  onTap: () async {
                    final sheetNavigator = Navigator.of(ctx);
                    await _service.activateMission(mission.id);
                    if (!mounted) return;
                    setState(() {});
                    sheetNavigator.pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.stop),
                  title: const Text('Deactivate'),
                  onTap: () async {
                    final sheetNavigator = Navigator.of(ctx);
                    await _service.deactivateMission(mission.id);
                    if (!mounted) return;
                    setState(() {});
                    sheetNavigator.pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () async {
                    final sheetNavigator = Navigator.of(ctx);
                    final edited = await showDialog<GeofenceMission>(
                      context: ctx,
                      builder: (_) => EditMissionDialog(mission: mission),
                    );
                    if (edited != null) {
                      await _repo.update(edited);
                    }
                    if (!mounted) return;
                    setState(() {});
                    sheetNavigator.pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text('Focus & Navigate'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    _startFocusMission(mission);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Add and Edit dialog classes were refactored into separate widgets under
// lib/features/wellness/presentation/widgets/*. Please use those widgets in
// the UI and avoid duplicating dialog classes here.

// TopActionButton moved to widgets/top_action_button.dart
