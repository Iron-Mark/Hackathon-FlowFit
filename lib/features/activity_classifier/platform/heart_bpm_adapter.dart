import 'dart:async';
import 'package:logger/logger.dart';

// Attempt to import the heart_bpm plugin.
// If the plugin API changes, update the usage here.
// This adapter accepts an optional external stream for BPM values (e.g., from
// the `heart_bpm` plugin or a watch bridge). We avoid referencing plugin APIs
// directly here to keep the adapter stable and testable.

/// Adapter for heart_bpm plugin (or fallback behavior).
/// Exposes a stream of bpm values (int) and a current value getter.
class HeartBpmAdapter {
  final Logger _logger = Logger();
  StreamSubscription<int>? _subscription;
  final StreamController<int?> _bpmController =
      StreamController<int?>.broadcast();

  int? _currentBpm;

  int? get currentBpm => _currentBpm;
  Stream<int?> get bpmStream => _bpmController.stream;
  bool get hasExternalConnection => _subscription != null;

  HeartBpmAdapter();

  /// Connect an external BPM stream (e.g., provided by a plugin or native bridge)
  /// Passing `null` removes the external subscription.
  void connectExternalStream(Stream<int>? external) {
    _subscription?.cancel();
    _subscription = null;

    if (external != null) {
      _subscription = external.listen(
        (bpm) {
          _currentBpm = bpm;
          _bpmController.add(bpm);
          _logger.d('HeartBpmAdapter: BPM update $bpm (external)');
        },
        onError: (e) {
          _logger.w('HeartBpmAdapter: external stream error', error: e);
        },
      );
    }
  }

  /// Attempt to connect to `heart_bpm` plugin stream. Returns true if connected.
  // Plugin connection is app-managed. Call `connectExternalStream(pluginStream)`
  // from `main.dart` or other initialization code if a plugin stream is available.

  /// Manual injection of a BPM value (e.g., for testing or when simulation is used)
  void setManualBpm(int bpm) {
    _currentBpm = bpm;
    _bpmController.add(bpm);
  }

  void dispose() {
    _subscription?.cancel();
    _bpmController.close();
  }
}
