import 'package:flutter/material.dart';

import 'package:flowfit/features/activity_classifier/presentation/watch_data_listener.dart';

/// Source selection and simulation controls for the tracker page: the heart
/// rate display/simulation block, the accelerometer source chips (with the
/// synthetic-signal sliders), and the BPM source chips.
class TrackerSourceControls extends StatelessWidget {
  const TrackerSourceControls({
    super.key,
    required this.accelSource,
    required this.bpmSource,
    required this.currentBpmValue,
    required this.simulatedHr,
    required this.forceSimulate,
    required this.accelAmplitude,
    required this.accelFreqHz,
    required this.onAccelSourceChanged,
    required this.onBpmSourceChanged,
    required this.onForceSimulateChanged,
    required this.onSimulatedHrChanged,
    required this.onAccelAmplitudeChanged,
    required this.onAccelFreqHzChanged,
  });

  final AccelSource accelSource;
  final BpmSource bpmSource;
  final int? currentBpmValue;
  final double simulatedHr;
  final bool forceSimulate;
  final double accelAmplitude;
  final double accelFreqHz;
  final ValueChanged<AccelSource> onAccelSourceChanged;
  final ValueChanged<BpmSource> onBpmSourceChanged;
  final ValueChanged<bool> onForceSimulateChanged;
  final ValueChanged<double> onSimulatedHrChanged;
  final ValueChanged<double> onAccelAmplitudeChanged;
  final ValueChanged<double> onAccelFreqHzChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 3. Heart Rate Source Display
        if (bpmSource == BpmSource.watch && currentBpmValue != null) ...[
          // Show live watch heart rate
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: Column(
              children: [
                const Text(
                  '❤️ Live Watch Heart Rate',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '$currentBpmValue BPM',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Using real-time data from Galaxy Watch',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ] else ...[
          // Show simulation controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Simulate Heart Rate: ${simulatedHr.round()} BPM',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  const Text('Use simulation'),
                  Switch(
                    value: forceSimulate,
                    onChanged: bpmSource == BpmSource.simulation
                        ? onForceSimulateChanged
                        : null, // Disable when not in simulation mode
                  ),
                ],
              ),
            ],
          ),
          Slider(
            min: 60,
            max: 180,
            value: simulatedHr,
            onChanged: bpmSource == BpmSource.simulation
                ? onSimulatedHrChanged
                : null, // Disable when not in simulation mode
            activeColor: Colors.red,
          ),
          const SizedBox(height: 4),
          Text(
            bpmSource == BpmSource.simulation
                ? 'Drag slider HIGH to simulate Panic/Running'
                : 'Switch to Simulation mode to use slider',
            style: TextStyle(
              color: bpmSource == BpmSource.simulation
                  ? Colors.black
                  : Colors.grey,
            ),
          ),
        ],

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        // Accelerometer Source Selection
        const Text(
          'Accelerometer Source',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Phone'),
              selected: accelSource == AccelSource.phone,
              onSelected: (s) => onAccelSourceChanged(AccelSource.phone),
            ),
            ChoiceChip(
              label: const Text('Simulation'),
              selected: accelSource == AccelSource.simulation,
              onSelected: (s) => onAccelSourceChanged(AccelSource.simulation),
            ),
            ChoiceChip(
              label: const Text('Watch'),
              selected: accelSource == AccelSource.watch,
              onSelected: (s) => onAccelSourceChanged(AccelSource.watch),
            ),
          ],
        ),

        // Simulation controls (only show when simulation is selected)
        if (accelSource == AccelSource.simulation) ...[
          const SizedBox(height: 16),
          const Text(
            'Simulation Controls',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Amplitude:'),
              Expanded(
                child: Slider(
                  min: 0.0,
                  max: 2.0,
                  value: accelAmplitude,
                  onChanged: onAccelAmplitudeChanged,
                  divisions: 20,
                  label: accelAmplitude.toStringAsFixed(2),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Frequency:'),
              Expanded(
                child: Slider(
                  min: 0.5,
                  max: 4.0,
                  value: accelFreqHz,
                  onChanged: onAccelFreqHzChanged,
                  divisions: 35,
                  label: '${accelFreqHz.toStringAsFixed(2)}Hz',
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),

        // Heart Rate Source Selection
        const Text(
          'Heart Rate Source',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Simulation'),
              selected: bpmSource == BpmSource.simulation,
              onSelected: (s) => onBpmSourceChanged(BpmSource.simulation),
            ),
            ChoiceChip(
              label: const Text('Plugin'),
              selected: bpmSource == BpmSource.plugin,
              onSelected: (s) => onBpmSourceChanged(BpmSource.plugin),
            ),
            ChoiceChip(
              label: const Text('Watch HR'),
              selected: bpmSource == BpmSource.watch,
              onSelected: (s) => onBpmSourceChanged(BpmSource.watch),
            ),
          ],
        ),
      ],
    );
  }
}
