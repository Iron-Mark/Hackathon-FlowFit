import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/permission_status.dart';
import '../../services/watch_bridge.dart';

typedef WellnessSetupChecker = Future<WellnessSetupStatus> Function();

class WellnessSetupStatus {
  const WellnessSetupStatus({
    required this.hasPermissions,
    required this.isWatchConnected,
    required this.message,
  });

  final bool hasPermissions;
  final bool isWatchConnected;
  final String message;

  bool get isReady => hasPermissions && isWatchConnected;
}

Future<WellnessSetupStatus> checkWellnessDeviceSetup() async {
  final watchBridge = WatchBridgeService();

  try {
    final hasBodySensors = await _ensureBodySensorPermission(watchBridge);
    final hasLocation = await _ensureLocationPermission();
    final isWatchConnected = await _ensureWatchConnection(watchBridge);
    final missing = <String>[
      if (!hasBodySensors) 'body sensors permission',
      if (!hasLocation) 'location permission',
      if (!isWatchConnected) 'Samsung Galaxy Watch connection',
    ];

    return WellnessSetupStatus(
      hasPermissions: hasBodySensors && hasLocation,
      isWatchConnected: isWatchConnected,
      message: missing.isEmpty
          ? 'Setup verified. You can start wellness tracking.'
          : 'Still needed: ${missing.join(', ')}.',
    );
  } finally {
    watchBridge.dispose();
  }
}

Future<bool> _ensureBodySensorPermission(WatchBridgeService watchBridge) async {
  try {
    final nativeStatus = await watchBridge.checkPermission();
    if (nativeStatus == 'granted') {
      return true;
    }

    return watchBridge.requestPermission();
  } catch (_) {
    try {
      final fallbackStatus = await watchBridge.checkBodySensorPermission();
      if (fallbackStatus == PermissionStatus.granted) {
        return true;
      }

      return watchBridge.requestBodySensorPermission();
    } catch (_) {
      return false;
    }
  }
}

Future<bool> _ensureLocationPermission() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  } catch (_) {
    return false;
  }
}

Future<bool> _ensureWatchConnection(WatchBridgeService watchBridge) async {
  try {
    if (await watchBridge.isWatchConnected()) {
      return true;
    }

    return watchBridge.connectToWatch();
  } catch (_) {
    return false;
  }
}

/// Onboarding screen for wellness tracker first-time users
class WellnessOnboardingScreen extends StatefulWidget {
  const WellnessOnboardingScreen({
    super.key,
    this.setupChecker = checkWellnessDeviceSetup,
  });

  final WellnessSetupChecker setupChecker;

  static const String _onboardingCompleteKey = 'wellness_onboarding_complete';

  /// Check if onboarding has been completed
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  @override
  State<WellnessOnboardingScreen> createState() =>
      _WellnessOnboardingScreenState();
}

