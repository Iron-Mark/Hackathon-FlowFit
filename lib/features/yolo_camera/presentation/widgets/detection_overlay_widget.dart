import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/entities/detection_result.dart';

class DetectionOverlayWidget extends StatelessWidget {
  final List<DetectionResult> results;
  const DetectionOverlayWidget({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _DetectionPainter(results),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final List<DetectionResult> results;

  _DetectionPainter(this.results);

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate scaling factors
    // Camera preview size might be different from screen size
    // We assume the preview covers the screen (BoxFit.cover) or fits (BoxFit.contain)
    // For simplicity, let's assume the coordinates are normalized [0,1] from the detector
    // If they are absolute pixels from the image, we need to scale.
    // Let's assume normalized for now as it's cleaner, or we scale based on previewSize.

    // NOTE: YOLO usually returns absolute coordinates relative to the image size.
    // We need to know the image size used for detection.
    // For now, we'll assume the results are scaled to the previewSize or we just draw them.

    final Paint boxPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint textBgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    const textStyle = TextStyle(color: Colors.white, fontSize: 12.0);

    for (var result in results) {
      // Bounding Box
      // Assuming bbox is [x, y, w, h] normalized or absolute.
      // Let's assume absolute for now relative to previewSize.
      // If it's normalized, we multiply by size.width/height.

      // Let's assume the bbox is [x1, y1, x2, y2] normalized [0..1]
      final rect = Rect.fromLTRB(
        result.bbox[0] * size.width,
        result.bbox[1] * size.height,
        result.bbox[2] * size.width,
        result.bbox[3] * size.height,
      );

      canvas.drawRect(rect, boxPaint);

      // Label
      final textSpan = TextSpan(
        text:
            '${result.label} ${(result.confidence * 100).toStringAsFixed(0)}%',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Draw label background
      final offset = Offset(rect.left, rect.top - textPainter.height);
      canvas.drawRect(
        Rect.fromLTWH(
          offset.dx,
          offset.dy,
          textPainter.width + 4,
          textPainter.height,
        ),
        textBgPaint,
      );
      textPainter.paint(canvas, offset + const Offset(2, 0));

      // Keypoints (if any)
      if (result.keypoints != null) {
        final pointPaint = Paint()
          ..color = Colors.yellow
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round;

        for (var point in result.keypoints!) {
          // Assuming point is [x, y] normalized
          if (point.length >= 2) {
            canvas.drawPoints(PointMode.points, [
              Offset(point[0] * size.width, point[1] * size.height),
            ], pointPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
