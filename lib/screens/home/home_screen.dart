import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../widgets/flowy_companion.dart';
import '../../services/phone_data_listener.dart';
import '../../models/heart_rate_data.dart';
import '../health/health_screen.dart';

// Home Screen - Redesigned for beginners with Flowy companion
// Features: AI movement tracking, water/food reminders, beginner guidance
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onLogWater, this.onLogMeal});

  final VoidCallback? onLogWater;
  final VoidCallback? onLogMeal;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentFlowyMessage = '';

  // Live watch data
  int? _watchBpm;
  bool _watchConnected = false;
  DateTime? _lastWatchUpdate;
  StreamSubscription? _watchHrSub;
  final _phoneDataListener = PhoneDataListener();

  @override
  void initState() {
    super.initState();
    _updateFlowyMessage();
    _subscribeToWatch();
  }

  @override
  void dispose() {
    _watchHrSub?.cancel();
    super.dispose();
  }

  void _subscribeToWatch() {
    _phoneDataListener.startListening();
    _watchHrSub = _phoneDataListener.heartRateStream.listen(
      (HeartRateData data) {
        if (mounted) {
          setState(() {
            _watchBpm = data.bpm;
            _watchConnected = true;
            _lastWatchUpdate = DateTime.now();
          });
        }
      },
      onError: (_) {
        if (mounted) setState(() => _watchConnected = false);
      },
    );
  }

  void _updateFlowyMessage() {
    final hour = DateTime.now().hour;
    final messages = [
      if (hour < 12) "Good morning! Ready to start your fitness journey today?",
      if (hour >= 12 && hour < 17) "Hey there! Let's keep that energy going!",
      if (hour >= 17) "Evening vibes! Time to wind down with some movement!",
    ];

    setState(() {
      _currentFlowyMessage = messages.first;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getUserName() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final metadata = user?.userMetadata ?? const <String, dynamic>{};
      final name =
          metadata['full_name'] ?? metadata['name'] ?? metadata['nickname'];
      if (name is String && name.trim().isNotEmpty) {
        return name.trim().split(RegExp(r'\s+')).first;
      }

      final email = user?.email;
      if (email != null && email.contains('@')) {
        final localPart = email.split('@').first;
        if (localPart.trim().isNotEmpty) return localPart.trim();
      }
    } catch (_) {
      // Some widget tests build this screen without a Supabase singleton.
    }

    return 'Friend';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Friendly header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    theme.colorScheme.secondary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Greeting
                      Text(
                        '${_getGreeting()}, ${_getUserName()}! 👋',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Flowy Companion - Main feature
                      FlowyCompanion(message: _currentFlowyMessage, size: 140),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's Mission Card - Beginner friendly
                  _buildMissionCard(context),

                  const SizedBox(height: 16),

                  // Live Watch Heart Rate Card
                  _buildWatchHeartRateCard(context),

                  const SizedBox(height: 20),

                  // Reminders Section
                  _buildRemindersSection(context),

                  const SizedBox(height: 24),

                  // Core Features - Simplified for beginners
                  Text(
                    'Let\'s Get Moving! 🎯',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose an activity to start your journey',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Primary Action - AI movement tracking
                  _buildPrimaryFeatureCard(
                    context,
                    'Start AI Workout',
                    'Classify movement with your watch sensors',
                    SolarIconsBold.dumbbell,
                    Colors.blue,
                    () {
                      Navigator.pushNamed(context, '/activity-classifier');
                    },
                  ),

                  const SizedBox(height: 12),

                  // Secondary Features Grid
                  GridView.count(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      _buildFeatureCard(
                        context,
                        'Drink Water',
                        '💧',
                        Colors.cyan,
                        () {
                          _openHealthLog(context, HealthInitialAction.addWater);
                        },
                      ),
                      _buildFeatureCard(
                        context,
                        'Log Meal',
                        '🍽️',
                        Colors.orange,
                        () {
                          _openHealthLog(context, HealthInitialAction.addMeal);
                        },
                      ),
                      _buildFeatureCard(
                        context,
                        'Track Steps',
                        '👟',
                        Colors.green,
                        () {
                          Navigator.pushNamed(context, '/mission');
                        },
                      ),
                      _buildFeatureCard(
                        context,
                        'Heart Check',
                        '❤️',
                        Colors.red,
                        () {
                          Navigator.pushNamed(context, '/phone_heart_rate');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Progress Section
                  _buildProgressSection(context),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Live Galaxy Watch heart rate card
  Widget _buildWatchHeartRateCard(BuildContext context) {
    final theme = Theme.of(context);
    final connected = _watchConnected && _watchBpm != null;
    final color = connected ? Colors.red : Colors.grey;

    String subtitle;
    if (connected && _lastWatchUpdate != null) {
      final secs = DateTime.now().difference(_lastWatchUpdate!).inSeconds;
      subtitle = secs < 5 ? 'Live from Galaxy Watch' : 'Updated ${secs}s ago';
    } else {
      subtitle = 'Waiting for Galaxy Watch...';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              connected ? SolarIconsBold.heartPulse : Icons.watch_outlined,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Heart Rate',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  connected ? '$_watchBpm BPM' : '— BPM',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: connected ? Colors.green : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // Mission card for daily goals
  Widget _buildMissionCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              SolarIconsBold.flame,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '5-Day Streak! 🔥',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'re doing amazing! Keep it up!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Reminders for water and food
  Widget _buildRemindersSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FlowyMini(size: 32),
              const SizedBox(width: 12),
              Text(
                'Flowy\'s Reminders',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildReminderItem(
            context,
            '💧',
            'Drink water',
            'Stay hydrated! 8 glasses today',
            Colors.cyan,
          ),
          const SizedBox(height: 8),
          _buildReminderItem(
            context,
            '🍎',
            'Healthy snack',
            'Time for a nutritious bite',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(
    BuildContext context,
    String emoji,
    String title,
    String subtitle,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(SolarIconsBold.bell, color: color, size: 20),
        ],
      ),
    );
  }

  // Primary feature card (larger)
  Widget _buildPrimaryFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.8), color],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  // Secondary feature cards
  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String emoji,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Progress section
  Widget _buildProgressSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Progress 📊',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Steps',
                '6,504',
                '10,000',
                SolarIconsBold.walking,
                Colors.blue,
                0.65,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Calories',
                '320',
                '500',
                SolarIconsBold.flame,
                Colors.orange,
                0.64,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          context,
          'Active Minutes',
          '45',
          '60',
          SolarIconsBold.stopwatch,
          Colors.green,
          0.75,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    String goal,
    IconData icon,
    Color color,
    double progress,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' / $goal',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  void _openHealthLog(BuildContext context, HealthInitialAction action) {
    final callback = switch (action) {
      HealthInitialAction.addWater => widget.onLogWater,
      HealthInitialAction.addMeal => widget.onLogMeal,
    };

    if (callback != null) {
      callback();
      return;
    }

    Navigator.pushNamed(
      context,
      '/dashboard',
      arguments: {'initialTab': 1, 'healthAction': action.name},
    );
  }
}
