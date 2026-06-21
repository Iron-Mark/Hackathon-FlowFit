import 'package:flutter/material.dart';
import 'dart:async';
import 'package:solar_icons/solar_icons.dart';
import '../models/tracked_data.dart';
import '../services/database_service.dart';
import '../services/phone_data_listener.dart';
import '../services/heart_rate_data_manager.dart';
import 'package:logger/logger.dart';

class PhoneHomePage extends StatefulWidget {
  const PhoneHomePage({super.key, HeartRateDataStore? dataStore})
    : _dataStore = dataStore;

  final HeartRateDataStore? _dataStore;

  @override
  State<PhoneHomePage> createState() => _PhoneHomePageState();
}

class _PhoneHomePageState extends State<PhoneHomePage> {
  final PhoneDataListener _dataListener = PhoneDataListener();
  late final HeartRateDataManager _dataManager;
  late final DataSyncManager _syncManager;
  final Logger _logger = Logger();

  List<TrackedData> _heartRateHistory = [];
  TrackedData? _latestHeartRate;
  bool _isConnected = false;
  bool _isStartingListener = false;
  bool _isFlushingData = false;
  bool _isConfirmingClear = false;
  bool _isClearingData = false;
  String _statusMessage = 'Waiting for watch data...';
  Map<String, dynamic> _statistics = {};

  StreamSubscription? _heartRateSubscription;
  StreamSubscription? _dataManagerSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    // Initialize data manager
    _dataManager = HeartRateDataManager(
      dbService: widget._dataStore,
      maxBufferSize: 100,
      maxDatabaseRecords: 10000,
      ibiHistorySize: 10,
    );

    // Initialize sync manager
    _syncManager = DataSyncManager(dbService: widget._dataStore);
    _syncManager.startPeriodicSync(interval: const Duration(minutes: 15));

    // Listen to data manager stream
    _dataManagerSubscription = _dataManager.dataStream.listen((trackedData) {
      setState(() {
        _latestHeartRate = trackedData;
        _statistics = _dataManager.getStatistics();

        // Update history list in real-time
        _heartRateHistory.insert(0, trackedData);

        // Keep only last 50 readings in UI
        if (_heartRateHistory.length > 50) {
          _heartRateHistory = _heartRateHistory.sublist(0, 50);
        }
      });
    });

    // Listen for heart rate data from watch
    _heartRateSubscription = _dataListener.heartRateStream.listen(
      (heartRateData) async {
        // Convert HeartRateData to TrackedData
        final trackedData = TrackedData(
          hr: heartRateData.bpm ?? 0,
          ibiValues: heartRateData.ibiValues,
          hrv: TrackedData.calculateHRV(heartRateData.ibiValues),
          spo2: 0, // Not available yet
          timestamp: heartRateData.timestamp,
          status: heartRateData.status,
        );

        // Add to data manager (handles buffer and database)
        await _dataManager.addData(trackedData);

        // Update UI
        setState(() {
          _isConnected = true;
          _statusMessage = 'Received from watch';
        });

        _logger.i(
          '✅ Heart rate received: ${trackedData.hr} BPM, IBI: ${trackedData.ibiValues.length}, HRV: ${trackedData.hrv.toStringAsFixed(1)}',
        );
      },
      onError: (error) {
        _logger.e('❌ Stream error: $error');
        setState(() {
          _statusMessage =
              'Watch data stream stopped. Check Bluetooth and Wear OS connection, then retry.';
          _isConnected = false;
        });
      },
    );

    _startListening();

