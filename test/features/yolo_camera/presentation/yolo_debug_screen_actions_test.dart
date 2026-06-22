import 'package:flowfit/features/yolo_camera/domain/entities/detection_result.dart';
import 'package:flowfit/features/yolo_camera/presentation/screens/yolo_debug_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YoloDebugScreen actions', () {
    testWidgets('info dialog opens and closes', (tester) async {
      await tester.pumpWidget(_harness());

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.text('YOLO Debug Info'), findsOneWidget);
      expect(
        find.textContaining('Object detection: YOLOv11s food model'),
        findsOneWidget,
      );
      expect(find.textContaining('Pose'), findsNothing);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('YOLO Debug Info'), findsNothing);
    });

    testWidgets('camera mode switch rebuilds the preview and clears results', (
      tester,
    ) async {
      await tester.pumpWidget(_harness());

      expect(find.text('Fake camera: realtime'), findsOneWidget);
      expect(find.text('Detections: 0'), findsOneWidget);

      await tester.tap(find.text('Emit detection'));
      await tester.pumpAndSettle();

      expect(find.text('Detections: 1'), findsOneWidget);
      expect(find.text('banana'), findsOneWidget);

      await tester.tap(find.text('Picture'));
      await tester.pumpAndSettle();

      expect(find.text('Fake camera: singleShot'), findsOneWidget);
      expect(find.text('Detections: 0'), findsOneWidget);
      expect(find.text('banana'), findsNothing);
    });

    testWidgets('only the working object detection mode is exposed', (
      tester,
    ) async {
      await tester.pumpWidget(_harness());

      expect(find.text('Detection mode: object'), findsOneWidget);
      expect(find.text('Object detection'), findsOneWidget);
      expect(find.text('YOLOv11s food model active'), findsOneWidget);
      expect(find.textContaining('Pose'), findsNothing);
      expect(find.text('Detection mode: object'), findsOneWidget);
    });

    testWidgets('detections render confidence chips', (tester) async {
      await tester.pumpWidget(_harness());

      await tester.tap(find.text('Emit detection'));
      await tester.pumpAndSettle();

      expect(find.text('Detections: 1'), findsOneWidget);
      expect(find.text('banana'), findsOneWidget);
      expect(find.text('88.0%'), findsOneWidget);
    });

    testWidgets('camera builder errors show retry and can recover', (
      tester,
    ) async {
      var shouldThrow = true;

      await tester.pumpWidget(
        MaterialApp(
          home: YoloDebugScreen(
            cameraBuilder: (context, detectionMode, cameraMode, onDetection) {
              if (shouldThrow) {
                throw StateError('camera unavailable');
              }

              return const Center(child: Text('Recovered camera'));
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('An Error Occurred'), findsOneWidget);
      expect(find.textContaining('Camera error:'), findsOneWidget);
      expect(find.textContaining('camera unavailable'), findsOneWidget);

      shouldThrow = false;
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.text('Recovered camera'), findsOneWidget);
      expect(find.text('An Error Occurred'), findsNothing);
    });
  });
}

Widget _harness() {
  return MaterialApp(
    home: YoloDebugScreen(
      cameraBuilder: (context, detectionMode, cameraMode, onDetection) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fake camera: ${cameraMode.name}'),
              Text('Detection mode: ${detectionMode.name}'),
              ElevatedButton(
                onPressed: () {
                  onDetection([
                    DetectionResult(
                      label: 'banana',
                      confidence: 0.88,
                      bbox: const [0.1, 0.2, 0.3, 0.4],
                    ),
                  ]);
                },
                child: const Text('Emit detection'),
              ),
            ],
          ),
        );
      },
    ),
  );
}
