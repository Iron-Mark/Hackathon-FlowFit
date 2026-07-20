import 'package:flutter/material.dart';

// Dialog that captures a food name and calorie amount for the health screen.
class AddFoodDialog extends StatefulWidget {
  const AddFoodDialog({super.key, required this.onAdd});

  final void Function(String name, String calories) onAdd;

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  bool _hasSubmitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_hasSubmitted) return;

    final name = _nameController.text.trim();
    final calories = _caloriesController.text.trim();
    if (name.isEmpty || calories.isEmpty) return;

    _hasSubmitted = true;
    widget.onAdd(name, calories);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Food'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Food Name',
            textField: true,
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Food Name',
                hintText: 'e.g., Banana',
              ),
              autofocus: true,
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Calories',
            textField: true,
            child: TextField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories',
                hintText: 'e.g., 105',
                suffixText: 'kcal',
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _submit(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
