import 'package:logger/logger.dart';

/// Web-safe classifier adapter.
///
/// The native TFLite package depends on dart:ffi, which is unavailable on
/// Flutter web. Keep the same public API so the app can compile and surface a
/// runtime feature-unavailable state instead of failing at build time.
class TFLiteActivityClassifier {
  final Logger _logger = Logger();
  bool _warned = false;

  static const int _inputLength = 320;

  Future<void> loadModel() async {
    if (_warned) return;

    _logger.w('TFLite activity classification is unavailable on Flutter web.');
    _warned = true;
  }

  Future<List<double>> predict(List<List<double>> buffer) async {
    if (buffer.length != _inputLength) {
      throw ArgumentError(
        'Buffer length must be $_inputLength, got ${buffer.length}',
      );
    }

    throw UnsupportedError(
      'TFLite activity classification is unavailable on Flutter web because '
      'tflite_flutter requires dart:ffi.',
    );
  }

  bool get isLoaded => false;

  void dispose() {
    _warned = false;
  }
}
