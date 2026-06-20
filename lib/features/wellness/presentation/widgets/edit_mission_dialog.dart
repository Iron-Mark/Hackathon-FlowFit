import 'package:flutter/material.dart';
import '../../domain/geofence_mission.dart';

class EditMissionDialog extends StatefulWidget {
  final GeofenceMission mission;
  const EditMissionDialog({required this.mission, super.key});

  @override
  State<EditMissionDialog> createState() => _EditMissionDialogState();
}

class _EditMissionDialogState extends State<EditMissionDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetDistanceController;
  late MissionType _type;
  late double _radius;
  double? _targetDistance;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.mission.title);
    _descriptionController = TextEditingController(
      text: widget.mission.description ?? '',
    );
    _type = widget.mission.type;
    _radius = widget.mission.radiusMeters;
    _targetDistance = widget.mission.targetDistanceMeters;
    _targetDistanceController = TextEditingController(
      text: _targetDistance?.toString() ?? '',
    );
  }

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
      title: const Text('Edit Mission'),
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
                    max: 2000,
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
            final title = _titleController.text.trim();
            final description = _descriptionController.text.trim();
            final updated = GeofenceMission(
              id: widget.mission.id,
              title: title.isEmpty ? widget.mission.title : title,
              description: description.isEmpty ? null : description,
              center: widget.mission.center,
              radiusMeters: _radius,
              type: _type,
              isActive: widget.mission.isActive,
              targetDistanceMeters: _type == MissionType.target
                  ? _targetDistance
                  : null,
              status: widget.mission.status,
            );
            Navigator.of(context).pop(updated);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
