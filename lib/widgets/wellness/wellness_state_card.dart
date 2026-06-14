import 'package:flutter/material.dart';
import '../../models/wellness_state.dart';

/// Card displaying current wellness state
class WellnessStateCard extends StatefulWidget {
  final WellnessStateData state;

  const WellnessStateCard({super.key, required this.state});

  @override
  State<WellnessStateCard> createState() => _WellnessStateCardState();
}

class _WellnessStateCardState extends State<WellnessStateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(WellnessStateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force rebuild when state changes (especially heart rate)
    if (oldWidget.state.heartRate != widget.state.heartRate ||
        oldWidget.state.state != widget.state.state) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.state.state.emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.state.state.displayName,
                      style: const TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.state.state.description,
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  icon: Icons.favorite,
                  label: 'Heart Rate',
                  value: widget.state.heartRate != null
                      ? '${widget.state.heartRate} BPM'
                      : '--',
                  color: Colors.red,
                  showPulse: widget.state.heartRate != null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetric(
                  icon: Icons.directions_walk,
                  label: 'Activity',
                  value: _getActivityLevel(widget.state.motionMagnitude),
                  color: Colors.blue,
                  showPulse: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool showPulse,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showPulse)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Icon(icon, size: 16, color: color),
                    );
                  },
                )
              else
                Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getActivityLevel(double? motion) {
    if (motion == null) return 'Unknown';
    if (motion < 0.5) return 'Resting';
    if (motion < 2.0) return 'Light';
    return 'Active';
  }
}
