import 'package:flutter/material.dart';

// Dialog that edits the bed and wake-up times for the health screen.
class EditSleepDialog extends StatefulWidget {
  const EditSleepDialog({
    super.key,
    required this.bedTime,
    required this.wakeTime,
    required this.pickTime,
    required this.onSave,
  });

  final TimeOfDay bedTime;
  final TimeOfDay wakeTime;
  final Future<TimeOfDay?> Function(BuildContext context, TimeOfDay initialTime)
  pickTime;
  final void Function(TimeOfDay bedTime, TimeOfDay wakeTime) onSave;

  @override
  State<EditSleepDialog> createState() => _EditSleepDialogState();
}

class _EditSleepDialogState extends State<EditSleepDialog> {
  late TimeOfDay _tempBedTime = widget.bedTime;
  late TimeOfDay _tempWakeTime = widget.wakeTime;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Sleep Schedule'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Bed Time'),
            trailing: Text(_tempBedTime.format(context)),
            onTap: () async {
              final time = await widget.pickTime(context, _tempBedTime);
              if (time != null) {
                setState(() => _tempBedTime = time);
              }
            },
          ),
          ListTile(
            title: const Text('Wake Up Time'),
            trailing: Text(_tempWakeTime.format(context)),
            onTap: () async {
              final time = await widget.pickTime(context, _tempWakeTime);
              if (time != null) {
                setState(() => _tempWakeTime = time);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_tempBedTime, _tempWakeTime);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
