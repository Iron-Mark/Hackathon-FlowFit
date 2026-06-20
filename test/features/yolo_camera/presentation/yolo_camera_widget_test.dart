import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flowfit/features/yolo_camera/domain/entities/detection_result.dart';
import 'package:flowfit/features/yolo_camera/domain/repositories/yolo_repository.dart';
import 'package:flowfit/features/yolo_camera/presentation/providers/providers.dart';
import 'package:flowfit/features/yolo_camera/presentation/widgets/yolo_camera_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('flowfit_yolo_widget_');
  });

  tearDown(() async {
    await _deleteDirectoryBestEffort(tempDir);
  });

  testWidgets('single-shot pick image action runs object detection', (
    tester,
  ) async {
    final image = _writeTestPng(tempDir, 'gallery.png');
    final repository = _FakeYoloRepository();
    List<DetectionResult>? detectedResults;

    await tester.pumpWidget(
      _harness(
        repository: repository,
        child: YoloCameraWidget(
          cameraMode: CameraMode.singleShot,
          pickImage: () async => image.path,
          readImageBytes: (_) async => Uint8List.fromList([1, 2, 3, 4]),
          onDetection: (results) => detectedResults = results,
        ),
      ),
    );

    await tester.tap(find.text('Pick Image'));
    await _pumpExternalAsync(tester);

    expect(repository.detectedImageBytes, isNotNull);
    expect(repository.detectedAsObject, isTrue);
    expect(detectedResults, hasLength(1));
    expect(detectedResults!.single.label, 'water bottle');
    expect(find.text('Pick Another'), findsOneWidget);
  });

  testWidgets('single-shot pick image cancellation keeps the empty state', (
    tester,
  ) async {
    final repository = _FakeYoloRepository();

    await tester.pumpWidget(
      _harness(
        repository: repository,
        child: YoloCameraWidget(
          cameraMode: CameraMode.singleShot,
          pickImage: () async => null,
        ),
      ),
    );

    await tester.tap(find.text('Pick Image'));
    await _pumpExternalAsync(tester);

    expect(repository.detectedImageBytes, isNull);
    expect(find.text('Pick Image'), findsOneWidget);
    expect(find.textContaining('Could not analyze image'), findsNothing);
  });

  testWidgets('single-shot pick image failure shows recoverable feedback', (
    tester,
  ) async {
    final repository = _FakeYoloRepository();

    await tester.pumpWidget(
      _harness(
        repository: repository,
        child: YoloCameraWidget(
          cameraMode: CameraMode.singleShot,
          pickImage: () async => throw StateError('gallery unavailable'),
        ),
      ),
    );

    await tester.tap(find.text('Pick Image'));
    await _pumpExternalAsync(tester);

    expect(repository.detectedImageBytes, isNull);
    expect(find.text('Pick Image'), findsOneWidget);
    expect(find.textContaining('Could not analyze image:'), findsOneWidget);
  });
}

Future<void> _pumpExternalAsync(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pumpAndSettle();
}

Widget _harness({required YoloRepository repository, required Widget child}) {
  return ProviderScope(
    overrides: [yoloRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      home: Scaffold(body: SizedBox.expand(child: child)),
    ),
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

class _FakeYoloRepository implements YoloRepository {
  Uint8List? detectedImageBytes;
  bool? detectedAsObject;

  @override
  Future<List<DetectionResult>> detectFromImageBytes(
    Uint8List imageBytes, {
    required bool isObjectDetection,
  }) async {
    detectedImageBytes = imageBytes;
    detectedAsObject = isObjectDetection;
    return [
      DetectionResult(
        label: 'water bottle',
        confidence: 0.91,
        bbox: const [0.1, 0.1, 0.4, 0.5],
      ),
    ];
  }

  @override
  Future<List<DetectionResult>> detectObjects(CameraImage image) async => [];

  @override
  Future<List<DetectionResult>> detectPose(CameraImage image) async => [];

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initObjectDetector() async {}

  @override
  Future<void> initPoseDetector() async {}
}
