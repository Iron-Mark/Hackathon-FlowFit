import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../models/mission.dart';
import '../../../models/mood_rating.dart';
import '../../../models/walking_session.dart';
import '../../../providers/walking_session_provider.dart';
import '../../../providers/running_session_provider.dart'; // For gpsTrackingServiceProvider
import 'active_walking_screen.dart';

/// Mission creation screen with map and mission configuration
/// Requirements: 6.3, 6.5
class MissionCreationScreen extends ConsumerStatefulWidget {
  final MissionType missionType;
  final MoodRating? preMood;

  const MissionCreationScreen({
    super.key,
    required this.missionType,
    this.preMood,
  });

  @override
  ConsumerState<MissionCreationScreen> createState() =>
      _MissionCreationScreenState();
}

class _MissionCreationScreenState extends ConsumerState<MissionCreationScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  double _distance = 500; // Default 500 meters
  double _radius = 100; // Default 100 meters
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    _setDefaultMissionName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final gpsService = ref.read(gpsTrackingServiceProvider);
      final location = await gpsService.getCurrentLocation();

      setState(() {
        _currentLocation = location;
        _selectedLocation = location;
        _isLoadingLocation = false;
      });

      // Center map on current location
      _mapController.move(location, 15.0);
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get current location. Please enable GPS.'),
          ),
        );
      }
    }
  }

  void _setDefaultMissionName() {
    switch (widget.missionType) {
      case MissionType.target:
        _nameController.text = 'Distance Challenge';
        break;
      case MissionType.sanctuary:
        _nameController.text = 'Destination Walk';
        break;
      case MissionType.safetyNet:
        _nameController.text = 'Safe Zone Walk';
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Create Mission'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map Section (50% of screen)
                Expanded(flex: 5, child: _buildMapSection(theme)),

                // Configuration Section (50% of screen)
                Expanded(flex: 5, child: _buildConfigurationSection(theme)),
              ],
            ),
    );
  }

  Widget _buildMapSection(ThemeData theme) {
    if (_currentLocation == null) {
      return Container(
        color: theme.colorScheme.surface,
        child: const Center(child: Text('Location unavailable')),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation!,
            initialZoom: 15.0,
            onTap: (tapPosition, point) {
              setState(() {
                _selectedLocation = point;
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.flowfit.app',
            ),
            MarkerLayer(
              markers: [
                // Current location marker
                Marker(
                  point: _currentLocation!,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                // Selected location marker
                if (_selectedLocation != null &&
                    _selectedLocation != _currentLocation)
                  Marker(
                    point: _selectedLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
              ],
            ),
            // Circle for safety net missions
            if (widget.missionType == MissionType.safetyNet &&
                _selectedLocation != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _selectedLocation!,
                    radius: _radius,
                    useRadiusInMeter: true,
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderColor: theme.colorScheme.primary,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
          ],
        ),
        // Instructions overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Tap on the map to select target location',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationSection(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mission Type Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.missionType.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.missionType.description,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Distance/Radius Input
            if (widget.missionType == MissionType.target) ...[
              Text('Target Distance', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _distance,
                      min: 100,
                      max: 5000,
                      divisions: 49,
                      label: '${_distance.round()}m',
                      onChanged: (value) {
                        setState(() {
                          _distance = value;
                        });
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_distance.round()}m',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            if (widget.missionType == MissionType.safetyNet) ...[
              Text('Safe Zone Radius', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _radius,
                      min: 50,
                      max: 1000,
                      divisions: 19,
                      label: '${_radius.round()}m',
                      onChanged: (value) {
                        setState(() {
                          _radius = value;
                        });
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_radius.round()}m',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Mission Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Mission Name',
                hintText: 'Enter mission name',
              ),
            ),
            const SizedBox(height: 16),

            // Mission Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add mission details',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Start Mission Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedLocation != null
                    ? () => _startMission(context)
                    : null,
                child: const Text('Start Mission'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startMission(BuildContext context) async {
    if (_selectedLocation == null) return;

    // Create mission
    final mission = Mission(
      id: const Uuid().v4(),
      type: widget.missionType,
      targetLocation: _selectedLocation!,
      targetDistance: widget.missionType == MissionType.target
          ? _distance
          : null,
      radius: widget.missionType == MissionType.safetyNet ? _radius : null,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    try {
      // Start walking session with mission
      await ref
          .read(walkingSessionProvider.notifier)
          .startSession(
            mode: WalkingMode.mission,
            mission: mission,
            preMood: widget.preMood,
          );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not start the mission. Sign in and check your connection, then try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      // Navigate to active walking screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ActiveWalkingScreen()),
      );
    }
  }
}
