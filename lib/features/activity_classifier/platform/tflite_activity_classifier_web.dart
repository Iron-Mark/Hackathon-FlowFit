import 'package:logger/logger.dart';

/// Web-safe classifier adapter.
///
/// The native TFLite package depends on dart:ffi, which is unavailable on
/// Flutter web. Keep the same public API so the app can compile and surface a
/// runtime feature-unavailable state instead of failing at build time.
class TFLiteActivityClassifier {
  final Logger _logger = Logger();
  bool _warned = false;
  bool _isLoaded = false;

  static const int _inputLength = 320;

  Future<void> loadModel() async {
    _isLoaded = true;

    if (!_warned) {
      _logger.w(
        'TFLite is unavailable on Flutter web; using heuristic activity classification.',
      );
      _warned = true;
    }
  }

  Future<List<double>> predict(List<List<double>> buffer) async {
    if (!_isLoaded) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    if (buffer.length != _inputLength) {
      throw ArgumentError(
        'Buffer length must be $_inputLength, got ${buffer.length}',
      );
    }

    var motionSum = 0.0;
    var bpmSum = 0.0;

    for (final sample in buffer) {
      if (sample.length != 4) {
        throw ArgumentError(
          'Each buffer item must contain [accX, accY, accZ, bpm].',
        );
      }

      final x = sample[0];
      final y = sample[1];
      final z = sample[2] - 9.8;
      motionSum += x.abs() + y.abs() + z.abs();
      bpmSum += sample[3];
    }

    final avgMotion = motionSum / buffer.length;
    final avgBpm = bpmSum / buffer.length;

    if (avgBpm >= 120 || avgMotion >= 4.0) {
      return const [0.10, 0.80, 0.10]; // Cardio
    }

    if (avgMotion >= 2.0) {
      return const [0.15, 0.20, 0.65]; // Strength
    }

    if (avgBpm >= 90) {
      return const [0.70, 0.20, 0.10]; // Stress
    }

    return const [0.20, 0.40, 0.40]; // Low-intensity movement fallback
  }

  bool get isLoaded => _isLoaded;

  void dispose() {
    _warned = false;
    _isLoaded = false;
  }
}
