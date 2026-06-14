import 'dart:async';
import 'package:flutter/services.dart';
import '../models/heart_rate_data.dart';
import '../models/sensor_batch.dart';
import '../models/sensor_error.dart';
import '../models/sensor_error_code.dart';
import 'package:logger/logger.dart';

/// Service for receiving heart rate data from Galaxy Watch
/// Uses Wearable Data Layer API to listen for messages from watch
///
/// This service listens to the EventChannel "com.flowfit.phone/heartrate"
/// which receives data from PhoneDataListenerService on the native Android side.
/// The data is transmitted from the watch via Wearable Data Layer API.
///
/// Singleton: all parts of the app share one instance so only one subscriber
/// holds the native EventChannel event sink at a time.
class PhoneDataListener {
  static final PhoneDataListener _instance = PhoneDataListener._internal();
  factory PhoneDataListener() => _instance;
  PhoneDataListener._internal();

  static const MethodChannel _methodChannel = MethodChannel(
    'com.flowfit.phone/data',
  );
  static const EventChannel _heartRateEventChannel = EventChannel(
    'com.flowfit.phone/heartrate',
  );
  static const EventChannel _sensorBatchEventChannel = EventChannel(
    'com.flowfit.phone/sensor_data',
  );

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  Stream<HeartRateData>? _heartRateStream;
  StreamController<HeartRateData>? _heartRateController;
  Stream<SensorBatch>? _sensorBatchStream;
  StreamController<SensorBatch>? _sensorBatchController;

