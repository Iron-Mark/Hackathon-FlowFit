import 'dart:async';
import 'package:logger/logger.dart';
import '../models/tracked_data.dart';
import 'database_service.dart';
import 'supabase_service.dart';

/// Heart Rate Data Manager
/// Manages in-memory buffer, database storage, and data lifecycle
/// Implements best practices from Kotlin implementation
class HeartRateDataManager {
  final DatabaseService _dbService;
  final Logger _logger;
  final int maxBufferSize;
  final int maxDatabaseRecords;
  final IbiHistoryManager _ibiHistory;

  // In-memory buffer for recent data
  final List<TrackedData> _dataBuffer = [];

  // Stream controller for real-time updates
  final _dataStreamController = StreamController<TrackedData>.broadcast();

  // Statistics
  int _totalReceived = 0;
  int _totalSaved = 0;
  DateTime? _lastSaveTime;

  HeartRateDataManager({
    DatabaseService? dbService,
    Logger? logger,
    this.maxBufferSize = 100,
    this.maxDatabaseRecords = 10000,
    int ibiHistorySize = 10,
  }) : _dbService = dbService ?? DatabaseService.instance,
       _logger = logger ?? Logger(),
       _ibiHistory = IbiHistoryManager(maxHistorySize: ibiHistorySize);

  /// Stream of heart rate data updates
  Stream<TrackedData> get dataStream => _dataStreamController.stream;

  /// Get current buffer
  List<TrackedData> get buffer => List.unmodifiable(_dataBuffer);

  /// Get buffer size
  int get bufferSize => _dataBuffer.length;

  /// Get IBI history
  List<int> get ibiHistory => _ibiHistory.history;

  /// Add new heart rate data
  Future<void> addData(TrackedData data) async {
    try {
      _totalReceived++;

      // Update IBI history
      if (data.hasIbiData) {
        _ibiHistory.addIbiValues(data.ibiValues);
        _logger.d(
          'IBI history updated: ${_ibiHistory.size} values, HRV: ${_ibiHistory.calculateHRV().toStringAsFixed(1)}',
        );
      }

      // Add to buffer
      _dataBuffer.add(data);

      // Emit to stream
      _dataStreamController.add(data);

      // Check if buffer needs to be flushed
      if (_dataBuffer.length >= maxBufferSize) {
        await _flushBuffer();
      }

      _logger.d(
        'Data added: $data (buffer: ${_dataBuffer.length}/$maxBufferSize)',
      );
    } catch (e, stackTrace) {
      _logger.e('Error adding data', error: e, stackTrace: stackTrace);
    }
  }

  /// Add multiple data points (batch)
  Future<void> addDataBatch(List<TrackedData> dataList) async {
    try {
      for (final data in dataList) {
        _totalReceived++;

        // Update IBI history
        if (data.hasIbiData) {
          _ibiHistory.addIbiValues(data.ibiValues);
        }

        // Add to buffer
        _dataBuffer.add(data);

        // Emit to stream
        _dataStreamController.add(data);
      }

      // Check if buffer needs to be flushed
      if (_dataBuffer.length >= maxBufferSize) {
        await _flushBuffer();
      }

      _logger.d(
        'Batch added: ${dataList.length} records (buffer: ${_dataBuffer.length}/$maxBufferSize)',
      );
    } catch (e, stackTrace) {
      _logger.e('Error adding batch', error: e, stackTrace: stackTrace);
    }
  }

  /// Flush buffer to database
  Future<void> _flushBuffer() async {
    if (_dataBuffer.isEmpty) return;

    try {
      _logger.i('Flushing buffer: ${_dataBuffer.length} records');

      // Save to database
      await _dbService.insertHeartRateDataBatch(_dataBuffer);

      _totalSaved += _dataBuffer.length;
      _lastSaveTime = DateTime.now();

      // Clear buffer
      _dataBuffer.clear();

      // Check database size and cleanup if needed
      await _checkDatabaseSize();

      _logger.i('Buffer flushed successfully');
    } catch (e, stackTrace) {
      _logger.e('Error flushing buffer', error: e, stackTrace: stackTrace);
    }
  }

  /// Force flush buffer (call before app closes)
  Future<void> forceFlush() async {
    await _flushBuffer();
  }

