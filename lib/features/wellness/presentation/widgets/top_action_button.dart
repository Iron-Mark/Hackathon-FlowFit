import 'package:flutter/material.dart';

class TopActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  const TopActionButton({
    required this.icon,
    required this.onTap,
    required this.label,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surface.withAlpha((0.9 * 255).toInt()),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: IconButton(icon: Icon(icon), onPressed: onTap, tooltip: label),
    );
  }
}
