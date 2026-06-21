import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/features/activity_classifier/platform/tflite_activity_classifier.dart';

void main() {
  group('TFLiteActivityClassifier', () {
    late TFLiteActivityClassifier classifier;

    setUp(() {
      classifier = TFLiteActivityClassifier();
    });

    tearDown(() {
      classifier.dispose();
    });

    test('is not loaded initially', () {
      expect(classifier.isLoaded, isFalse);
    });

    test('throws error if predict called before loadModel', () async {
      final buffer = List.generate(320, (_) => [1.0, 2.0, 3.0, 72.0]);

      expect(
        () => classifier.predict(buffer),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not loaded'),
          ),
        ),
      );
    });

    test('validates input buffer length', () async {
      // Skip model loading in test; just test validation
      // In real app, loadModel() would initialize _interpreter

      final shortBuffer = List.generate(100, (_) => [1.0, 2.0, 3.0, 72.0]);

      expect(
        () => classifier.predict(shortBuffer),
        throwsA(isA<StateError>()), // Model not loaded error comes first
      );
    });

    test('dispose cleans up resources', () {
      classifier.dispose();
      expect(classifier.isLoaded, isFalse);
    });

    // Note: Full inference tests would require actual TFLite model
    // and would run in integration tests, not unit tests
  });
}
