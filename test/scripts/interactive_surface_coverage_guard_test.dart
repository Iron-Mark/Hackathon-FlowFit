import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interactive production surfaces have action-oriented tests', () {
    final testFiles = _testFiles();
    final uncovered = <String>[];

    for (final file in _interactiveProductionFiles()) {
      final source = file.readAsStringSync();
      final identifiers = _coverageIdentifiers(file, source);

      final hasActionCoverage = _hasActionCoverageReference(
        identifiers,
        testFiles,
      );
      if (!hasActionCoverage) {
        uncovered.add(
          '${_normalizePath(file.path)} '
          '(expected one of: ${identifiers.take(6).join(', ')})',
        );
      }
    }

    uncovered.sort();
    expect(
      uncovered,
      isEmpty,
      reason:
          'Every production file that declares visible controls should have a '
          'widget, route, or grouped action test that both references the '
          'surface and drives a user action. Add focused action coverage for '
          'the new surface, or reference its public widget/helper from an '
          'existing grouped action test.',
    );
  });
}

List<File> _testFiles() {
  final files = <File>[];
  for (final file in Directory('test').listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    files.add(file);
  }
  files.sort(
    (a, b) => _normalizePath(a.path).compareTo(_normalizePath(b.path)),
  );
  return files;
}

bool _hasActionCoverageReference(Set<String> identifiers, List<File> files) {
  for (final file in files) {
    final source = file.readAsStringSync();
    if (!identifiers.any(source.contains)) continue;
    if (_actionCoveragePattern.hasMatch(source)) {
      return true;
    }
  }
  return false;
}

List<File> _interactiveProductionFiles() {
  final files = <File>[];
  for (final root in const ['lib/screens', 'lib/widgets', 'lib/features']) {
    final directory = Directory(root);
    if (!directory.existsSync()) continue;

    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (_interactivePattern.hasMatch(source)) {
        files.add(entity);
      }
    }
  }
  files.sort(
    (a, b) => _normalizePath(a.path).compareTo(_normalizePath(b.path)),
  );
  return files;
}

Set<String> _coverageIdentifiers(File file, String source) {
  final normalizedPath = _normalizePath(file.path);
  final fileName = normalizedPath.split('/').last;
  final stem = fileName.replaceFirst(RegExp(r'\.dart$'), '');
  final identifiers = <String>{stem};

  final trimmedStem = stem.replaceFirst(
    RegExp(r'_(screen|page|widget|button|dialog)$'),
    '',
  );
  if (trimmedStem != stem) {
    identifiers.add(trimmedStem);
  }

  for (final match in _classPattern.allMatches(source)) {
    identifiers.add(match.group(1)!);
  }
  for (final match in _topLevelFunctionPattern.allMatches(source)) {
    final functionName = match.group(2)!;
    if (!_commonFunctionNames.contains(functionName)) {
      identifiers.add(functionName);
    }
  }

  identifiers.removeWhere((value) => value.length < 5);
  return identifiers;
}

String _normalizePath(String path) => path.replaceAll(r'\', '/');

final _interactivePattern = RegExp(
  r'\b('
  r'onPressed|onTap|onLongPress|onDoubleTap|GestureDetector|InkWell|'
  r'IconButton|TextButton|ElevatedButton|OutlinedButton|FilledButton|'
  r'FloatingActionButton|PopupMenuButton|showDialog|showModalBottomSheet'
  r')\b',
);

final _actionCoveragePattern = RegExp(
  r'\b('
  r'testWidgets|tester\.(tap|longPress|drag|fling|enterText|ensureVisible|'
  r'scrollUntilVisible)|\.onPressed!|\.onTap!|widgetWithText|widgetWithIcon|'
  r'clickText|clickExactText|_invokeRouteAction'
  r')\b',
);

final _classPattern = RegExp(r'\bclass\s+([A-Z][A-Za-z0-9_]*)\b');
final _topLevelFunctionPattern = RegExp(
  r'^(?:[A-Za-z_][A-Za-z0-9_<>,? ]+\s+)?'
  r'([A-Za-z_][A-Za-z0-9_<>,? ]+)?\s*'
  r'([a-z][A-Za-z0-9_]*)\s*\(',
  multiLine: true,
);

const _commonFunctionNames = {
  'build',
  'createState',
  'initState',
  'dispose',
  'setState',
};
