import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/core/domain/entities/heart_rate_point.dart';

void main() {
  group('HeartRatePoint', () {
    late DateTime testTimestamp;

    setUp(() {
      testTimestamp = DateTime(2024, 1, 1, 12, 0, 0);
    });

    group('Constructor', () {
      test('creates instance with all required parameters', () {
        final point = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [800, 820, 810],
        );

        expect(point.timestamp, equals(testTimestamp));
        expect(point.bpm, equals(75));
        expect(point.ibiValues, equals([800, 820, 810]));
      });

      test('creates instance with empty ibiValues list', () {
        final point = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 60,
          ibiValues: [],
        );

        expect(point.ibiValues, isEmpty);
      });

      test('accepts valid bpm range', () {
        final lowBpm = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 40,
          ibiValues: [],
        );
        final highBpm = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 200,
          ibiValues: [],
        );

        expect(lowBpm.bpm, equals(40));
        expect(highBpm.bpm, equals(200));
      });
    });

    group('copyWith', () {
      test('creates copy with updated timestamp', () {
        final original = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [800],
        );
        final newTimestamp = testTimestamp.add(const Duration(seconds: 1));
        final copy = original.copyWith(timestamp: newTimestamp);

        expect(copy.timestamp, equals(newTimestamp));
        expect(copy.bpm, equals(original.bpm));
        expect(copy.ibiValues, equals(original.ibiValues));
      });

      test('creates copy with updated bpm', () {
        final original = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [800],
        );
        final copy = original.copyWith(bpm: 85);

        expect(copy.timestamp, equals(original.timestamp));
        expect(copy.bpm, equals(85));
        expect(copy.ibiValues, equals(original.ibiValues));
      });

      test('creates copy with updated ibiValues', () {
        final original = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [800],
        );
        final newIbiValues = [810, 820, 830];
        final copy = original.copyWith(ibiValues: newIbiValues);

        expect(copy.timestamp, equals(original.timestamp));
        expect(copy.bpm, equals(original.bpm));
        expect(copy.ibiValues, equals(newIbiValues));
      });

      test('creates copy with multiple updated fields', () {
        final original = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [800],
        );
        final newTimestamp = testTimestamp.add(const Duration(seconds: 1));
        final copy = original.copyWith(
          timestamp: newTimestamp,
          bpm: 80,
          ibiValues: [805],
        );

        expect(copy.timestamp, equals(newTimestamp));
        expect(copy.bpm, equals(80));
        expect(copy.ibiValues, equals([805]));
      });

      test('returns same values when no parameters provided', () {
        final original = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [800],
        );
        final copy = original.copyWith();

        expect(copy.timestamp, equals(original.timestamp));
        expect(copy.bpm, equals(original.bpm));
        expect(copy.ibiValues, equals(original.ibiValues));
      });
    });

    group('Equality', () {
      test('two instances with same values are equal', () {
        final point1 = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [800, 820],
        );
        final point2 = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [800, 820],
        );

        expect(point1, equals(point2));
        expect(point1.hashCode, equals(point2.hashCode));
      });

      test('two instances with different timestamps are not equal', () {
        final point1 = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [800],
        );
        final point2 = HeartRatePoint(
          timestamp: testTimestamp.add(const Duration(seconds: 1)),
          bpm: 75,
          ibiValues: [800],
        );

        expect(point1, isNot(equals(point2)));
      });

      test('two instances with different bpm are not equal', () {
        final point1 = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [800],
        );
        final point2 = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 80,
          ibiValues: [800],
        );

        expect(point1, isNot(equals(point2)));
      });

      test('two instances with different ibiValues are not equal', () {
        final point1 = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [800, 820],
        );
        final point2 = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [800, 830],
        );

        expect(point1, isNot(equals(point2)));
      });

      test('two instances with different ibiValues length are not equal', () {
        final point1 = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [800],
        );
        final point2 = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [800, 820],
        );

        expect(point1, isNot(equals(point2)));
      });

      test('instance is equal to itself', () {
        final point = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [800],
        );

        expect(point, equals(point));
      });

      test('equality handles empty ibiValues correctly', () {
        final point1 = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [],
        );
        final point2 = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: [],
        );

        expect(point1, equals(point2));
      });
    });

    group('Edge Cases', () {
      test('handles extreme bpm values', () {
        final veryLowBpm = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 0,
          ibiValues: [],
        );
        final veryHighBpm = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 300,
          ibiValues: [],
        );

        expect(veryLowBpm.bpm, equals(0));
        expect(veryHighBpm.bpm, equals(300));
      });

      test('handles large ibiValues arrays', () {
        final largeIbiValues = List.generate(1000, (i) => 800 + i);
        final point = HeartRatePoint(
          timestamp: testTimestamp,
          bpm: 75,
          ibiValues: largeIbiValues,
        );

        expect(point.ibiValues.length, equals(1000));
        expect(point.ibiValues.first, equals(800));
        expect(point.ibiValues.last, equals(1799));
      });

      test('handles timestamps with millisecond precision', () {
        final preciseTimestamp = DateTime(2024, 1, 1, 12, 0, 0, 123, 456);
        final point = HeartRatePoint(
          timestamp: preciseTimestamp,
          bpm: 75,
          ibiValues: [],
        );

        expect(point.timestamp.millisecond, equals(123));
        expect(point.timestamp.microsecond, equals(456));
      });
    });
  });
}
