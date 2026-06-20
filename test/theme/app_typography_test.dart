import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app text styles keep letter spacing at zero', () {
    final offenders = <String>[];
    final pattern = RegExp(r'letterSpacing:\s*(-?\d+(?:\.\d+)?)');

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final match = pattern.firstMatch(lines[index]);
        if (match == null) continue;

        final value = double.parse(match.group(1)!);
        if (value != 0) {
          offenders.add(
            '${entity.path.replaceAll('\\', '/')}:${index + 1}: $value',
          );
        }
      }
    }

    expect(offenders, isEmpty);
  });
}
