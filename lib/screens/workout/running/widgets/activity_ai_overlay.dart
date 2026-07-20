import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:flowfit/features/activity_classifier/presentation/providers.dart';

/// Gradient badge showing the AI-detected activity mode (or an analyzing
/// state while no activity has been classified yet).
///
/// Pure display: rebuilds are driven by the shell's `ref.watch` of the
/// classifier view model.
class ActivityModeBadge extends StatelessWidget {
  const ActivityModeBadge({super.key, required this.viewModel});

  final ActivityClassifierViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🎨 Building badge - Activity: ${viewModel.currentActivity?.label}, Loading: ${viewModel.isLoading}',
    );

    // Show loading state while detecting
    if (viewModel.currentActivity == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withValues(alpha: 0.9),
              const Color(0xFF8B5CF6).withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI Activity Detection',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Analyzing...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final activity = viewModel.currentActivity!;
    final modeLabel = activity.label.toUpperCase();
    final confidence = activity.confidence;

    // Define colors and icons for each mode
    Color modeColor = Colors.green;
    IconData modeIcon = SolarIconsBold.leaf;

    switch (activity.label) {
      case 'Stress':
        modeColor = Colors.red;
        modeIcon = SolarIconsBold.danger;
        break;
      case 'Cardio':
        modeColor = Colors.orange;
        modeIcon = SolarIconsBold.heartPulse;
        break;
      case 'Strength':
        modeColor = Colors.green;
        modeIcon = SolarIconsBold.leaf;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            modeColor.withValues(alpha: 0.9),
            modeColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: modeColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(modeIcon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AI Activity Mode',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    modeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card breaking down the classifier's per-activity probabilities.
///
/// Callers must only build this when `viewModel.currentActivity` is non-null,
/// matching the pre-extraction call-site guard.
class AiMetricsBreakdown extends StatelessWidget {
  const AiMetricsBreakdown({super.key, required this.viewModel});

  final ActivityClassifierViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final probabilities = viewModel.currentActivity!.probabilities;
    final stressProb = probabilities[0];
    final cardioProb = probabilities[1];
    final strengthProb = probabilities[2];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(SolarIconsBold.cpu, size: 16, color: Color(0xFF8B5CF6)),
              SizedBox(width: 6),
              Text(
                'AI Detection Breakdown',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stress metric
          ProbabilityBar(
            label: 'Stress',
            probability: stressProb,
            color: Colors.red,
            icon: SolarIconsBold.danger,
          ),
          const SizedBox(height: 8),

          // Cardio metric
          ProbabilityBar(
            label: 'Cardio',
            probability: cardioProb,
            color: Colors.orange,
            icon: SolarIconsBold.heartPulse,
          ),
          const SizedBox(height: 8),

          // Strength metric
          ProbabilityBar(
            label: 'Strength',
            probability: strengthProb,
            color: Colors.green,
            icon: SolarIconsBold.leaf,
          ),
        ],
      ),
    );
  }
}

/// Single labeled probability row with a linear progress bar.
class ProbabilityBar extends StatelessWidget {
  const ProbabilityBar({
    super.key,
    required this.label,
    required this.probability,
    required this.color,
    required this.icon,
  });

  final String label;
  final double probability;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final percentage = (probability * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: probability,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
