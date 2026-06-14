import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

class RelaxScreen extends StatefulWidget {
  final WearShape shape;
  final WearMode mode;

  const RelaxScreen({super.key, required this.shape, required this.mode});

  @override
  State<RelaxScreen> createState() => _RelaxScreenState();
}

class _RelaxScreenState extends State<RelaxScreen>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAmbient = widget.mode == WearMode.ambient;
    final isRound = widget.shape == WearShape.round;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background with gradient animation
          if (!isAmbient)
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.deepPurple.withValues(
                          alpha: _fadeAnimation.value * 0.6,
                        ),
                        Colors.black,
                        Colors.indigo.withValues(
                          alpha: _fadeAnimation.value * 0.4,
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            Container(color: Colors.black),

          // Content
          Center(
            child: Container(
              padding: EdgeInsets.all(isRound ? 20 : 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!isAmbient) ...[
                    const Text(
                      'Relax',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _buildPlayPauseButton(),
                    const SizedBox(height: 24),
                    Text(
                      _isPlaying ? 'Ocean Waves' : 'Tap to play',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Relax',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return SizedBox(
      width: 100,
      height: 100,
      child: ElevatedButton(
        onPressed: _togglePlayPause,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(20),
        ),
        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 40),
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        // TODO: Start audio playback using audioplayers plugin
      } else {
        // TODO: Pause audio playback
      }
    });
  }
}
