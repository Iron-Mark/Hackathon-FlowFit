import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('static Navigator route targets are registered in release routes', () {
    final registeredRoutes = _registeredReleaseRoutes();
    final navigationTargets = _staticNavigatorTargets();

    final missingRoutes = navigationTargets.difference(registeredRoutes);

    expect(
      missingRoutes,
      isEmpty,
      reason:
          'Every static Navigator.pushNamed target must be registered in '
          'release MaterialApp.routes so tapped buttons do not fail at '
          'runtime.',
    );
  });

  test('production Navigator targets do not depend on debug-only routes', () {
    final debugOnlyRoutes = _registeredDebugOnlyRoutes();
    final navigationTargets = _staticNavigatorTargets();

    final debugTargets = navigationTargets.intersection(debugOnlyRoutes);

    expect(
      debugTargets,
      isEmpty,
      reason:
          'Routes registered inside if (kDebugMode) are unavailable in release '
          'builds and must not be used by production navigation controls.',
    );
  });

  test('unregistered slash string literals are known non-release routes', () {
    final releaseRoutes = _registeredReleaseRoutes();
    final debugOnlyRoutes = _registeredDebugOnlyRoutes();

    final unknownSlashLiterals =
        _slashStringLiterals()
            .where((literal) => !releaseRoutes.contains(literal.value))
            .where(
              (literal) =>
                  !_isKnownNonReleaseSlashLiteral(literal, debugOnlyRoutes),
            )
            .map((literal) => literal.description)
            .toList()
          ..sort();

    expect(
      unknownSlashLiterals,
      isEmpty,
      reason:
          'Slash-prefixed string literals often become route names. Keep them '
          'registered in release routes, or add a narrow explicit exception '
          'for debug-only routes and non-route display text.',
    );
  });

  test('direct MaterialPageRoute pushes stay reviewed and covered', () {
    final directPushes = _directMaterialPageRoutePushes();
    final unexpectedDirectPushes =
        directPushes
            .where((push) => !_reviewedDirectMaterialPushes.contains(push.key))
            .map((push) => push.description)
            .toList()
          ..sort();

    expect(
      unexpectedDirectPushes,
      isEmpty,
      reason:
          'Direct MaterialPageRoute pushes bypass the named route table and '
          'static route registration guard. Add widget coverage for the new '
          'button flow, then add a narrow reviewed entry here.',
    );
  });
}

Set<String> _registeredReleaseRoutes() {
  final mainSource = File('lib/main.dart').readAsStringSync();
  final debugRoutesStart = mainSource.indexOf('if (kDebugMode)');
  final releaseSource = debugRoutesStart == -1
      ? mainSource
      : mainSource.substring(0, debugRoutesStart);

  return _registeredRoutesFromSource(releaseSource);
}

Set<String> _registeredDebugOnlyRoutes() {
  final mainSource = File('lib/main.dart').readAsStringSync();
  final debugRoutesStart = mainSource.indexOf('if (kDebugMode)');
  if (debugRoutesStart == -1) return <String>{};

  return _registeredRoutesFromSource(mainSource.substring(debugRoutesStart));
}

Set<String> _registeredRoutesFromSource(String source) {
  return RegExp(
    r"'(/[^']+)'\s*:",
  ).allMatches(source).map((match) => match.group(1)!).toSet();
}

Set<String> _staticNavigatorTargets() {
  final targets = <String>{};

  for (final file in Directory('lib').listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;

    final source = file.readAsStringSync();
    targets.addAll(_staticNavigatorFunctionTargets(source));
    targets.addAll(_staticNavigatorOfTargets(source));
  }

  return targets;
}

Iterable<String> _staticNavigatorFunctionTargets(String source) {
  return RegExp(
    r"Navigator\.(?:pushNamed|pushReplacementNamed|pushNamedAndRemoveUntil)"
    r"\s*\(\s*[^,]+,\s*'(/[^']+)'",
    dotAll: true,
  ).allMatches(source).map((match) => match.group(1)!);
}

