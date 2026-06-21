import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as maplat;
import '../../domain/geofence_mission.dart';

class PlaceModeOverlay extends StatelessWidget {
  final bool visible;
  final maplat.LatLng? latLng;
  final double radius;
  final TextEditingController titleController;
  final MissionType type;
  final void Function(double) onRadiusChanged;
  final void Function(MissionType?) onTypeChanged;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const PlaceModeOverlay({
    required this.visible,
    required this.latLng,
    required this.radius,
    required this.titleController,
    required this.type,
    required this.onRadiusChanged,
    required this.onTypeChanged,
    required this.onCancel,
    required this.onConfirm,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible && latLng != null,
      child: Positioned(
        top: 120,
        left: 20,
        right: 20,
        child: Card(
          elevation: 6.0,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onCancel,
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const Text('Radius'),
                    Expanded(
                      child: Slider(
                        min: 10,
                        max: 2000,
                        value: radius,
                        onChanged: onRadiusChanged,
                      ),
                    ),
                    Text('${radius.toStringAsFixed(0)}m'),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<MissionType>(
                        value: type,
                        isExpanded: true,
                        items: MissionType.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.name),
                              ),
                            )
                            .toList(),
                        onChanged: onTypeChanged,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: onConfirm,
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
