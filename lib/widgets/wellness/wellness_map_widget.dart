import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/wellness_state.dart';
import '../../models/walking_route.dart';
import '../../services/calming_route_service.dart';
import '../../services/openroute_service.dart';
import '../../services/gps_tracking_service.dart';

/// Map widget that responds to wellness state
class WellnessMapWidget extends StatefulWidget {
  final WellnessState state;

  const WellnessMapWidget({super.key, required this.state});

  @override
  State<WellnessMapWidget> createState() => _WellnessMapWidgetState();
}

class _WellnessMapWidgetState extends State<WellnessMapWidget> {
  final MapController _mapController = MapController();
  final GPSTrackingService _gpsService = GPSTrackingService();
  LatLng? _userLocation;
  final List<LatLng> _userPath = []; // Track user's walking path
  List<WalkingRoute> _calmingRoutes = [];
  WalkingRoute? _selectedRoute;
  bool _isLoadingRoutes = false;
  bool _isLoadingLocation = true;
  bool _isTrackingPath = false;
  String? _locationError;
  StreamSubscription<LatLng>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeLocationAccess();
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _gpsService.stopTracking();
    _gpsService.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WellnessMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Load calming routes when entering stress state
    if (widget.state == WellnessState.stress &&
        oldWidget.state != WellnessState.stress) {
      _loadCalmingRoutes();
    }
  }

  Future<void> _initializeLocationAccess() async {
    final prepared = await _prepareLocationAccess();
    if (!prepared || !mounted) return;

    final locationLoaded = await _getUserLocation();
    if (!locationLoaded || !mounted) return;

    await _startGPSTracking();
  }

  Future<bool> _prepareLocationAccess() async {
    final hasPermission = await _gpsService.hasLocationPermission();
    if (hasPermission) {
      return true;
    }

    final shouldRequest = await _showLocationPermissionDisclosure();
    if (!shouldRequest || !mounted) {
      _showLocationAccessError();
      return false;
    }

    final granted = await _gpsService.requestLocationPermission();
    if (!granted) {
      _showLocationAccessError();
    }
    return granted;
  }

  Future<bool> _showLocationPermissionDisclosure() async {
    if (!mounted) return false;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Use Location for Wellness Missions?'),
            content: const Text(
              'FlowFit uses your location to show nearby calming routes, record '
              'walking paths, and update geofence mission progress while the '
              'app is open. You can change this in device settings anytime.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Not Now'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showLocationAccessError() {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = false;
      _locationError =
          'Location access is needed for wellness routes, walking paths, and geofence missions.';
    });
  }

  Future<bool> _getUserLocation() async {
    try {
      debugPrint('📍 WellnessMap: Requesting location...');

      // Get current location (this will wait for actual GPS fix)
      final location = await _gpsService.getCurrentLocation();
      debugPrint(
        '✅ WellnessMap: Got location: ${location.latitude}, ${location.longitude}',
      );

      if (mounted) {
        setState(() {
          _userLocation = location;
          _userPath.add(location); // Add initial position to path
          _isLoadingLocation = false;
          _locationError = null; // Clear any previous errors
        });

        // Center map on user location
        _mapController.move(_userLocation!, 15.0);
      }
      return true;
    } catch (e) {
      debugPrint('❌ WellnessMap: Location error: $e');
      // Keep loading state and show error - don't use fake location
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationError =
              'Unable to get your location. Please enable GPS and try again.';
        });
      }
      return false;
    }
  }

  /// Starts continuous GPS tracking to update user location and path
  Future<void> _startGPSTracking() async {
    try {
      debugPrint('🛰️ WellnessMap: Starting GPS tracking...');
      await _gpsService.startTracking();

      // Listen to location updates
      _locationSubscription = _gpsService.locationStream.listen((location) {
        if (mounted) {
          setState(() {
            _userLocation = location;

            // Add to path if tracking is enabled
            if (_isTrackingPath) {
              _userPath.add(location);
              debugPrint(
                '📍 WellnessMap: Path updated - ${_userPath.length} points',
              );
            }
          });

          // Auto-center map on user location (smooth follow)
          _mapController.move(location, _mapController.camera.zoom);
        }
      });

      // Enable path tracking by default
      setState(() {
        _isTrackingPath = true;
      });

      debugPrint('✅ WellnessMap: GPS tracking started');
    } catch (e) {
      debugPrint('❌ WellnessMap: Failed to start GPS tracking: $e');
    }
  }

  /// Clears the tracked path
  void _clearPath() {
    setState(() {
      _userPath.clear();
      if (_userLocation != null) {
        _userPath.add(_userLocation!);
      }
    });
  }

  Future<void> _loadCalmingRoutes() async {
    if (_userLocation == null || _isLoadingRoutes) return;

    setState(() => _isLoadingRoutes = true);

    try {
      debugPrint(
        '🗺️ WellnessMap: Loading calming routes for location: $_userLocation',
      );
      final service = CalmingRouteService(OpenRouteService());
      final routes = await service.generateCalmingRoutes(_userLocation!);
      debugPrint('✅ WellnessMap: Loaded ${routes.length} routes');

      if (mounted) {
        setState(() {
          _calmingRoutes = routes;
          _isLoadingRoutes = false;
        });

        // Auto-pan to show routes
        if (routes.isNotEmpty) {
          _mapController.move(_userLocation!, 14.0);
        }
      }
    } catch (e) {
      debugPrint('❌ WellnessMap: Failed to load routes: $e');
      if (mounted) {
        setState(() => _isLoadingRoutes = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLocation) {
      return Container(
        color: const Color(0xFFF1F6FD),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Getting your location...',
                style: TextStyle(fontFamily: 'GeneralSans', fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_userLocation == null) {
      return Container(
        color: const Color(0xFFF1F6FD),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _locationError ?? 'Unable to get location',
                style: const TextStyle(fontFamily: 'GeneralSans', fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoadingLocation = true;
                    _locationError = null;
                  });
                  _initializeLocationAccess();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation!,
              initialZoom: 15.0,
              minZoom: 10.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.flowfit.app',
                tileProvider: NetworkTileProvider(),
              ),

              // User's walking path (drawn first, underneath everything)
              if (_userPath.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _userPath,
                      strokeWidth: 4,
                      color: const Color(0xFF10B981), // Green for wellness path
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ],
                ),

              // Calming route polylines (drawn before markers)
              if (widget.state == WellnessState.stress &&
                  _calmingRoutes.isNotEmpty)
                ..._buildRoutePolylines(),

              // User location marker (on top)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userLocation!,
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: _buildUserMarker(),
                  ),
                ],
              ),
            ],
          ),

          // Top controls
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Loading indicator
                if (_isLoadingRoutes)
                  const Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Finding calming routes...',
                            style: TextStyle(
                              fontFamily: 'GeneralSans',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Path tracking controls
                if (_userPath.length > 1) ...[
                  const SizedBox(height: 8),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.route,
                                size: 16,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_userPath.length} points',
                                style: const TextStyle(
                                  fontFamily: 'GeneralSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_gpsService.calculateRouteDistance(_userPath).toStringAsFixed(2)} km',
                            style: TextStyle(
                              fontFamily: 'GeneralSans',
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Clear path button
          if (_userPath.length > 1)
            Positioned(
              top: 16,
              left: 16,
              child: FloatingActionButton.small(
                heroTag: 'clear_path',
                onPressed: _clearPath,
                backgroundColor: Colors.white,
                child: const Icon(Icons.clear, color: Colors.red),
              ),
            ),

          // Route selection panel
          if (_calmingRoutes.isNotEmpty && widget.state == WellnessState.stress)
            _buildRouteSelectionPanel(),
        ],
      ),
    );
  }

  List<Widget> _buildRoutePolylines() {
    return _calmingRoutes.map((route) {
      final isSelected = route == _selectedRoute;
      return PolylineLayer(
        polylines: [
          Polyline(
            points: route.routePoints,
            strokeWidth: isSelected ? 6.0 : 4.0,
            color: isSelected
                ? const Color(0xFF4A90E2)
                : const Color(0xFF5DADE2).withValues(alpha: 0.7),
            borderStrokeWidth: isSelected ? 2.0 : 0,
            borderColor: Colors.white,
          ),
        ],
      );
    }).toList();
  }

  Widget _buildUserMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 20),
    );
  }

  Widget _buildRouteSelectionPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Calming Routes',
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _calmingRoutes.length,
                itemBuilder: (context, index) {
                  final route = _calmingRoutes[index];
                  return _buildRouteCard(route);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(WalkingRoute route) {
    final isSelected = route == _selectedRoute;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRoute = isSelected ? null : route;
        });
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A90E2) : const Color(0xFFF1F6FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A90E2) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  route.name,
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(route.greenSpacePercentage * 100).toInt()}% 🌳',
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 10,
                      color: isSelected ? Colors.white : Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.straighten,
                  size: 14,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${route.distance.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${route.duration} min',
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
