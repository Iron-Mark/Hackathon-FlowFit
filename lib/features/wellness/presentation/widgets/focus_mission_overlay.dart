// dart:async left out because no timers used in this widget
import 'package:flutter/material.dart';
// latlong import not required here; overlay uses GeofenceMission object only
import '../../domain/geofence_mission.dart';

class FocusMissionOverlay extends StatelessWidget {
  final GeofenceMission mission;
  final double distanceMeters;
  final Duration eta;
  final bool isActive;
  final double speedMetersPerSecond;
  final VoidCallback onUnfocus;
  final VoidCallback onCenter;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final void Function(double) onSpeedChanged;

  const FocusMissionOverlay({
    required this.mission,
    required this.distanceMeters,
    required this.eta,
    required this.isActive,
    required this.speedMetersPerSecond,
    required this.onUnfocus,
    required this.onCenter,
    required this.onActivate,
    required this.onDeactivate,
    required this.onSpeedChanged,
    super.key,
  });

  String _formatEta(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes} min';
    }
    return '${d.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${distanceMeters.toStringAsFixed(0)} m • ETA ${_formatEta(eta)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onCenter,
                    icon: const Icon(Icons.my_location),
                  ),
                  IconButton(
                    onPressed: onUnfocus,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      min: 0.5,
                      max: 5.0,
                      divisions: 9,
                      value: speedMetersPerSecond,
                      label: '${speedMetersPerSecond.toStringAsFixed(1)} m/s',
                      onChanged: (v) => onSpeedChanged(v),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    '${speedMetersPerSecond.toStringAsFixed(1)} m/s',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isActive
                          ? () => onDeactivate()
                          : () => onActivate(),
                      icon: Icon(isActive ? Icons.stop : Icons.play_arrow),
                      label: Text(isActive ? 'Stop' : 'Start'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
