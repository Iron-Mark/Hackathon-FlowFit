import 'package:flowfit/features/activity_classifier/platform/tflite_activity_classifier_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('web TFLiteActivityClassifier fallback', () {
    late TFLiteActivityClassifier classifier;

    setUp(() {
      classifier = TFLiteActivityClassifier();
    });

    tearDown(() {
      classifier.dispose();
    });

    test('requires loadModel before prediction', () async {
      final buffer = List.generate(320, (_) => [0.1, 0.1, 9.8, 95.0]);

      expect(() => classifier.predict(buffer), throwsA(isA<StateError>()));
    });

    test('returns a stress-biased prediction for elevated BPM', () async {
      await classifier.loadModel();
      final buffer = List.generate(320, (_) => [0.1, 0.1, 9.8, 95.0]);

      final prediction = await classifier.predict(buffer);

      expect(prediction, [0.70, 0.20, 0.10]);
    });

    test(
      'returns a cardio-biased prediction for high motion and BPM',
      () async {
        await classifier.loadModel();
        final buffer = List.generate(320, (_) => [3.0, 3.0, 11.0, 125.0]);

        final prediction = await classifier.predict(buffer);

        expect(prediction, [0.10, 0.80, 0.10]);
      },
    );

    test('validates sample shape', () async {
      await classifier.loadModel();
      final buffer = List.generate(320, (_) => [0.1, 0.1, 9.8]);

      expect(() => classifier.predict(buffer), throwsA(isA<ArgumentError>()));
    });
  });
}
