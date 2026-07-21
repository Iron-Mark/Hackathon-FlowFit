import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/core/exceptions/profile_exceptions.dart';
import 'package:flowfit/core/utils/logger.dart';

/// Represents a queued sync operation
class SyncQueueItem {
  final String userId;
  final UserProfile profile;
  final DateTime queuedAt;
  final int retryCount;
  final DateTime? nextRetryAt;

  const SyncQueueItem({
    required this.userId,
    required this.profile,
    required this.queuedAt,
    this.retryCount = 0,
    this.nextRetryAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'profile': profile.toJson(),
      'queuedAt': queuedAt.toIso8601String(),
      'retryCount': retryCount,
      'nextRetryAt': nextRetryAt?.toIso8601String(),
    };
  }

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      userId: json['userId'] as String,
      profile: UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      nextRetryAt: json['nextRetryAt'] != null
          ? DateTime.parse(json['nextRetryAt'] as String)
          : null,
    );
  }

  SyncQueueItem copyWith({
    String? userId,
    UserProfile? profile,
    DateTime? queuedAt,
    int? retryCount,
    DateTime? nextRetryAt,
  }) {
    return SyncQueueItem(
      userId: userId ?? this.userId,
      profile: profile ?? this.profile,
      queuedAt: queuedAt ?? this.queuedAt,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    );
  }
}

/// Service for managing offline sync queue with exponential backoff
///
/// Handles queuing profile updates when offline and automatically
/// syncing when connectivity is restored.
class SyncQueueService {
  final SharedPreferences _prefs;
  final ProfileRepository _profileRepository;
  final Logger _logger = Logger('SyncQueueService');

  // Storage key for sync queue
  static const String _queueKey = 'sync_queue';

  // Storage key for items parked after exhausting their retries
  static const String _deadLetterKey = 'sync_queue_dead_letter';

  // Retry configuration
  static const int _maxRetries = 5;
  static const Duration _initialBackoff = Duration(seconds: 5);
  static const int _backoffMultiplier = 2;

  // Connectivity monitoring
  Timer? _connectivityTimer;
  Timer? _retryTimer;
  bool _isProcessing = false;
  bool _isRestoringDeadLetters = false;

  // Stream controller for queue status
  final _queueStatusController = StreamController<int>.broadcast();

  SyncQueueService({
    required SharedPreferences prefs,
    required ProfileRepository profileRepository,
  }) : _prefs = prefs,
       _profileRepository = profileRepository {
    _logger.info('SyncQueueService initialized');
    _startConnectivityMonitoring();
    _startRetryTimer();

    // Give parked dead-letter items a chance to re-enter the queue on startup
    unawaited(_restoreDeadLetters());
  }

  /// Get stream of pending queue count
  Stream<int> get queueStatus => _queueStatusController.stream;

