import 'dart:math';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/tracked_data.dart';

abstract class HeartRateDataStore {
  Future<void> insertHeartRateDataBatch(List<TrackedData> dataList);

  Future<List<TrackedData>> getRecentHeartRateData({int limit = 50});

  Future<List<TrackedData>> getHeartRateDataByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<Map<String, dynamic>>> getUnsyncedData();

  Future<void> markAsSynced(List<int> ids);

  Future<int> deleteOldData({int daysToKeep = 30});

  Future<Map<String, dynamic>> getStatistics();

  Future<void> clearAllData();
}

/// Volatile fallback store for environments where sqflite cannot initialize.
///
/// Android and iOS still use the persistent sqflite database. This store keeps
/// the phone dashboard functional in widget tests, web-like runtimes, or other
/// platforms where a sqflite database factory is unavailable.
class InMemoryHeartRateDataStore implements HeartRateDataStore {
  final List<Map<String, dynamic>> _rows = [];
  var _nextId = 1;

  Future<int> insertHeartRateData(TrackedData data) async {
    final id = _nextId++;
    _rows.add({
      ...data.toDatabaseMap(),
      'id': id,
      'synced': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return id;
  }

  @override
  Future<void> insertHeartRateDataBatch(List<TrackedData> dataList) async {
    for (final data in dataList) {
      await insertHeartRateData(data);
    }
  }

  @override
  Future<List<TrackedData>> getRecentHeartRateData({int limit = 50}) async {
    final rows = [
      ..._rows,
    ]..sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
    return rows.take(limit).map(TrackedData.fromDatabaseMap).toList();
  }

  @override
  Future<List<TrackedData>> getHeartRateDataByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = startDate.millisecondsSinceEpoch;
    final end = endDate.millisecondsSinceEpoch;
    final rows =
        _rows.where((row) {
          final timestamp = row['timestamp'] as int;
          return timestamp >= start && timestamp <= end;
        }).toList()..sort(
          (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int),
        );
    return rows.map(TrackedData.fromDatabaseMap).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getUnsyncedData() async {
    final rows =
        _rows
            .where((row) => row['synced'] == 0)
            .map((row) => Map<String, dynamic>.from(row))
            .toList()
          ..sort(
            (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int),
          );
    return rows;
  }

  @override
  Future<void> markAsSynced(List<int> ids) async {
    for (final row in _rows) {
      if (ids.contains(row['id'])) {
        row['synced'] = 1;
      }
    }
  }

  @override
  Future<int> deleteOldData({int daysToKeep = 30}) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: daysToKeep))
        .millisecondsSinceEpoch;
    final before = _rows.length;
    _rows.removeWhere(
      (row) => (row['timestamp'] as int) < cutoff && row['synced'] == 1,
    );
    return before - _rows.length;
  }

  @override
  Future<Map<String, dynamic>> getStatistics() async {
    final timestamps = _rows.map((row) => row['timestamp'] as int).toList();
    return {
      'total_records': _rows.length,
      'unsynced_records': _rows.where((row) => row['synced'] == 0).length,
      'oldest_record': timestamps.isEmpty
          ? null
          : DateTime.fromMillisecondsSinceEpoch(timestamps.reduce(min)),
      'newest_record': timestamps.isEmpty
          ? null
          : DateTime.fromMillisecondsSinceEpoch(timestamps.reduce(max)),
    };
  }

  @override
  Future<void> clearAllData() async {
    _rows.clear();
    _nextId = 1;
  }
}

/// Local database service for storing heart rate data
/// Implements best practices for data persistence
class DatabaseService implements HeartRateDataStore {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  final InMemoryHeartRateDataStore _fallbackStore =
      InMemoryHeartRateDataStore();
  var _useFallbackStore = false;

  DatabaseService._init();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('flowfit.db');
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<T> _withStore<T>({
    required Future<T> Function(Database db) persistent,
    required Future<T> Function(InMemoryHeartRateDataStore store) fallback,
  }) async {
    if (_useFallbackStore) {
      return fallback(_fallbackStore);
    }

    try {
      final db = await database;
      return persistent(db);
    } on MissingPluginException {
      _useFallbackStore = true;
      return fallback(_fallbackStore);
    } on UnsupportedError {
      _useFallbackStore = true;
      return fallback(_fallbackStore);
    } on StateError catch (error) {
      if (!_isDatabaseFactoryInitializationError(error)) {
        rethrow;
      }
      _useFallbackStore = true;
      return fallback(_fallbackStore);
    }
  }

  bool _isDatabaseFactoryInitializationError(StateError error) {
    return error.toString().contains('databaseFactory') &&
        error.toString().contains('initialized');
  }

