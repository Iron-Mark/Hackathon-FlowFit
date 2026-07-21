import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/features/activity_classifier/domain/activity_sample_buffer.dart';

void main() {
  group('ActivitySampleBuffer', () {
    test('add rejects a sample whose length is not 4', () {
      final buffer = ActivitySampleBuffer();

      final accepted = buffer.add([1.0, 2.0, 3.0]);

      expect(accepted, isFalse);
      expect(buffer.length, equals(0));
    });

    test('add accepts a 4-feature sample', () {
      final buffer = ActivitySampleBuffer();

      final accepted = buffer.add([1.0, 2.0, 3.0, 90.0]);

      expect(accepted, isTrue);
      expect(buffer.length, equals(1));
    });

    test('adding 400 samples trims to exactly 320', () {
      final buffer = ActivitySampleBuffer();

      for (var i = 0; i < 400; i++) {
        buffer.add([i.toDouble(), 0.0, 0.0, 90.0]);
      }

      expect(buffer.length, equals(320));
    });

    test('isReady is false at 319 and true at 320', () {
      final buffer = ActivitySampleBuffer();

      for (var i = 0; i < 319; i++) {
        buffer.add([1.0, 2.0, 3.0, 90.0]);
      }
      expect(buffer.isReady, isFalse);

      buffer.add([1.0, 2.0, 3.0, 90.0]);
      expect(buffer.isReady, isTrue);
    });

    test('window returns a copy that does not mutate the buffer', () {
      final buffer = ActivitySampleBuffer();
      buffer.add([1.0, 2.0, 3.0, 90.0]);
      buffer.add([4.0, 5.0, 6.0, 95.0]);

      final window = buffer.window();
      window.clear();

      expect(buffer.length, equals(2));
    });
  });
}
