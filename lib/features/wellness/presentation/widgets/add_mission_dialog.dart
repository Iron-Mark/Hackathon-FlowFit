import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as maplat;
import '../../domain/geofence_mission.dart';

class AddMissionDialog extends StatefulWidget {
  final maplat.LatLng latLng;
  const AddMissionDialog({required this.latLng, super.key});

  @override
  State<AddMissionDialog> createState() => _AddMissionDialogState();
}

class _AddMissionDialogState extends State<AddMissionDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _targetDistanceController =
      TextEditingController();
  MissionType _type = MissionType.sanctuary;
  double _radius = 50.0;
  double? _targetDistance;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetDistanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Mission'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            DropdownButton<MissionType>(
              value: _type,
              items: MissionType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _type = v ?? MissionType.sanctuary),
            ),
            Row(
              children: [
                const Text('Radius (m)'),
                Expanded(
                  child: Slider(
                    min: 10,
                    max: 1000,
                    value: _radius,
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                ),
                Text(_radius.toStringAsFixed(0)),
              ],
            ),
            if (_type == MissionType.target)
              TextField(
                controller: _targetDistanceController,
                decoration: const InputDecoration(
                  labelText: 'Target distance (m)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    setState(() => _targetDistance = double.tryParse(v)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final id = DateTime.now().millisecondsSinceEpoch.toString();
            final title = _titleController.text.trim();
            final description = _descriptionController.text.trim();
            final mission = GeofenceMission(
              id: id,
              title: title.isEmpty ? 'Mission $id' : title,
              description: description.isEmpty ? null : description,
              center: LatLngSimple(
                widget.latLng.latitude,
                widget.latLng.longitude,
              ),
              radiusMeters: _radius,
              type: _type,
              targetDistanceMeters: _targetDistance,
            );
            Navigator.of(context).pop(mission);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