  /// Create database tables
  Future<void> _createDB(Database db, int version) async {
    // Heart rate data table
    await db.execute('''
      CREATE TABLE heart_rate_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hr INTEGER NOT NULL,
        ibi_values TEXT,
        hrv REAL NOT NULL,
        spo2 INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        status TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create index on timestamp for faster queries
    await db.execute('''
      CREATE INDEX idx_timestamp ON heart_rate_data(timestamp DESC)
    ''');

    // Create index on synced status
    await db.execute('''
      CREATE INDEX idx_synced ON heart_rate_data(synced)
    ''');
  }

  /// Insert heart rate data
  Future<int> insertHeartRateData(TrackedData data) async {
    return _withStore(
      persistent: (db) async {
        final map = data.toDatabaseMap();
        map['synced'] = 0; // Mark as not synced
        map['created_at'] = DateTime.now().millisecondsSinceEpoch;

        return db.insert('heart_rate_data', map);
      },
      fallback: (store) => store.insertHeartRateData(data),
    );
  }

  /// Insert multiple heart rate data (batch insert)
  @override
  Future<void> insertHeartRateDataBatch(List<TrackedData> dataList) async {
    await _withStore(
      persistent: (db) async {
        final batch = db.batch();

        for (final data in dataList) {
          final map = data.toDatabaseMap();
          map['synced'] = 0;
          map['created_at'] = DateTime.now().millisecondsSinceEpoch;
          batch.insert('heart_rate_data', map);
        }

        await batch.commit(noResult: true);
      },
      fallback: (store) => store.insertHeartRateDataBatch(dataList),
    );
  }

  /// Get recent heart rate data (last N records)
  @override
  Future<List<TrackedData>> getRecentHeartRateData({int limit = 50}) async {
    return _withStore(
      persistent: (db) async {
        final List<Map<String, dynamic>> maps = await db.query(
          'heart_rate_data',
          orderBy: 'timestamp DESC',
          limit: limit,
        );

        return maps.map((map) => TrackedData.fromDatabaseMap(map)).toList();
      },
      fallback: (store) => store.getRecentHeartRateData(limit: limit),
    );
  }

  /// Get heart rate data by date range
  @override
  Future<List<TrackedData>> getHeartRateDataByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _withStore(
      persistent: (db) async {
        final List<Map<String, dynamic>> maps = await db.query(
          'heart_rate_data',
          where: 'timestamp >= ? AND timestamp <= ?',
          whereArgs: [
            startDate.millisecondsSinceEpoch,
            endDate.millisecondsSinceEpoch,
          ],
          orderBy: 'timestamp DESC',
        );

        return maps.map((map) => TrackedData.fromDatabaseMap(map)).toList();
      },
      fallback: (store) => store.getHeartRateDataByDateRange(
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  /// Get unsynced heart rate data (for uploading to backend)
  @override
  Future<List<Map<String, dynamic>>> getUnsyncedData() async {
    return _withStore(
      persistent: (db) {
        return db.query(
          'heart_rate_data',
          where: 'synced = ?',
          whereArgs: [0],
          orderBy: 'timestamp ASC',
        );
      },
      fallback: (store) => store.getUnsyncedData(),
    );
  }

  /// Mark data as synced
  @override
  Future<void> markAsSynced(List<int> ids) async {
    await _withStore(
      persistent: (db) async {
        final batch = db.batch();

        for (final id in ids) {
          batch.update(
            'heart_rate_data',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [id],
          );
        }

        await batch.commit(noResult: true);
      },
      fallback: (store) => store.markAsSynced(ids),
    );
  }

  /// Delete old data (keep last N days)
  @override
  Future<int> deleteOldData({int daysToKeep = 30}) async {
    return _withStore(
      persistent: (db) {
        final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

        return db.delete(
          'heart_rate_data',
          where: 'timestamp < ? AND synced = ?',
          whereArgs: [cutoffDate.millisecondsSinceEpoch, 1],
        );
      },
      fallback: (store) => store.deleteOldData(daysToKeep: daysToKeep),
    );
  }

  /// Get database statistics
  @override
  Future<Map<String, dynamic>> getStatistics() async {
    return _withStore(
      persistent: (db) async {
        // Total records
        final totalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM heart_rate_data',
        );
        final total = totalResult.first['count'] as int;

        // Unsynced records
        final unsyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM heart_rate_data WHERE synced = 0',
        );
        final unsynced = unsyncedResult.first['count'] as int;

        // Date range
        final rangeResult = await db.rawQuery(
          'SELECT MIN(timestamp) as min, MAX(timestamp) as max FROM heart_rate_data',
        );
        final minTimestamp = rangeResult.first['min'] as int?;
        final maxTimestamp = rangeResult.first['max'] as int?;

        return {
          'total_records': total,
          'unsynced_records': unsynced,
          'oldest_record': minTimestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(minTimestamp)
              : null,
          'newest_record': maxTimestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(maxTimestamp)
              : null,
        };
      },
      fallback: (store) => store.getStatistics(),
    );
  }

  /// Clear all data (use with caution)
  @override
  Future<void> clearAllData() async {
    await _withStore(
      persistent: (db) async {
        await db.delete('heart_rate_data');
      },
      fallback: (store) => store.clearAllData(),
    );
  }

  /// Close database
  Future<void> close() async {
    if (_useFallbackStore) {
      await _fallbackStore.clearAllData();
      _useFallbackStore = false;
      return;
    }

    if (_database == null) return;
    final db = await database;
    await db.close();
    _database = null;
  }
}
