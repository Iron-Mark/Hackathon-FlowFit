import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flowfit/models/running_session.dart';
import 'package:flowfit/screens/workout/running/share_achievement_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets('share achievement picks a background image', (tester) async {
    final tempDir = Directory.systemTemp.createTempSync(
      'flowfit_share_picker_',
    );
    addTearDown(() => _deleteDirectoryBestEffort(tempDir));
    final imageFile = _writeTestPng(tempDir, 'background.png');

    await tester.pumpWidget(_harness(pickImage: () async => imageFile));

    expect(find.text('Add Background Image'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Add Background Image'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Change Background'), findsOneWidget);
  });

  testWidgets('share achievement disables image picker while opening', (
    tester,
  ) async {
    final tempDir = Directory.systemTemp.createTempSync(
      'flowfit_share_picker_pending_',
    );
    addTearDown(() => _deleteDirectoryBestEffort(tempDir));
    final imageFile = _writeTestPng(tempDir, 'background.png');
    final pickCompleter = Completer<File?>();
    var pickCalls = 0;

    await tester.pumpWidget(
      _harness(
        pickImage: () {
          pickCalls++;
          return pickCompleter.future;
        },
      ),
    );

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Add Background Image'),
    );
    await tester.pump();

    expect(pickCalls, 1);
    expect(find.text('Opening Gallery...'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Opening Gallery...'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Opening Gallery...'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(pickCalls, 1);

    pickCompleter.complete(imageFile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Change Background'), findsOneWidget);
    expect(pickCalls, 1);
  });

  testWidgets('share achievement shows image picker failures', (tester) async {
    await tester.pumpWidget(
      _harness(pickImage: () async => throw StateError('gallery unavailable')),
    );

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Add Background Image'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Error selecting image:'), findsOneWidget);
    expect(find.text('Add Background Image'), findsOneWidget);
  });

  testWidgets('share achievement shares generated image and returns home', (
    tester,
  ) async {
    final shared = <_SharedAchievement>[];
    Uint8List? capturedBytes;
    final outputFile = File('flowfit_achievement_test.png');

    await tester.pumpWidget(
      _harness(
        captureShareCard: (_) async => Uint8List.fromList([1, 2, 3, 4]),
        getShareDirectory: () async => Directory.systemTemp,
        writeShareImage: ({required directory, required pngBytes}) async {
          capturedBytes = Uint8List.fromList(pngBytes);
          return outputFile;
        },
        shareImage: ({required file, required text}) async {
          shared.add(_SharedAchievement(file, text));
        },
      ),
    );

    expect(
      find.widgetWithText(ElevatedButton, 'Share Achievement'),
      findsOneWidget,
    );

    _pressAppBarShare(tester);
    await _pumpUntilFound(tester, find.text('route:dashboard'));

    expect(shared, hasLength(1));
    expect(capturedBytes, [1, 2, 3, 4]);
    expect(shared.single.file.path, outputFile.path);
    expect(shared.single.text, contains('1.50 km run'));
    expect(find.text('route:dashboard'), findsOneWidget);
  });

  testWidgets('share achievement bottom button shares and returns home', (
    tester,
  ) async {
    final shared = <_SharedAchievement>[];

    await tester.pumpWidget(
      _harness(
        captureShareCard: (_) async => Uint8List.fromList([5, 6, 7, 8]),
        getShareDirectory: () async => Directory.systemTemp,
        writeShareImage: ({required directory, required pngBytes}) async {
          return File('flowfit_achievement_bottom_button_test.png');
        },
        shareImage: ({required file, required text}) async {
          shared.add(_SharedAchievement(file, text));
        },
      ),
    );

    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Share Achievement'),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Share Achievement'));
    await _pumpUntilFound(tester, find.text('route:dashboard'));

    expect(shared, hasLength(1));
    expect(shared.single.text, contains('1.50 km run'));
    expect(find.text('route:dashboard'), findsOneWidget);
  });

  testWidgets('share achievement surfaces share generation failures', (
    tester,
  ) async {
    var shareCalls = 0;

    await tester.pumpWidget(
      _harness(
        captureShareCard: (_) async => throw StateError('capture unavailable'),
        shareImage: ({required file, required text}) async {
          shareCalls++;
        },
      ),
    );

    _pressAppBarShare(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(shareCalls, 0);
    expect(find.textContaining('Error sharing:'), findsOneWidget);
    expect(find.text('route:dashboard'), findsNothing);
  });
}

Widget _harness({
  ShareAchievementImagePicker? pickImage,
  ShareAchievementCapture? captureShareCard,
  ShareAchievementDirectoryProvider? getShareDirectory,
  ShareAchievementImageWriter? writeShareImage,
  ShareAchievementFileSharer? shareImage,
}) {
  return MaterialApp(
    home: ShareAchievementScreen(
      session: _runningSession(),
      pickImage: pickImage,
      captureShareCard: captureShareCard,
      getShareDirectory: getShareDirectory,
      writeShareImage: writeShareImage,
      shareImage: shareImage,
    ),
    routes: {
      '/dashboard': (_) => const Scaffold(body: Text('route:dashboard')),
    },
  );
}

RunningSession _runningSession() {
  return RunningSession(
    id: 'run-share-actions',
    userId: 'user-1',
    startTime: DateTime(2026),
    goalType: GoalType.distance,
    targetDistance: 5,
    durationSeconds: 600,
    currentDistance: 1.5,
    avgPace: 6.4,
    steps: 1800,
    caloriesBurned: 120,
    routePoints: const [LatLng(14.5995, 120.9842), LatLng(14.6000, 120.9850)],
  );
}

File _writeTestPng(Directory directory, String name) {
  final file = File('${directory.path}${Platform.pathSeparator}$name');
  file.writeAsBytesSync(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
    ),
  );
  return file;
}

Finder _appBarShareButton() {
  return find.descendant(
    of: find.byType(AppBar),
    matching: find.byType(IconButton),
  );
}

void _pressAppBarShare(WidgetTester tester) {
  final button = tester.widget<IconButton>(_appBarShareButton());
  expect(button.onPressed, isNotNull);
  button.onPressed!();
}

class _SharedAchievement {
  const _SharedAchievement(this.file, this.text);

  final File file;
  final String text;
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 20,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}

Future<void> _deleteDirectoryBestEffort(Directory directory) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
      return;
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
}
