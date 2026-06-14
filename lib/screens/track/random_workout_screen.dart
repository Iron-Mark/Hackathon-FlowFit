import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
// import 'package:ultralytics_yolo/ultralytics_yolo.dart'; // Removed due to compilation errors
import '../../services/phone_data_listener.dart';
import '../../models/heart_rate_data.dart';

class RandomWorkoutScreen extends StatefulWidget {
  const RandomWorkoutScreen({super.key});

  @override
  State<RandomWorkoutScreen> createState() => _RandomWorkoutScreenState();
}

class _RandomWorkoutScreenState extends State<RandomWorkoutScreen> {
  // ObjectDetector? _objectDetector; // Removed
  StreamSubscription<HeartRateData>? _heartRateSubscription;
  int _heartRate = 0;
  int _squatCount = 0;
  // bool _isSquatting = false; // Unused
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initObjectDetector();
    _initHeartRateListener();
  }

  Future<void> _initObjectDetector() async {
    // Placeholder for camera initialization
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  void _initHeartRateListener() {
    final phoneDataListener = context.read<PhoneDataListener>();
    _heartRateSubscription = phoneDataListener.heartRateStream.listen((data) {
      if (mounted) {
        setState(() {
          _heartRate = data.bpm ?? 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _heartRateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera View Placeholder
          if (_isCameraInitialized)
            Container(
              color: Colors.grey[900],
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, color: Colors.white54, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Camera Preview',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'Squat detection model not loaded.\n(Waiting for model assets)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  'Initializing Camera...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

          // Overlay UI
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_heartRate BPM',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Flowy Character & Instructions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/flowy.svg', height: 80),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Let\'s do some Squats!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Count: $_squatCount',
                              style: const TextStyle(
                                color: Colors.yellow,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Simulate Button (For testing without actual detection)
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _squatCount++;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
