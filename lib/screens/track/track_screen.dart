import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'random_workout_screen.dart';
import 'walk_screen.dart';
import '../workout/running/running_setup_screen.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Time to Move!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                  fontFamily: 'GeneralSans',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'What do you want to do today?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Color(0xFF9098A3)),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Center(
                  child: SvgPicture.asset(
                    'assets/flowy.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _activityButton(
                context: context,
                title: 'Random Workout',
                subtitle: 'Fun exercises with Flowy!',
                icon: Icons.fitness_center,
                color: const Color(0xFFFF6B6B),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RandomWorkoutScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _activityButton(
                context: context,
                title: 'Take a Walk',
                subtitle: 'Explore the outdoors',
                icon: Icons.directions_walk,
                color: const Color(0xFF4ECDC4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WalkScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _activityButton(
                context: context,
                title: 'Log a Run',
                subtitle: 'Track your pace and progress',
                icon: Icons.directions_run,
                color: const Color(0xFF2D82E8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RunningSetupScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFFB8C0CC),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
