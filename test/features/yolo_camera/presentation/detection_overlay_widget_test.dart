import 'package:flowfit/features/yolo_camera/domain/entities/detection_result.dart';
import 'package:flowfit/features/yolo_camera/presentation/widgets/detection_overlay_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('detection overlay renders with no results', (tester) async {
    await tester.pumpWidget(
      _harness(const DetectionOverlayWidget(results: [])),
    );

    expect(find.byType(DetectionOverlayWidget), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detection overlay paints boxes and keypoints without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        DetectionOverlayWidget(
          results: [
            DetectionResult(
              label: 'runner',
              confidence: 0.94,
              bbox: [0.1, 0.2, 0.6, 0.8],
              keypoints: [
                [0.2, 0.3],
                [0.4, 0.5],
              ],
            ),
          ],
        ),
      ),
    );

    expect(find.byType(DetectionOverlayWidget), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Widget _harness(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 320, height: 480, child: child)),
  );
}
