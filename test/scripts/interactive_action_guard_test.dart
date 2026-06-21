import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production UI does not leave empty interactive handlers', () {
    final emptyHandlers = _findEmptyInteractiveHandlers();

    expect(
      emptyHandlers,
      isEmpty,
      reason:
          'Empty onPressed/onTap/onLongPress handlers make controls look '
          'available while doing nothing. Use a real action, a disabled null '
          'handler, or a user-visible unavailable state.',
    );
  });

  test('production UI does not expose placeholder availability copy', () {
    final placeholderCopy = _findPlaceholderUiCopy();

    expect(
      placeholderCopy,
      isEmpty,
      reason:
          'Production screens should not ship user-visible "coming soon", '
          '"not implemented", placeholder, or TODO copy. Wire the action, '
          'hide/disable it, or show a specific actionable error instead.',
    );
  });
}

List<String> _findEmptyInteractiveHandlers() {
  final handlers = <String>[];

  for (final file in Directory('lib').listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;

    final source = file.readAsStringSync();
    for (final match in _emptyHandlerPattern.allMatches(source)) {
      final line = _lineForOffset(source, match.start);
      handlers.add('${file.path}:$line ${match.group(1)}');
    }
  }

  handlers.sort();
  return handlers;
}

final _emptyHandlerPattern = RegExp(
  r'\b('
  r'onPressed|onTap|onLongPress|onDoubleTap|'
  r'onChanged|onSubmitted|onEditingComplete|onFieldSubmitted|onSaved|'
  r'onSelected|onRefresh|onDismissed|onDestinationSelected|onPageChanged|'
  r'onAccept|onAcceptWithDetails'
  r')\s*:\s*'
  r'(?:\([^)]*\)\s*)?'
  r'(?:async\s*)?'
  r'(?:\{\s*\}|=>\s*(?:null|Future(?:<[^>]+>)?\.value\(\)|\(\)))',
  multiLine: true,
  dotAll: true,
);

List<String> _findPlaceholderUiCopy() {
  final matches = <String>[];
  final roots = [
    Directory('lib/screens'),
    Directory('lib/widgets'),
    Directory('lib/features'),
  ];

  for (final root in roots) {
    if (!root.existsSync()) continue;

    for (final file in root.listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;

      final source = file.readAsStringSync();
      for (final match in _dartStringLiteralPattern.allMatches(source)) {
        final literal = match.group(1) ?? match.group(2) ?? '';
        if (!_placeholderCopyPattern.hasMatch(literal)) continue;

        final line = _lineForOffset(source, match.start);
        matches.add('${file.path}:$line "$literal"');
      }
    }
  }

  matches.sort();
  return matches;
}

final _dartStringLiteralPattern = RegExp(
  r'''(?:r)?'([^'\\\r\n]*(?:\\.[^'\\\r\n]*)*)'|(?:r)?"([^"\\\r\n]*(?:\\.[^"\\\r\n]*)*)"''',
  multiLine: true,
);

final _placeholderCopyPattern = RegExp(
  r'\b(?:coming soon|not implemented|under construction|todo|tbd|placeholder|'
  r'lorem ipsum|dummy)\b',
  caseSensitive: false,
);

int _lineForOffset(String source, int offset) {
  return '\n'.allMatches(source.substring(0, offset)).length + 1;
}
