import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:solar_icons/solar_icons.dart';
import '../../core/providers/providers.dart' as core_providers;
import '../../providers/dashboard_providers.dart';
import 'package:flowfit/features/activity_classifier/presentation/providers.dart'
    as ac_providers;

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final dailyStatsAsync = ref.watch(dailyStatsProvider);
    final dailyMoodAsync = ref.watch(dailyMoodProvider);
    final heartRateAsync = ref.watch(core_providers.currentHeartRateProvider);
    final watchConnectedAsync = ref.watch(
      core_providers.watchConnectionStateProvider,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // Page Header
          _buildPageHeader(context, _getGreeting()),
          // Watch status banner for immediate visibility
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 6.0,
            ),
            child: watchConnectedAsync.when(
              data: (connected) => connected
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.watch,
                            size: 18,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Watch connected — live data available',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.watch_off,
                            size: 18,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Watch not connected — connect to enable live AI tracking',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                await ref
                                    .read(
                                      core_providers
                                          .connectionControlProvider
                                          .notifier,
                                    )
                                    .connect();
                              } catch (_) {}
                            },
                            child: const Text('Connect'),
                          ),
                        ],
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // Stats Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: dailyStatsAsync.when(
                            data: (s) => _buildStatCard(
                              context,
                              'Steps',
                              '${s.steps}',
                              Icons.directions_walk,
                              theme.colorScheme.primary,
                            ),
                            loading: () => _buildStatCard(
                              context,
                              'Steps',
                              '--',
                              Icons.directions_walk,
                              theme.colorScheme.primary,
                            ),
                            error: (_, __) => _buildStatCard(
                              context,
                              'Steps',
                              '--',
                              Icons.directions_walk,
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: dailyStatsAsync.when(
                            data: (s) => _buildStatCard(
                              context,
                              'Calories',
                              '${s.calories}',
                              Icons.local_fire_department,
                              theme.colorScheme.secondary,
                            ),
                            loading: () => _buildStatCard(
                              context,
                              'Calories',
                              '--',
                              Icons.local_fire_department,
                              theme.colorScheme.secondary,
                            ),
                            error: (_, __) => _buildStatCard(
                              context,
                              'Calories',
                              '--',
                              Icons.local_fire_department,
                              theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Minutes Card
                    dailyStatsAsync.when(
                      data: (s) => _buildStatCard(
                        context,
                        'Minutes',
                        '${s.activeMinutes}',
                        Icons.timer,
                        theme.colorScheme.tertiary,
                      ),
                      loading: () => _buildStatCard(
                        context,
                        'Minutes',
                        '--',
                        Icons.timer,
                        theme.colorScheme.tertiary,
                      ),
                      error: (_, __) => _buildStatCard(
                        context,
                        'Minutes',
                        '--',
                        Icons.timer,
                        theme.colorScheme.tertiary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Streak Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '🔥',
                              style: TextStyle(fontSize: 32),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You\'re on fire! 🎉',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '5-day streak. Keep it up!',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '5',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Track Section
                    Text(
                      'Quick Track',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick Track Grid (2x2) - improved
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            Navigator.pushNamed(
                              context,
                              '/activity-classifier',
                            );
                          },
                          child: _buildQuickTrackCard(
                            context,
                            'Quick Walk',
                            'Start now',
                            Icons.directions_run,
                            Colors.blue,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            // Navigate or trigger connect
                            final watchConnected = await ref.read(
                              core_providers
                                  .watchConnectionStateProvider
                                  .future,
                            );
                            if (!watchConnected) {
                              await ref
                                  .read(
                                    core_providers
                                        .connectionControlProvider
                                        .notifier,
                                  )
                                  .connect();
                            }
                          },
                          child: _buildAIActivityCard(
                            context,
                            ref,
                            dailyMoodAsync,
                            heartRateAsync,
                            watchConnectedAsync,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Add Meal
                          },
                          child: _buildQuickTrackCard(
                            context,
                            'Add Meal',
                            'Log food',
                            Icons.restaurant,
                            Colors.orange,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, "/mission");
                          },
                          child: _buildQuickTrackCard(
                            context,
                            'Challenges',
                            'Complete goals',
                            SolarIconsBold.target,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, String greeting) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
          Text(
            greeting,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Let's make today a great day.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIActivityCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> dailyMoodAsync,
    AsyncValue<dynamic> heartRateAsync,
    AsyncValue<bool> watchConnectedAsync,
  ) {
    final theme = Theme.of(context);
    // Try to read the provider-managed ActivityClassifierViewModel if available
    ac_providers.ActivityClassifierViewModel? classifierViewModel;
    try {
      classifierViewModel = provider_pkg
          .Provider.of<ac_providers.ActivityClassifierViewModel>(context);
    } catch (_) {
      classifierViewModel = null;
    }

    return watchConnectedAsync.when(
      data: (isConnected) {
        if (!isConnected) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerHighest,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          SolarIconsBold.cpu,
                          size: 20,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Activity',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Watch required for live stress tracking',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Connect your watch to enable live AI detection',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(
                                  core_providers
                                      .connectionControlProvider
                                      .notifier,
                                )
                                .connect();
                          } catch (_) {}
                        },
                        child: const Text('Connect'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // Watch connected – show live classification or fallback
        final activityLabel =
            classifierViewModel?.currentActivity?.label ?? 'Estimating';
        final probs =
            classifierViewModel?.currentActivity?.probabilities ??
            [0.0, 0.0, 0.0];
        final isStressed = activityLabel.toLowerCase().contains('stress');
        final bpm = heartRateAsync.when(
          data: (hr) => hr.bpm?.toString() ?? '--',
          loading: () => '--',
          error: (_, __) => '--',
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isStressed ? Colors.red : Colors.green)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      SolarIconsBold.cpu,
                      size: 20,
                      color: isStressed ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Activity (Live)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          activityLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isStressed ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Confidence: ${(probs.isNotEmpty ? (probs.first * 100).round() : 0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$bpm bpm',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: probs.isNotEmpty ? (probs.first.clamp(0.0, 1.0)) : 0,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isStressed ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _buildQuickTrackCard(
        context,
        'AI Activity',
        'Checking watch…',
        SolarIconsBold.cpu,
        Colors.deepPurple,
      ),
      error: (_, __) => _buildQuickTrackCard(
        context,
        'AI Activity',
        'AI down',
        SolarIconsBold.cpu,
        Colors.deepPurple,
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTrackCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
