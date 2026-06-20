import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app code does not hard-code public OSM tile servers', () {
    final offenders = <String>[];
    final pattern = RegExp(r'tile\.(?:openstreetmap|osm)\.org');

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        if (!pattern.hasMatch(lines[index])) continue;

        offenders.add('${entity.path.replaceAll('\\', '/')}:${index + 1}');
      }
    }

    expect(offenders, isEmpty);
  });
}