  /// Check database size and cleanup old data if needed
  Future<void> _checkDatabaseSize() async {
    try {
      final stats = await _dbService.getStatistics();
      final totalRecords = stats['total_records'] as int;

      if (totalRecords > maxDatabaseRecords) {
        _logger.w('Database size exceeded: $totalRecords/$maxDatabaseRecords');

        // Delete oldest synced records
        final deleted = await _dbService.deleteOldData(daysToKeep: 7);

        _logger.i('Cleaned up $deleted old records');
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error checking database size',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get recent data from buffer and database
  Future<List<TrackedData>> getRecentData({int limit = 50}) async {
    try {
      // Combine buffer and database data
      final bufferData = _dataBuffer.reversed.take(limit).toList();

      if (bufferData.length >= limit) {
        return bufferData;
      }

      // Get remaining from database
      final remaining = limit - bufferData.length;
      final dbData = await _dbService.getRecentHeartRateData(limit: remaining);

      return [...bufferData, ...dbData];
    } catch (e, stackTrace) {
      _logger.e('Error getting recent data', error: e, stackTrace: stackTrace);
      return _dataBuffer.reversed.toList();
    }
  }

  /// Get data by date range
  Future<List<TrackedData>> getDataByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get from database
      final dbData = await _dbService.getHeartRateDataByDateRange(
        startDate: startDate,
        endDate: endDate,
      );

      // Add buffer data if in range
      final bufferData = _dataBuffer.where((data) {
        return data.timestamp.isAfter(startDate) &&
            data.timestamp.isBefore(endDate);
      }).toList();

      return [...bufferData, ...dbData];
    } catch (e, stackTrace) {
      _logger.e(
        'Error getting data by date range',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'total_received': _totalReceived,
      'total_saved': _totalSaved,
      'buffer_size': _dataBuffer.length,
      'ibi_history_size': _ibiHistory.size,
      'last_save_time': _lastSaveTime,
      'current_hrv': _ibiHistory.hasEnoughData
          ? _ibiHistory.calculateHRV().toStringAsFixed(1)
          : 'N/A',
    };
  }

  /// Clear all data (buffer and database)
  Future<void> clearAllData() async {
    try {
      _dataBuffer.clear();
      _ibiHistory.clear();
      await _dbService.clearAllData();
      _totalReceived = 0;
      _totalSaved = 0;
      _lastSaveTime = null;
      _logger.i('All data cleared');
    } catch (e, stackTrace) {
      _logger.e('Error clearing data', error: e, stackTrace: stackTrace);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await forceFlush();
    await _dataStreamController.close();
  }
}

/// Data sync manager for uploading to backend
class DataSyncManager {
  final DatabaseService _dbService;
  final Logger _logger;
  final SupabaseService? _supabaseService;
  Timer? _syncTimer;

  DataSyncManager({
    DatabaseService? dbService,
    Logger? logger,
    SupabaseService? supabaseService,
  }) : _dbService = dbService ?? DatabaseService.instance,
       _logger = logger ?? Logger(),
       _supabaseService = supabaseService;

  /// Start periodic sync (every N minutes)
  void startPeriodicSync({Duration interval = const Duration(minutes: 15)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncData());
    _logger.i('Periodic sync started: every ${interval.inMinutes} minutes');
  }

  /// Stop periodic sync
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _logger.i('Periodic sync stopped');
  }

  /// Sync unsynced data to backend
  Future<bool> syncData() async {
    try {
      final unsyncedData = await _dbService.getUnsyncedData();

      if (unsyncedData.isEmpty) {
        _logger.d('No data to sync');
        return true;
      }

      _logger.i('Syncing ${unsyncedData.length} records');

      final supabaseService = _resolveSupabaseService();
      if (supabaseService == null) {
        _logger.w('Supabase is not initialized; keeping data unsynced');
        return false;
      }

      final payload = unsyncedData
          .map(_heartRateRowToSupabasePayload)
          .toList(growable: false);
      await supabaseService.saveHeartRateDataBatch(payload);

      final ids = unsyncedData.map((data) => data['id'] as int).toList();
      await _dbService.markAsSynced(ids);

      _logger.i('Sync completed: ${unsyncedData.length} records');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Error syncing data', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  SupabaseService? _resolveSupabaseService() {
    if (_supabaseService != null) return _supabaseService;
    try {
      return SupabaseService();
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _heartRateRowToSupabasePayload(
    Map<String, dynamic> row,
  ) {
    final ibiValues = _parseIbiValues(row['ibi_values']);
    return {
      'bpm': row['hr'] as int?,
      'timestamp': row['timestamp'] as int,
      'status': row['status'] as String?,
      'ibiValues': ibiValues,
      'ibi_values': ibiValues,
      'raw_data': {
        'local_id': row['id'],
        'hrv': row['hrv'],
        'spo2': row['spo2'],
        'created_at': row['created_at'],
      },
    };
  }

  List<int> _parseIbiValues(Object? value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .map((entry) => entry is int ? entry : int.tryParse('$entry'))
          .whereType<int>()
          .toList();
    }
    final text = value.toString().trim();
    if (text.isEmpty) return const [];
    return text
        .split(',')
        .map((entry) => int.tryParse(entry.trim()))
        .whereType<int>()
        .toList();
  }

  /// Dispose resources
  void dispose() {
    stopPeriodicSync();
  }
}