class _WellnessOnboardingScreenState extends State<WellnessOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCheckingPermissions = false;
  bool _hasPermissions = false;
  bool _isWatchConnected = false;
  String? _setupMessage;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(WellnessOnboardingScreen._onboardingCompleteKey, true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/wellness-tracker');
    }
  }

  Future<void> _checkPermissionsAndWatch() async {
    if (_isCheckingPermissions) return;

    setState(() {
      _isCheckingPermissions = true;
      _setupMessage = null;
    });

    try {
      final status = await widget.setupChecker();
      if (!mounted) {
        return;
      }

      setState(() {
        _hasPermissions = status.hasPermissions;
        _isWatchConnected = status.isWatchConnected;
        _setupMessage = status.message;
        _isCheckingPermissions = false;
      });

      // The setup page renders this message inline above the bottom action.
      // Keeping it out of a bottom SnackBar leaves the retry CTA tappable.
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = 'Setup check failed: $error';
      setState(() {
        _hasPermissions = false;
        _isWatchConnected = false;
        _setupMessage = message;
        _isCheckingPermissions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? const Color(0xFF3B82F6)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [_buildPage1(), _buildPage2(), _buildPage3()],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text(
                        'Back',
                        style: TextStyle(fontFamily: 'GeneralSans'),
                      ),
                    ),
                  const Spacer(),
                  if (_currentPage < 2)
                    ElevatedButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: _isCheckingPermissions
                          ? null
                          : (_hasPermissions && _isWatchConnected
                                ? _completeOnboarding
                                : _checkPermissionsAndWatch),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isCheckingPermissions
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _hasPermissions && _isWatchConnected
                                  ? 'Get Started'
                                  : 'Check Setup',
                              style: const TextStyle(
                                fontFamily: 'GeneralSans',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return _buildOnboardingPage([
      Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.favorite, size: 60, color: Color(0xFF3B82F6)),
      ),
      const SizedBox(height: 40),
      const Text(
        'Welcome to Wellness Tracker',
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      Text(
        'We\'ll monitor your heart rate and movement to help you understand your wellness state throughout the day',
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 16,
          color: Colors.grey[600],
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    ]);
  }

  Widget _buildPage2() {
    return _buildOnboardingPage([
      Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.spa, size: 60, color: Colors.green),
      ),
      const SizedBox(height: 40),
      const Text(
        'Personalized Recommendations',
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      Text(
        'Get real-time suggestions for calming walks when stress is detected, plus foreground geofence mission progress and automatic workout tracking when you exercise',
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 16,
          color: Colors.grey[600],
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 32),
      _buildFeatureItem(
        icon: Icons.directions_walk,
        title: 'Stress Relief Routes',
        subtitle: 'Calming walks near you',
      ),
      const SizedBox(height: 16),
      _buildFeatureItem(
        icon: Icons.fitness_center,
        title: 'Exercise Detection',
        subtitle: 'Auto-track your workouts',
      ),
      const SizedBox(height: 16),
      _buildFeatureItem(
        icon: Icons.insights,
        title: 'Daily Insights',
        subtitle: 'Understand your patterns',
      ),
    ]);
  }

  Widget _buildPage3() {
    return _buildOnboardingPage([
      Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.lock, size: 60, color: Colors.purple),
      ),
      const SizedBox(height: 40),
      const Text(
        'Your Data Stays Private',
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      Text(
        'Live wellness state is calculated on your device. Account, workout, heart-rate, and mission records can sync to Supabase over HTTPS and are protected by app access controls.',
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 16,
          color: Colors.grey[600],
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 32),
      Container(
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
          children: [
            _buildSetupItem(
              icon: Icons.watch,
              title: 'Samsung Galaxy Watch',
              status: _isWatchConnected ? 'Connected' : 'Not Connected',
              isSuccess: _isWatchConnected,
            ),
            const Divider(height: 32),
            _buildSetupItem(
              icon: Icons.sensors,
              title: 'Body Sensors and Location',
              status: _hasPermissions ? 'Granted' : 'Required',
              isSuccess: _hasPermissions,
            ),
          ],
        ),
      ),
      if (_setupMessage != null) ...[
        const SizedBox(height: 16),
        Text(
          _setupMessage!,
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 14,
            color: _hasPermissions && _isWatchConnected
                ? Colors.green[700]
                : Colors.orange[700],
          ),
          textAlign: TextAlign.center,
        ),
      ] else if (!_hasPermissions || !_isWatchConnected) ...[
        const SizedBox(height: 16),
        Text(
          'Check setup to request body sensors and location permission, then verify your Samsung Galaxy Watch connection.',
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 14,
            color: Colors.orange[700],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ]);
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupItem({
    required IconData icon,
    required String title,
    required String status,
    required bool isSuccess,
  }) {
    return Row(
      children: [
        Icon(icon, color: isSuccess ? Colors.green : Colors.orange, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 12,
                  color: isSuccess ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ),
        Icon(
          isSuccess ? Icons.check_circle : Icons.warning,
          color: isSuccess ? Colors.green : Colors.orange,
        ),
      ],
    );
  }
}
