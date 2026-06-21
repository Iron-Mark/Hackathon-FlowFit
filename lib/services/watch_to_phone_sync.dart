import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../models/heart_rate_data.dart';
import 'dart:convert';

/// Service for syncing heart rate data from watch to phone
/// Uses Wearable Data Layer API (MessageClient)
class WatchToPhoneSync {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.flowfit.watch/sync',
  );

  final Logger _logger = Logger();

  /// Send a single heart rate reading to the phone
  Future<bool> sendHeartRateToPhone(HeartRateData data) async {
    try {
      _logger.i('Sending heart rate to phone: ${data.bpm} BPM');

      // Convert to JSON
      final jsonData = jsonEncode(data.toJson());

      // Send via method channel
      final result = await _methodChannel.invokeMethod<bool>(
        'sendHeartRateToPhone',
        {'data': jsonData},
      );

      final success = result ?? false;
      _logger.i('Send result: $success');
      return success;
    } on PlatformException catch (e) {
      _logger.e('Failed to send heart rate', error: e);
      return false;
    } catch (e) {
      _logger.e('Unexpected error sending heart rate', error: e);
      return false;
    }
  }

  /// Send multiple heart rate readings in batch
  Future<bool> sendBatchData(List<HeartRateData> dataList) async {
    try {
      _logger.i('Sending batch of ${dataList.length} readings to phone');

      // Convert list to JSON
      final jsonList = dataList.map((d) => d.toJson()).toList();
      final jsonData = jsonEncode(jsonList);

      // Send via method channel
      final result = await _methodChannel.invokeMethod<bool>(
        'sendBatchToPhone',
        {'data': jsonData},
      );

      final success = result ?? false;
      _logger.i('Batch send result: $success');
      return success;
    } on PlatformException catch (e) {
      _logger.e('Failed to send batch', error: e);
      return false;
    } catch (e) {
      _logger.e('Unexpected error sending batch', error: e);
      return false;
    }
  }

  /// Check if phone is connected and reachable
  Future<bool> checkPhoneConnection() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'checkPhoneConnection',
      );
      final connected = result ?? false;
      _logger.d('Phone connection status: $connected');
      return connected;
    } on PlatformException catch (e) {
      _logger.e('Failed to check phone connection', error: e);
      return false;
    }
  }

  /// Get the number of connected nodes (phones)
  Future<int> getConnectedNodesCount() async {
    try {
      final result = await _methodChannel.invokeMethod<int>(
        'getConnectedNodesCount',
      );
      return result ?? 0;
    } on PlatformException catch (e) {
      _logger.e('Failed to get connected nodes count', error: e);
      return 0;
    }
  }
}