  /// Get stream of heart rate data from watch
  ///
  /// This stream receives heart rate data sent from the Galaxy Watch
  /// via the Wearable Data Layer API. The data is decoded from JSON
  /// and validated before being emitted.
  ///
  /// Requirements: 8.2, 9.4
  Stream<HeartRateData> get heartRateStream {
    _heartRateStream ??= _heartRateEventChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
          try {
            // Validate that event is a Map
            if (event == null) {
              _logger.e('Received null event from heart rate stream');
              throw SensorError(
                code: SensorErrorCode.unknown,
                message: 'Received null data from watch',
                details: 'Event channel emitted null value',
              );
            }

            if (event is! Map) {
              _logger.e('Received non-Map event: ${event.runtimeType}');
              throw SensorError(
                code: SensorErrorCode.unknown,
                message: 'Invalid data format from watch',
                details: 'Expected Map but got ${event.runtimeType}',
              );
            }

            // Convert to Map<String, dynamic>
            final jsonMap = Map<String, dynamic>.from(event);

            // Validate required fields (Requirements 9.4)
            _validateRequiredFields(jsonMap);

            // Parse heart rate data
            final heartRateData = HeartRateData.fromJson(jsonMap);

            _logger.d(
              'Received heart rate from watch: ${heartRateData.bpm} bpm, '
              'status: ${heartRateData.status.name}, '
              'ibiCount: ${heartRateData.ibiValues.length}',
            );

            return heartRateData;
          } on SensorError {
            // Re-throw SensorError as-is
            rethrow;
          } catch (e, stackTrace) {
            _logger.e(
              'Failed to parse heart rate data from watch',
              error: e,
              stackTrace: stackTrace,
            );
            throw SensorError(
              code: SensorErrorCode.unknown,
              message: 'Failed to decode heart rate data from watch',
              details: 'JSON parsing error: ${e.toString()}',
            );
          }
        })
        .handleError((error, stackTrace) {
          _logger.e(
            'Error in heart rate stream from watch',
            error: error,
            stackTrace: stackTrace,
          );

          // Convert platform exceptions to SensorError
          if (error is PlatformException) {
            throw SensorError(
              code: SensorErrorCode.unknown,
              message: 'Platform error in heart rate stream',
              details: '${error.code}: ${error.message}',
            );
          }

          // Re-throw if already a SensorError
          if (error is SensorError) {
            throw error;
          }

          // Wrap other errors
          throw SensorError(
            code: SensorErrorCode.unknown,
            message: 'Unexpected error in heart rate stream',
            details: error.toString(),
          );
        });

    return _heartRateStream!;
  }

  /// Get stream of sensor batches from watch
  ///
  /// This stream receives combined sensor data (accelerometer + heart rate)
  /// sent from the Galaxy Watch via the Wearable Data Layer API.
  /// Each batch contains 32 samples with 4-feature vectors [accX, accY, accZ, bpm].
  ///
  /// Requirements: 2.4, 2.5
  Stream<SensorBatch> get sensorBatchStream {
    _sensorBatchStream ??= _sensorBatchEventChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
          try {
            // Validate that event is a Map
            if (event == null) {
              // Log parsing error (Requirements 8.3)
              _logger.e('❌ Received null event from sensor batch stream');
              throw SensorError(
                code: SensorErrorCode.unknown,
                message: 'Received null data from watch',
                details: 'Event channel emitted null value',
              );
            }

            if (event is! Map) {
              // Log parsing error with raw data (Requirements 8.3)
              _logger.e(
                '❌ Received non-Map event: ${event.runtimeType}, '
                'raw_data: $event',
              );
              throw SensorError(
                code: SensorErrorCode.unknown,
                message: 'Invalid data format from watch',
                details: 'Expected Map but got ${event.runtimeType}',
              );
            }

            // Convert to Map<String, dynamic>
            final jsonMap = Map<String, dynamic>.from(event);

            // Parse and validate sensor batch (Requirements 2.4)
            final sensorBatch = _handleSensorBatch(jsonMap);

            // Feature vectors are already constructed in SensorBatch.fromJson (Requirements 2.5)
            _logger.d(
              '✅ Successfully processed sensor batch: '
              'feature_vectors=${sensorBatch.sampleCount}',
            );

            return sensorBatch;
          } on SensorError {
            // Re-throw SensorError as-is (already logged)
            rethrow;
          } catch (e, stackTrace) {
            // Log parsing error with raw data (Requirements 8.3)
            _logger.e(
              '❌ Failed to parse sensor batch from watch: '
              'error=${e.runtimeType}: $e, '
              'raw_event: $event',
              error: e,
              stackTrace: stackTrace,
            );
            throw SensorError(
              code: SensorErrorCode.unknown,
              message: 'Failed to decode sensor batch from watch',
              details: 'JSON parsing error: ${e.toString()}',
            );
          }
        })
        .handleError((error, stackTrace) {
          // Log parsing error (Requirements 8.3)
          _logger.e(
            '❌ Error in sensor batch stream from watch: '
            'error=${error.runtimeType}: $error',
            error: error,
            stackTrace: stackTrace,
          );

          // Convert platform exceptions to SensorError
          if (error is PlatformException) {
            throw SensorError(
              code: SensorErrorCode.unknown,
              message: 'Platform error in sensor batch stream',
              details: '${error.code}: ${error.message}',
            );
          }

          // Re-throw if already a SensorError
          if (error is SensorError) {
            throw error;
          }

          // Wrap other errors
          throw SensorError(
            code: SensorErrorCode.unknown,
            message: 'Unexpected error in sensor batch stream',
            details: error.toString(),
          );
        });

    return _sensorBatchStream!;
  }

  /// Validate that all required fields are present in the JSON data
  ///
  /// According to Requirements 9.4, the JSON must contain:
  /// - bpm (can be null)
  /// - ibiValues (array)
  /// - timestamp (integer)
  /// - status (string)
  void _validateRequiredFields(Map<String, dynamic> json) {
    final requiredFields = ['timestamp', 'status'];
    final missingFields = <String>[];

    for (final field in requiredFields) {
      if (!json.containsKey(field)) {
        missingFields.add(field);
      }
    }

    if (missingFields.isNotEmpty) {
      final message = 'Missing required fields: ${missingFields.join(", ")}';
      _logger.e('JSON validation failed: $message');
      _logger.d('Received JSON: $json');

      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Malformed JSON from watch',
        details: message,
      );
    }

    // Validate field types
    if (json['timestamp'] is! int) {
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Invalid timestamp field type',
        details: 'Expected int but got ${json['timestamp'].runtimeType}',
      );
    }

    if (json['status'] is! String) {
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Invalid status field type',
        details: 'Expected String but got ${json['status'].runtimeType}',
      );
    }

    // Validate optional fields if present
    if (json.containsKey('bpm') && json['bpm'] != null && json['bpm'] is! int) {
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Invalid bpm field type',
        details: 'Expected int or null but got ${json['bpm'].runtimeType}',
      );
    }

    if (json.containsKey('ibiValues') &&
        json['ibiValues'] != null &&
        json['ibiValues'] is! List) {
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Invalid ibiValues field type',
        details: 'Expected List but got ${json['ibiValues'].runtimeType}',
      );
    }
  }

  /// Start listening for data from watch
  Future<bool> startListening() async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    try {
      _logger.i('🎧 Starting to listen for watch data at $startTime');
      final result = await _methodChannel.invokeMethod<bool>('startListening');
      final success = result ?? false;
      if (success) {
        _logger.i('✅ Listening started successfully');
      } else {
        _logger.w('⚠️ Listening failed to start');
      }
      return success;
    } on PlatformException catch (e) {
      // Log parsing error (Requirements 8.3)
      _logger.e(
        '❌ Failed to start listening: '
        'code=${e.code}, message=${e.message}',
        error: e,
      );
      return false;
    }
  }

  /// Stop listening for data from watch
  Future<void> stopListening() async {
    final stopTime = DateTime.now().millisecondsSinceEpoch;
    try {
      _logger.i('🛑 Stopping listening for watch data at $stopTime');
      await _methodChannel.invokeMethod<void>('stopListening');
      _logger.i('✅ Listening stopped successfully');
    } on PlatformException catch (e) {
      // Log parsing error (Requirements 8.3)
      _logger.e(
        '❌ Failed to stop listening: '
        'code=${e.code}, message=${e.message}',
        error: e,
      );
    }
  }

  /// Check if watch is connected
  Future<bool> isWatchConnected() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'isWatchConnected',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _logger.e('Failed to check watch connection', error: e);
      return false;
    }
  }

  /// Validate that all required fields are present in sensor batch JSON
  ///
  /// According to Requirements 2.4, the JSON must contain:
  /// - type (string)
  /// - timestamp (integer)
  /// - bpm (integer)
  /// - sampleRate or sample_rate (integer)
  /// - count (integer)
  /// - accelerometer (array)
  void _validateSensorBatchFields(Map<String, dynamic> json) {
    final requiredFields = [
      'type',
      'timestamp',
      'bpm',
      'count',
      'accelerometer',
    ];
    final missingFields = <String>[];

    for (final field in requiredFields) {
      if (!json.containsKey(field)) {
        missingFields.add(field);
      }
    }

    // Check for sample_rate (snake_case) or sampleRate (camelCase)
    if (!json.containsKey('sample_rate') && !json.containsKey('sampleRate')) {
      missingFields.add('sample_rate/sampleRate');
    }

    if (missingFields.isNotEmpty) {
      final message = 'Missing required fields: ${missingFields.join(", ")}';
      // Log parsing error with raw data (Requirements 8.3)
      _logger.e('❌ Sensor batch JSON validation FAILED: $message');
      _logger.d('Raw JSON: $json');

      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Malformed sensor batch JSON from watch',
        details: message,
      );
    }

    // Validate field types
    if (json['type'] is! String) {
      // Log parsing error (Requirements 8.3)
      _logger.e(
        '❌ Invalid type field: expected String but got ${json['type'].runtimeType}',
      );
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Invalid type field type',
        details: 'Expected String but got ${json['type'].runtimeType}',
      );
    }

    if (json['timestamp'] is! int) {
      // Log parsing error (Requirements 8.3)
      _logger.e(
        '❌ Invalid timestamp field: expected int but got ${json['timestamp'].runtimeType}',
      );
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Invalid timestamp field type',
        details: 'Expected int but got ${json['timestamp'].runtimeType}',
      );
    }

    if (json['bpm'] is! int) {
      // Log parsing error (Requirements 8.3)
      _logger.e(
        '❌ Invalid bpm field: expected int but got ${json['bpm'].runtimeType}',
      );
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Invalid bpm field type',
        details: 'Expected int but got ${json['bpm'].runtimeType}',
      );
    }

    // Validate sample_rate or sampleRate (accept both formats)
    final sampleRate = json['sample_rate'] ?? json['sampleRate'];
    if (sampleRate is! int) {
      // Log parsing error (Requirements 8.3)
      _logger.e(
        '❌ Invalid sample_rate/sampleRate field: expected int but got ${sampleRate.runtimeType}',
      );
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Invalid sample_rate field type',
        details: 'Expected int but got ${sampleRate.runtimeType}',
      );
    }

    if (json['count'] is! int) {
      // Log parsing error (Requirements 8.3)
      _logger.e(
        '❌ Invalid count field: expected int but got ${json['count'].runtimeType}',
      );
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Invalid count field type',
        details: 'Expected int but got ${json['count'].runtimeType}',
      );
    }

    if (json['accelerometer'] is! List) {
      // Log parsing error (Requirements 8.3)
      _logger.e(
        '❌ Invalid accelerometer field: expected List but got ${json['accelerometer'].runtimeType}',
      );
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Invalid accelerometer field type',
        details: 'Expected List but got ${json['accelerometer'].runtimeType}',
      );
    }

    // Validate count matches accelerometer array length
    final accelData = json['accelerometer'] as List;
    final count = json['count'] as int;
    if (accelData.length != count) {
      // Log parsing error (Requirements 8.3)
      _logger.e(
        '❌ Count mismatch: count=$count but accelerometer array has ${accelData.length} elements',
      );
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Count mismatch in sensor batch',
        details:
            'count field is $count but accelerometer array has ${accelData.length} elements',
      );
    }
  }

  /// Handle incoming sensor batch from watch
  ///
  /// Parses JSON, validates required fields, and extracts sensor data.
  /// Requirements: 2.4
  SensorBatch _handleSensorBatch(Map<String, dynamic> json) {
    final receiveTime = DateTime.now().millisecondsSinceEpoch;

    try {
      // Validate all required fields are present
      _validateSensorBatchFields(json);

      // Extract fields (handle both snake_case and camelCase)
      final bpm = json['bpm'] as int;
      final timestamp = json['timestamp'] as int;
      final count = json['count'] as int;
      final sampleRate = (json['sample_rate'] ?? json['sampleRate']) as int;

      // Log received sensor batch with sample count and heart rate (Requirements 8.3)
      _logger.i(
        '📥 Sensor batch RECEIVED at $receiveTime: '
        'samples=$count, '
        'bpm=$bpm, '
        'sample_rate=${sampleRate}Hz, '
        'watch_timestamp=$timestamp, '
        'latency=${receiveTime - timestamp}ms',
      );

      // Parse into SensorBatch model
      final sensorBatch = SensorBatch.fromJson(json);

      // Log feature vector construction details
      _logger.d(
        '🔧 Feature vectors constructed: '
        'count=${sensorBatch.sampleCount}, '
        'features_per_sample=4 [accX, accY, accZ, bpm]',
      );

      return sensorBatch;
    } catch (e, stackTrace) {
      // Log parsing errors with raw data (Requirements 8.3)
      _logger.e(
        '❌ PARSING ERROR in sensor batch at $receiveTime: '
        'error=${e.runtimeType}: $e',
        error: e,
        stackTrace: stackTrace,
      );
      _logger.d('Raw JSON data: $json');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _heartRateController?.close();
    _heartRateController = null;
    _heartRateStream = null;
    _sensorBatchController?.close();
    _sensorBatchController = null;
    _sensorBatchStream = null;
  }
}
