import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:flowfit/core/config/flowfit_runtime_config.dart';

/// Full-screen background map for the active running screen.
///
/// Shows a waiting state until GPS points arrive, then the tile map with the
/// route polyline and current-location marker.
class RunningMapView extends StatelessWidget {
  const RunningMapView({
    super.key,
    required this.routePoints,
    required this.currentLocation,
    required this.resolveMapController,
  });

  final List<LatLng> routePoints;
  final LatLng? currentLocation;

  /// Lazily resolves the shell-owned [MapController], so the controller is
  /// only created once GPS points exist and the shell can dispose it.
  final MapController Function() resolveMapController;

  @override
  Widget build(BuildContext context) {
    final location = currentLocation;

    return routePoints.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  SolarIconsBold.mapPoint,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Waiting for GPS signal...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        : FlutterMap(
            mapController: resolveMapController(),
            options: MapOptions(
              initialCenter: location ?? const LatLng(0, 0),
              initialZoom: 16,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: FlowFitRuntimeConfig.mapTileUrlTemplate,
                subdomains: FlowFitRuntimeConfig.mapTileSubdomains,
                userAgentPackageName: FlowFitRuntimeConfig.authScheme,
              ),
              // Route polyline
              if (routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 5,
                      color: const Color(0xFF3B82F6),
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ],
                ),
              // Current location marker
              if (location != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: location,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          );
  }
}