  /// Add profile update to sync queue
  Future<void> enqueue(UserProfile profile) async {
    try {
      _logger.debug('Enqueueing profile for user: ${profile.userId}');
      final queue = await _loadQueue();

      // Check if user already has a queued item
      final existingIndex = queue.indexWhere(
        (item) => item.userId == profile.userId,
      );

      final queueItem = SyncQueueItem(
        userId: profile.userId,
        profile: profile,
        queuedAt: DateTime.now(),
      );

      if (existingIndex >= 0) {
        // Update existing item
        _logger.debug(
          'Updating existing queue item for user: ${profile.userId}',
        );
        queue[existingIndex] = queueItem;
      } else {
        // Add new item
        _logger.debug('Adding new queue item for user: ${profile.userId}');
        queue.add(queueItem);
      }

      await _saveQueue(queue);
      _queueStatusController.add(queue.length);
      _logger.info('Profile queued for sync (queue size: ${queue.length})');

      // Try to process immediately
      unawaited(_processQueue());
    } catch (e, stackTrace) {
      // Log error but don't throw - queue operation should be resilient
      _logger.error(
        'Error enqueueing profile for user: ${profile.userId}',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get count of pending items in queue
  Future<int> getPendingCount() async {
    try {
      final queue = await _loadQueue();
      return queue.length;
    } catch (e) {
      return 0;
    }
  }

  /// Check if user has pending sync
  Future<bool> hasPendingSync(String userId) async {
    try {
      final queue = await _loadQueue();
      return queue.any((item) => item.userId == userId);
    } catch (e) {
      return false;
    }
  }

  /// Manually trigger sync processing
  Future<void> processPendingSync() async {
    await _processQueue();
  }

  /// Manually trigger sync and return connectivity status
  ///
  /// Returns true if sync was attempted (has connectivity), false otherwise.
  /// Useful for pull-to-refresh or manual sync buttons.
  Future<bool> manualSync() async {
    final hasConnectivity = await _hasConnectivity();
    if (hasConnectivity) {
      await _processQueue();
    }
    return hasConnectivity;
  }

  /// Clear all queued items (use with caution)
  Future<void> clearQueue() async {
    await _prefs.remove(_queueKey);
    _queueStatusController.add(0);
  }

  /// Purge a deleted user's parked payload from the shared dead-letter store.
  ///
  /// Static on purpose: constructing a real [SyncQueueService] would start its
  /// timers and kick off a restore pass that could re-enqueue the very payload
  /// we are trying to purge. A corrupted store is dropped entirely so a deleted
  /// user's payload can never survive.
  static Future<void> clearDeadLetterForUser(
    SharedPreferences prefs,
    String userId,
  ) async {
    final jsonString = prefs.getString(_deadLetterKey);
    if (jsonString == null) {
      return;
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final remaining = jsonList
          .map((json) => SyncQueueItem.fromJson(json as Map<String, dynamic>))
          .where((item) => item.userId != userId)
          .toList();

      if (remaining.isEmpty) {
        await prefs.remove(_deadLetterKey);
      } else {
        await prefs.setString(
          _deadLetterKey,
          jsonEncode(remaining.map((item) => item.toJson()).toList()),
        );
      }
    } catch (_) {
      await prefs.remove(_deadLetterKey);
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivityTimer?.cancel();
    _retryTimer?.cancel();
    _queueStatusController.close();
  }

  // ============================================================================
  // Private Methods
  // ============================================================================

  /// Load queue from local storage
  Future<List<SyncQueueItem>> _loadQueue() async {
    try {
      final jsonString = _prefs.getString(_queueKey);
      if (jsonString == null) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final queue = jsonList
          .map((json) => SyncQueueItem.fromJson(json as Map<String, dynamic>))
          .toList();

      _logger.debug('Loaded ${queue.length} items from sync queue');
      return queue;
    } on FormatException catch (e, stackTrace) {
      _logger.error(
        'Invalid JSON format in sync queue, clearing queue',
        error: e,
        stackTrace: stackTrace,
      );
      // Clear corrupted queue
      await _prefs.remove(_queueKey);
      return [];
    } catch (e, stackTrace) {
      _logger.error(
        'Error loading sync queue, returning empty queue',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Save queue to local storage
  Future<void> _saveQueue(List<SyncQueueItem> queue) async {
    try {
      final jsonList = queue.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      final success = await _prefs.setString(_queueKey, jsonString);

      if (!success) {
        _logger.error('Failed to save sync queue to SharedPreferences');
      } else {
        _logger.debug('Saved ${queue.length} items to sync queue');
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error saving sync queue',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Park an item that exhausted its retries in the dead-letter store
  ///
  /// Replace-by-userId semantics: one parked payload per user, matching the
  /// main queue's contract.
  Future<void> _parkInDeadLetter(SyncQueueItem item) async {
    final deadLetters = await _loadDeadLetters();

    final existingIndex = deadLetters.indexWhere(
      (parked) => parked.userId == item.userId,
    );

    if (existingIndex >= 0) {
      deadLetters[existingIndex] = item;
    } else {
      deadLetters.add(item);
    }

    await _saveDeadLetters(deadLetters);
  }

  /// Load dead-letter store from local storage
  Future<List<SyncQueueItem>> _loadDeadLetters() async {
    final jsonString = _prefs.getString(_deadLetterKey);
    if (jsonString == null) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => SyncQueueItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      _logger.error(
        'Corrupted dead-letter store, clearing key',
        error: e,
        stackTrace: stackTrace,
      );
      // If parsing fails, clear corrupted data
      await _prefs.remove(_deadLetterKey);
      return [];
    }
  }

  /// Save dead-letter store to local storage
  ///
  /// Removes the key entirely when the store is empty so the restore pass
  /// stays a cheap no-op.
  Future<void> _saveDeadLetters(List<SyncQueueItem> deadLetters) async {
    try {
      if (deadLetters.isEmpty) {
        await _prefs.remove(_deadLetterKey);
        return;
      }

      final jsonList = deadLetters.map((item) => item.toJson()).toList();
      await _prefs.setString(_deadLetterKey, jsonEncode(jsonList));
    } catch (e, stackTrace) {
      _logger.error(
        'Error saving dead-letter store',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Restore parked dead-letter items back into the main queue
  ///
  /// Runs at startup and whenever connectivity is confirmed. For each parked
  /// item the backend copy is checked first: if it changed after the item was
  /// queued, replaying would clobber newer edits, so the item is dropped
  /// permanently (mirrors the buddy onboarding stale-replay guard). Items
  /// that cannot be checked because the backend is unreachable stay parked
  /// for the next cycle.
  Future<void> _restoreDeadLetters() async {
    // Prevent concurrent restore passes
    if (_isRestoringDeadLetters) {
      return;
    }

    // Cheap no-op when nothing is parked
    if (!_prefs.containsKey(_deadLetterKey)) {
      return;
    }

    _isRestoringDeadLetters = true;

    try {
      final deadLetters = await _loadDeadLetters();
      if (deadLetters.isEmpty) {
        return;
      }

      final queue = await _loadQueue();
      final stillParked = <SyncQueueItem>[];
      int restoredCount = 0;

      for (final parked in deadLetters) {
        // Stale guard first: a backend row updated after this payload was
        // queued means the backend already holds newer data - drop the item.
        try {
          final backend = await _profileRepository.getBackendProfile(
            parked.userId,
          );
          if (backend != null && backend.updatedAt.isAfter(parked.queuedAt)) {
            _logger.info(
              'Dropping dead-letter item for user ${parked.userId}: backend copy is newer',
            );
            continue;
          }
        } on BackendSyncException {
          // Backend unreachable - keep parked for the next cycle
          stillParked.add(parked);
          continue;
        }

        // A queued item for this user is necessarily fresher than the parked
        // one, so the parked payload is dropped in its favor.
        final alreadyQueued = queue.any((item) => item.userId == parked.userId);
        if (alreadyQueued) {
          continue;
        }

        // Re-enqueue with a fresh retry budget and no pending backoff
        queue.add(
          SyncQueueItem(
            userId: parked.userId,
            profile: parked.profile,
            queuedAt: parked.queuedAt,
          ),
        );
        restoredCount++;
      }

      await _saveQueue(queue);
      await _saveDeadLetters(stillParked);
      _queueStatusController.add(queue.length);

      if (restoredCount > 0) {
        _logger.info(
          'Restored $restoredCount dead-letter item(s) into the sync queue',
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error restoring dead-letter items',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isRestoringDeadLetters = false;
    }
  }

  /// Start monitoring connectivity
  void _startConnectivityMonitoring() {
    // Check connectivity every 30 seconds
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivityAndProcess(),
    );
  }

  /// Start retry timer for failed items
  void _startRetryTimer() {
    // Check for items ready to retry every 10 seconds
    _retryTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _processQueue(),
    );
  }

  /// Check connectivity and process queue if online
  Future<void> _checkConnectivityAndProcess() async {
    if (await _hasConnectivity()) {
      await _restoreDeadLetters();
      await _processQueue();
    }
  }

  /// Check if device has internet connectivity
  Future<bool> _hasConnectivity() async {
    try {
      // Try to lookup a reliable host
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      final hasConnection =
          result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _logger.debug(
        'Connectivity check: ${hasConnection ? "online" : "offline"}',
      );
      return hasConnection;
    } on SocketException catch (e) {
      _logger.debug('No connectivity: ${e.message}');
      return false;
    } on TimeoutException {
      _logger.debug('Connectivity check timed out');
      return false;
    } catch (e) {
      _logger.debug('Connectivity check failed', error: e);
      return false;
    }
  }

  /// Process sync queue
  Future<void> _processQueue() async {
    // Prevent concurrent processing
    if (_isProcessing) {
      _logger.debug('Queue processing already in progress, skipping');
      return;
    }

    _isProcessing = true;

    try {
      // Check connectivity first
      if (!await _hasConnectivity()) {
        _logger.debug('No connectivity, skipping queue processing');
        return;
      }

      final queue = await _loadQueue();
      if (queue.isEmpty) {
        _logger.debug('Queue is empty, nothing to process');
        return;
      }

      _logger.info('Processing sync queue with ${queue.length} items');

      final now = DateTime.now();
      final itemsToProcess = <SyncQueueItem>[];
      final itemsToKeep = <SyncQueueItem>[];

      // Separate items ready to process from those waiting for retry
      for (final item in queue) {
        if (item.nextRetryAt == null || now.isAfter(item.nextRetryAt!)) {
          itemsToProcess.add(item);
        } else {
          itemsToKeep.add(item);
        }
      }

      _logger.debug(
        '${itemsToProcess.length} items ready to process, ${itemsToKeep.length} waiting for retry',
      );

      // Process each item
      int successCount = 0;
      int failureCount = 0;

      for (final item in itemsToProcess) {
        final success = await _syncItem(item);

        if (!success) {
          failureCount++;
          // Add back to queue with retry logic
          if (item.retryCount < _maxRetries) {
            final backoffDuration = _calculateBackoff(item.retryCount);
            final updatedItem = item.copyWith(
              retryCount: item.retryCount + 1,
              nextRetryAt: now.add(backoffDuration),
            );
            itemsToKeep.add(updatedItem);
            _logger.debug(
              'Retry ${item.retryCount + 1}/$_maxRetries scheduled for user ${item.userId} in ${backoffDuration.inSeconds}s',
            );
          } else {
            // Max retries reached - park for a later restore pass
            await _parkInDeadLetter(item);
            _logger.error(
              'Max retries ($_maxRetries) reached for user ${item.userId}, parking item in dead-letter store',
            );
          }
        } else {
          successCount++;
        }
        // If successful, item is not added back to queue
      }

      // Save updated queue
      await _saveQueue(itemsToKeep);
      _queueStatusController.add(itemsToKeep.length);

      _logger.info(
        'Queue processing complete: $successCount succeeded, $failureCount failed, ${itemsToKeep.length} remaining',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error processing sync queue',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Sync a single queue item
  Future<bool> _syncItem(SyncQueueItem item) async {
    try {
      _logger.debug('Syncing profile for user: ${item.userId}');
      await _profileRepository.saveBackendProfile(item.profile);

      // Update local profile to mark as synced
      final syncedProfile = item.profile.copyWith(isSynced: true);
      await _profileRepository.saveLocalProfile(syncedProfile);

      _logger.info('Successfully synced profile for user: ${item.userId}');
      return true;
    } on BackendSyncException catch (e, stackTrace) {
      _logger.warning(
        'Backend sync failed for user: ${item.userId}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    } on LocalStorageException catch (e, stackTrace) {
      _logger.error(
        'Failed to update local profile after sync for user: ${item.userId}',
        error: e,
        stackTrace: stackTrace,
      );
      // Consider this a success since backend sync worked
      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Unexpected error syncing profile for user: ${item.userId}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Calculate exponential backoff duration
  Duration _calculateBackoff(int retryCount) {
    if (retryCount == 0) {
      return Duration.zero;
    }
    final seconds =
        (_initialBackoff.inSeconds * pow(_backoffMultiplier, retryCount - 1))
            .toInt();
    return Duration(seconds: seconds);
  }
}
