import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as maplat;

class FloatingMapActions extends StatelessWidget {
  final fm.MapController? mapController;
  final maplat.LatLng? lastCenter;
  final Future<void> Function(maplat.LatLng) onAddAtLatLng;
  final Future<maplat.LatLng> Function()? currentLocationGetter;

  const FloatingMapActions({
    required this.mapController,
    required this.lastCenter,
    required this.onAddAtLatLng,
    this.currentLocationGetter,
    super.key,
  });

  Future<void> _centerOnCurrentLocation(BuildContext context) async {
    final controller = mapController;
    if (controller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Map is still loading. Try again soon.')),
      );
      return;
    }

    try {
      final currentLocation =
          await (currentLocationGetter?.call() ??
              Geolocator.getCurrentPosition().then(
                (pos) => maplat.LatLng(pos.latitude, pos.longitude),
              ));
      controller.move(currentLocation, 16.0);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get your location. Check GPS permission.'),
        ),
      );
    }
  }

  Future<void> _addAtVisibleCenter(BuildContext context) async {
    final center = lastCenter;
    if (center == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Map center is not ready yet.')),
      );
      return;
    }

    await onAddAtLatLng(maplat.LatLng(center.latitude, center.longitude));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 70.0, right: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'center_location',
                onPressed: () async => _centerOnCurrentLocation(context),
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'add_mission',
                onPressed: () async => _addAtVisibleCenter(context),
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
