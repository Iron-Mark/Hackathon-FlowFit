import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offline action verifier includes every UI action test', () {
    final verifierSource = File(
      'scripts/verify_offline_app_actions.ps1',
    ).readAsStringSync();
    final verifierTests = _listedVerifierTests(verifierSource);
    final actionTests = _uiActionTests();

    final missing = actionTests.difference(verifierTests).toList()..sort();

    expect(
      missing,
      isEmpty,
      reason:
          'scripts/verify_offline_app_actions.ps1 is the repeatable offline '
          'gate for button and feature actions. Add new UI action tests to '
          'that script so the action gate cannot silently drift.',
    );
  });
}

Set<String> _listedVerifierTests(String source) {
  return RegExp(r"'(test/[^']+\.dart)'")
      .allMatches(source.replaceAll(r'\', '/'))
      .map((match) => match.group(1)!)
      .toSet();
}

Set<String> _uiActionTests() {
  const roots = [
    'test/app',
    'test/features',
    'test/integration',
    'test/routes',
    'test/screens',
    'test/widgets',
  ];
  final tests = <String>{};

  for (final root in roots) {
    final directory = Directory(root);
    if (!directory.existsSync()) continue;

    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final source = entity.readAsStringSync();
      if (_actionPattern.hasMatch(source)) {
        tests.add(_normalizePath(entity.path));
      }
    }
  }

  return tests;
}

String _normalizePath(String path) => path.replaceAll(r'\', '/');

final _actionPattern = RegExp(
  r'\b('
  r'tester\.(tap|longPress|drag|fling|enterText|ensureVisible|'
  r'scrollUntilVisible)|\.onPressed!|\.onTap!|widgetWithText|'
  r'widgetWithIcon|clickText|clickExactText|_invokeRouteAction'
  r')\b',
);
