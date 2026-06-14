import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:logger/logger.dart';

/// Platform-specific TFLite ML inference wrapper
/// Handles model loading and prediction logic
/// This adapter isolates TFLite dependencies from domain/presentation layers
class TFLiteActivityClassifier {
  Interpreter? _interpreter;
  final Logger _logger = Logger();

  static const String _modelAsset = 'assets/model/activity_tracker.tflite';
  static const int _inputLength = 320; // Time window size
  static const int _inputFeatures = 4; // [accX, accY, accZ, bpm]
  static const int _outputClasses = 3; // [Stress, Cardio, Strength]

  /// Load TFLite model from assets
  /// Call this once during app initialization
  Future<void> loadModel() async {
    try {
      _logger.i('Loading TFLite model from $_modelAsset');
      _interpreter = await Interpreter.fromAsset(_modelAsset);

      // Validate model shape
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      final inputShape = inputTensor.shape;
      final outputShape = outputTensor.shape;

      _logger.d(
        'Input shape: $inputShape (expected [1, $_inputLength, $_inputFeatures])',
      );
      _logger.d('Output shape: $outputShape (expected [1, $_outputClasses])');

      // Validate shapes match expectations
      if (inputShape[1] != _inputLength || inputShape[2] != _inputFeatures) {
        throw Exception(
          'Input shape mismatch: expected [1, $_inputLength, $_inputFeatures], got $inputShape',
        );
      }

      if (outputShape[1] != _outputClasses) {
        throw Exception(
          'Output shape mismatch: expected [1, $_outputClasses], got $outputShape',
        );
      }

      _logger.i('✅ Model loaded successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to load model', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Run inference on sensor buffer
  /// Expects buffer of [accX, accY, accZ, bpm] values, length 320
  /// Returns list of 3 probabilities [stress%, cardio%, strength%]
  Future<List<double>> predict(List<List<double>> buffer) async {
    if (_interpreter == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    if (buffer.length != _inputLength) {
      throw ArgumentError(
        'Buffer length must be $_inputLength, got ${buffer.length}',
      );
    }

    try {
      _logger.d('Running inference on buffer (${buffer.length} samples)');

      // 1. Reshape input to [1, 320, 4] (batch size of 1)
      final input = [buffer];

      // 2. Prepare output buffer [1, 3]
      final output = List.filled(
        1 * _outputClasses,
        0.0,
      ).reshape([1, _outputClasses]);

      // 3. Run inference
      _interpreter!.run(input, output);

      // 4. Extract and return probabilities
      final probabilities = List<double>.from(output[0] as List);

      _logger.d(
        'Inference result: [Stress=${(probabilities[0] * 100).toStringAsFixed(1)}%, '
        'Cardio=${(probabilities[1] * 100).toStringAsFixed(1)}%, '
        'Strength=${(probabilities[2] * 100).toStringAsFixed(1)}%]',
      );

      return probabilities;
    } catch (e, stackTrace) {
      _logger.e('Inference failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Check if model is loaded
  bool get isLoaded => _interpreter != null;

  /// Dispose and cleanup resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _logger.i('Model disposed');
  }
}
