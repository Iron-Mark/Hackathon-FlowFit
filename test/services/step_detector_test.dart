import 'package:flowfit/services/step_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StepDetector', () {
    late DateTime now;
    late StepDetector detector;

    setUp(() {
      now = DateTime(2026, 6, 21, 10);
      detector = StepDetector(clock: () => now);
    });

    test('detects a step when a peak falls below the step threshold', () {
      expect(detector.processMagnitude(9), isFalse);
      expect(detector.processMagnitude(14), isFalse);
      expect(detector.processMagnitude(10), isTrue);

      expect(detector.totalSteps, 1);
    });

    test('does not double count peaks inside the debounce window', () {
      detector.processMagnitude(9);
      detector.processMagnitude(14);
      detector.processMagnitude(10);

      now = now.add(
        const Duration(milliseconds: StepDetector.minTimeBetweenStepsMs - 1),
      );
      detector.processMagnitude(9);
      detector.processMagnitude(14);
      final detected = detector.processMagnitude(10);

      expect(detected, isFalse);
      expect(detector.totalSteps, 1);
    });

    test('counts a second step after the debounce window', () {
      detector.processMagnitude(9);
      detector.processMagnitude(14);
      detector.processMagnitude(10);

      now = now.add(
        const Duration(milliseconds: StepDetector.minTimeBetweenStepsMs),
      );
      detector.processMagnitude(9);
      detector.processMagnitude(14);
      final detected = detector.processMagnitude(10);

      expect(detected, isTrue);
      expect(detector.totalSteps, 2);
    });

    test('calculates magnitude from accelerometer samples', () {
      expect(detector.processSample(0, 0, 9.8), isFalse);
      expect(detector.processSample(0, 0, 14.2), isFalse);
      expect(detector.processSample(0, 0, 10.5), isTrue);

      expect(detector.totalSteps, 1);
    });

    test('reset clears count and pending peak state', () {
      detector.processMagnitude(9);
      detector.processMagnitude(14);

      detector.reset();

      expect(detector.totalSteps, 0);
      expect(detector.processMagnitude(10), isFalse);
      expect(detector.totalSteps, 0);
    });
  });
}