    // Load recent history
    _loadRecentHistory();
  }

  Future<void> _startListening() async {
    if (_isStartingListener) return;

    if (mounted) {
      setState(() {
        _isStartingListener = true;
        _statusMessage = 'Starting watch listener...';
      });
    }

    final started = await _dataListener.startListening();
    if (!mounted) return;

    setState(() {
      _isStartingListener = false;
      if (started) {
        _statusMessage = _isConnected
            ? _statusMessage
            : 'Listening for watch data...';
      } else {
        _isConnected = false;
        _statusMessage =
            'Could not start watch listener. Check Bluetooth and Wear OS connection, then retry.';
      }
    });
  }

  Future<void> _loadRecentHistory() async {
    try {
      // Get data from buffer and database
      final recentData = await _dataManager.getRecentData(limit: 50);

      if (mounted) {
        setState(() {
          _heartRateHistory = recentData;
          _statistics = _dataManager.getStatistics();
        });
        _logger.d('Loaded ${recentData.length} recent readings');
      }
    } catch (e) {
      _logger.e('Error loading history: $e');
    }
  }

  /// Refresh history from data manager
  Future<void> _refreshHistory() async {
    await _loadRecentHistory();
  }

  @override
  void dispose() {
    _heartRateSubscription?.cancel();
    _dataManagerSubscription?.cancel();
    unawaited(
      _dataManager.dispose().catchError((Object error, StackTrace stack) {
        _logger.e('Error disposing heart rate data manager', error: error);
      }),
    );
    _syncManager.dispose();
    _dataListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar.large(
              title: const Text('FlowFit'),
              actions: [
                // Test Mode / Sensor Data button
                IconButton(
                  icon: const Icon(Icons.sensors),
                  tooltip: 'Sensor Data (Test Mode)',
                  onPressed: () {
                    Navigator.pushNamed(context, '/phone_heart_rate');
                  },
                ),
                // Statistics badge
                if (_statistics.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_statistics['buffer_size'] ?? 0} buffered',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    _isConnected ? Icons.watch : Icons.watch_outlined,
                    color: _isConnected ? Colors.green : Colors.grey,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isConnected
                              ? 'Connected to Galaxy Watch'
                              : 'Watch not connected',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Current Heart Rate Card
                  _buildCurrentHeartRateCard(colorScheme),

                  const SizedBox(height: 16),

                  // Stats Row
                  _buildStatsRow(colorScheme),

                  const SizedBox(height: 16),

                  // Status Card
                  _buildStatusCard(colorScheme),

                  const SizedBox(height: 16),

                  // Recent Readings
                  _buildRecentReadingsCard(colorScheme),

                  const SizedBox(height: 80), // Space for FAB
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flush buffer button
          if (_statistics['buffer_size'] != null &&
              _statistics['buffer_size'] > 0)
            FloatingActionButton.extended(
              onPressed: _isFlushingData
                  ? null
                  : () async {
                      if (_isFlushingData) return;

                      setState(() => _isFlushingData = true);
                      try {
                        final pendingRecords =
                            _statistics['buffer_size'] as int? ?? 0;
                        await _dataManager.forceFlush();
                        await _refreshHistory();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Flushed $pendingRecords records to database',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isFlushingData = false);
                        }
                      }
                    },
              heroTag: 'flush',
              icon: const Icon(SolarIconsBold.diskette),
              label: Text(
                _isFlushingData
                    ? 'Saving...'
                    : 'Save ${_statistics['buffer_size']}',
              ),
              backgroundColor: colorScheme.secondary,
            ),
          const SizedBox(height: 8),
          // Clear button
          FloatingActionButton.extended(
            onPressed: _isConfirmingClear || _isClearingData
                ? null
                : () async {
                    if (_isConfirmingClear || _isClearingData) return;

                    setState(() => _isConfirmingClear = true);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear All Data'),
                        content: const Text(
                          'This will clear all heart rate data. Continue?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );

                    if (!mounted) return;
                    setState(() => _isConfirmingClear = false);

                    if (confirm == true) {
                      setState(() => _isClearingData = true);
                      try {
                        await _dataManager.clearAllData();
                        if (!mounted) return;
                        setState(() {
                          _heartRateHistory.clear();
                          _latestHeartRate = null;
                          _statistics = _dataManager.getStatistics();
                          _statusMessage = 'Cleared all data';
                        });
                      } finally {
                        if (mounted) {
                          setState(() => _isClearingData = false);
                        }
                      }
                    }
                  },
            heroTag: 'clear',
            icon: const Icon(SolarIconsBold.trashBinMinimalistic),
            label: Text(_isClearingData ? 'Clearing...' : 'Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentHeartRateCard(ColorScheme colorScheme) {
    final bpm = _latestHeartRate?.hr;
    final hrv = _latestHeartRate?.hrv;
    final ibiValues = _latestHeartRate?.ibiValues ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  SolarIconsBold.heartPulse,
                  color: colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Current Heart Rate',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (bpm != null && bpm > 0) ...[
              Text(
                '$bpm',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'BPM',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _buildHeartRateZone(bpm, colorScheme),

              // HRV Display
              if (hrv != null && hrv > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        SolarIconsBold.pulse,
                        size: 20,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'HRV: ${hrv.toStringAsFixed(1)} ms',
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // IBI Display
              if (ibiValues.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'IBI: ${ibiValues.take(5).join(", ")} ms',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ] else ...[
              Icon(
                SolarIconsOutline.heartBroken,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'No data yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRateZone(int bpm, ColorScheme colorScheme) {
    String zone;
    Color zoneColor;

    if (bpm < 60) {
      zone = 'Resting';
      zoneColor = Colors.blue;
    } else if (bpm < 100) {
      zone = 'Light';
      zoneColor = Colors.green;
    } else if (bpm < 140) {
      zone = 'Moderate';
      zoneColor = Colors.orange;
    } else if (bpm < 170) {
      zone = 'Hard';
      zoneColor = Colors.deepOrange;
    } else {
      zone = 'Maximum';
      zoneColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: zoneColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: zoneColor, width: 2),
      ),
      child: Text(
        zone,
        style: TextStyle(color: zoneColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatsRow(ColorScheme colorScheme) {
    final validData = _heartRateHistory.where((d) => d.hr > 0).toList();

    final avgBpm = validData.isNotEmpty
        ? validData.map((d) => d.hr).reduce((a, b) => a + b) ~/ validData.length
        : 0;

    final maxBpm = validData.isNotEmpty
        ? validData.map((d) => d.hr).reduce((a, b) => a > b ? a : b)
        : 0;

    final minBpm = validData.isNotEmpty
        ? validData.map((d) => d.hr).reduce((a, b) => a < b ? a : b)
        : 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Average',
            '$avgBpm',
            SolarIconsBold.chartSquare,
            colorScheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Max',
            '$maxBpm',
            SolarIconsBold.altArrowUp,
            colorScheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Min',
            '$minBpm',
            SolarIconsBold.altArrowDown,
            colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ColorScheme colorScheme) {
    final canRetry =
        !_isStartingListener &&
        !_isConnected &&
        (_statusMessage.startsWith('Could not start') ||
            _statusMessage.startsWith('Watch data stream stopped'));

    return Card(
      color: _isConnected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isConnected
                  ? SolarIconsBold.checkCircle
                  : SolarIconsOutline.infoCircle,
              color: _isConnected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isConnected ? 'Connected' : 'Waiting',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _isConnected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _statusMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _isConnected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (canRetry) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _startListening,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReadingsCard(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(SolarIconsBold.history, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recent Readings',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_heartRateHistory.length} readings',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_heartRateHistory.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.watch_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No readings yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start tracking on your watch',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _heartRateHistory.length > 10
                    ? 10
                    : _heartRateHistory.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final data = _heartRateHistory[index];
                  final timeAgo = _getTimeAgo(data.timestamp);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        '${data.hr}',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text('${data.hr} BPM'),
                    subtitle: Text(
                      'HRV: ${data.hrv.toStringAsFixed(1)} ms • IBI: ${data.ibiValues.length} • $timeAgo',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          SolarIconsBold.heart,
                          color: colorScheme.primary.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        if (data.ibiValues.isNotEmpty)
                          Icon(
                            SolarIconsBold.pulse,
                            color: colorScheme.secondary.withValues(alpha: 0.5),
                            size: 16,
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
