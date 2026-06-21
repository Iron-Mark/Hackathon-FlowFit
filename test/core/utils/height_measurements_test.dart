import 'package:flowfit/core/utils/height_measurements.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('height measurement helpers', () {
    test(
      'stores feet and inches as total inches without losing two digits',
      () {
        expect(parseHeightForStorage('5.10', 'ft'), 70);
        expect(parseHeightForStorage('5.11', 'ft'), 71);
        expect(parseHeightForStorage('5.13', 'ft'), isNull);
      },
    );

    test('formats new total-inch storage and legacy decimal input', () {
      expect(formatHeightMeasurement(70, 'ft'), '5 ft 10 in');
      expect(formatHeightMeasurement(5.8, 'ft'), '5 ft 8 in');
      expect(formatHeightMeasurement(180, 'cm'), '180cm');
    });

    test('converts exact stored feet and inches to centimeters', () {
      expect(heightInCentimeters(70, 'ft'), closeTo(177.8, 0.001));
      expect(heightInCentimeters(5.8, 'ft'), closeTo(172.72, 0.001));
    });

    test('converts entered values when switching height units', () {
      expect(
        convertHeightInputForUnit(input: '170', fromUnit: 'cm', toUnit: 'ft'),
        '5.7',
      );
      expect(
        convertHeightInputForUnit(input: '5.8', fromUnit: 'ft', toUnit: 'cm'),
        '172.7',
      );
      expect(
        convertHeightInputForUnit(input: '5.13', fromUnit: 'ft', toUnit: 'cm'),
        isNull,
      );
      expect(
        convertHeightInputForUnit(input: '-1', fromUnit: 'cm', toUnit: 'ft'),
        isNull,
      );
    });
  });
}