Iterable<String> _staticNavigatorOfTargets(String source) {
  return RegExp(
    r"Navigator\.of\([^)]*\)\."
    r"(?:pushNamed|pushReplacementNamed|pushNamedAndRemoveUntil)"
    r"\s*\(\s*'(/[^']+)'",
    dotAll: true,
  ).allMatches(source).map((match) => match.group(1)!);
}

List<_SlashLiteral> _slashStringLiterals() {
  final literals = <_SlashLiteral>[];

  for (final file in Directory('lib').listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;

    final normalizedPath = file.path.replaceAll(r'\', '/');
    final source = file.readAsStringSync();
    for (final match in _slashStringLiteralPattern.allMatches(source)) {
      literals.add(
        _SlashLiteral(
          filePath: normalizedPath,
          line: _lineForOffset(source, match.start),
          value: match.group(1)!,
        ),
      );
    }
  }

  return literals;
}

List<_DirectMaterialRoutePush> _directMaterialPageRoutePushes() {
  final pushes = <_DirectMaterialRoutePush>[];

  for (final file in Directory('lib').listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;

    final normalizedPath = file.path.replaceAll(r'\', '/');
    final source = file.readAsStringSync();
    for (final match in _materialPageRoutePattern.allMatches(source)) {
      pushes.add(
        _DirectMaterialRoutePush(
          filePath: normalizedPath,
          line: _lineForOffset(source, match.start),
          destination: match.group(1)!,
        ),
      );
    }
  }

  return pushes;
}

bool _isKnownNonReleaseSlashLiteral(
  _SlashLiteral literal,
  Set<String> debugOnlyRoutes,
) {
  if (debugOnlyRoutes.contains(literal.value)) {
    return literal.filePath.endsWith('lib/main.dart') ||
        literal.filePath.endsWith('lib/widgets/debug_route_menu.dart');
  }

  return literal.filePath.endsWith(
        'lib/screens/workout/running/active_running_screen.dart',
      ) &&
      literal.value == '/km';
}

final _slashStringLiteralPattern = RegExp(r'''['"](/[^'"]+)['"]''');
final _materialPageRoutePattern = RegExp(
  r'MaterialPageRoute(?:<[^>]+>)?\s*\(\s*builder\s*:\s*'
  r'\([^)]*\)\s*=>\s*(?:const\s+)?([A-Za-z_][A-Za-z0-9_]*)',
  dotAll: true,
);

final _reviewedDirectMaterialPushes = <String>{
  'lib/screens/mood_tracking_demo_screen.dart|PostWorkoutMoodCheck',
  'lib/screens/wear/wear_dashboard.dart|AmbientMode',
  'lib/screens/wear/wear_heart_rate_screen.dart|SensorPermissionRationaleScreen',
  'lib/screens/workout/walking/mission_creation_screen.dart|ActiveWalkingScreen',
  'lib/screens/workout/walking/walking_options_screen.dart|ActiveWalkingScreen',
  'lib/screens/workout/walking/walking_options_screen.dart|MissionCreationScreen',
  'lib/screens/workout/walking/walking_summary_screen.dart|MissionCreationScreen',
};

int _lineForOffset(String source, int offset) {
  return '\n'.allMatches(source.substring(0, offset)).length + 1;
}

class _SlashLiteral {
  const _SlashLiteral({
    required this.filePath,
    required this.line,
    required this.value,
  });

  final String filePath;
  final int line;
  final String value;

  String get description => '$filePath:$line $value';
}

class _DirectMaterialRoutePush {
  const _DirectMaterialRoutePush({
    required this.filePath,
    required this.line,
    required this.destination,
  });

  final String filePath;
  final int line;
  final String destination;

  String get key => '$filePath|$destination';

  String get description => '$filePath:$line MaterialPageRoute->$destination';
}
