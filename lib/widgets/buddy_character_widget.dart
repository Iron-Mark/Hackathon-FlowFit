import 'package:flutter/material.dart';

/// A widget that renders the Buddy character with a blob/bean shape
/// and simple facial features (eyes, beak/smile, rosy cheeks).
///
/// The Buddy character is designed to be minimalist, gender-neutral,
/// and friendly, inspired by successful self-care apps.
class BuddyCharacterWidget extends StatelessWidget {
  /// The color of the Buddy character
  final Color color;

  /// The size of the Buddy character (width and height)
  final double size;

  /// Whether to show the face (eyes, beak, cheeks)
  final bool showFace;

  const BuddyCharacterWidget({
    super.key,
    required this.color,
    this.size = 160.0,
    this.showFace = true,
  });

  @override
  Widget build(BuildContext context) {
    // Get color name for accessibility
    final colorName = _getColorName(color);

    return Semantics(
      label: 'Buddy character in $colorName color',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _BuddyPainter(color: color, showFace: showFace),
        ),
      ),
    );
  }

  /// Helper method to get a friendly color name for accessibility
  String _getColorName(Color color) {
    // Map common Buddy colors to friendly names
    if (color == const Color(0xFF4ECDC4)) return 'ocean blue';
    if (color == const Color(0xFF26A69A)) return 'teal';
    if (color == const Color(0xFF66BB6A)) return 'green';
    if (color == const Color(0xFF9575CD)) return 'purple';
    if (color == const Color(0xFFFFD54F)) return 'yellow';
    if (color == const Color(0xFFFFB74D)) return 'orange';
    if (color == const Color(0xFFF06292)) return 'pink';
    if (color == const Color(0xFF90A4AE)) return 'gray';

    // Default description
    return 'colorful';
  }
}

/// Custom painter for the Buddy character
class _BuddyPainter extends CustomPainter {
  final Color color;
  final bool showFace;

  _BuddyPainter({required this.color, required this.showFace});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw blob/bean shape using a rounded rectangle with asymmetric curves
    final blobPath = Path();
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Create a blob shape by drawing an oval with slight asymmetry
    blobPath.addRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.45)),
    );

    canvas.drawPath(blobPath, paint);

    // Draw face if enabled
    if (showFace) {
      _drawFace(canvas, size);
    }
  }

  void _drawFace(Canvas canvas, Size size) {
    final eyePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final cheekPaint = Paint()
      ..color = Colors.pink.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    // Eye size: 8x8 circles
    const eyeRadius = 4.0;

    // Left eye position (slightly left of center, upper third)
    final leftEyeX = size.width * 0.35;
    final leftEyeY = size.height * 0.38;

    // Right eye position (slightly right of center, upper third)
    final rightEyeX = size.width * 0.65;
    final rightEyeY = size.height * 0.38;

    // Draw eyes
    canvas.drawCircle(Offset(leftEyeX, leftEyeY), eyeRadius, eyePaint);
    canvas.drawCircle(Offset(rightEyeX, rightEyeY), eyeRadius, eyePaint);

    // Draw small beak/smile (small arc)
    final beakPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final beakPath = Path();
    final beakCenterX = size.width * 0.5;
    final beakCenterY = size.height * 0.55;
    final beakWidth = size.width * 0.15;

    // Draw a small smile arc
    beakPath.moveTo(beakCenterX - beakWidth / 2, beakCenterY);
    beakPath.quadraticBezierTo(
      beakCenterX,
      beakCenterY + beakWidth / 3,
      beakCenterX + beakWidth / 2,
      beakCenterY,
    );

    canvas.drawPath(beakPath, beakPaint);

    // Rosy cheeks: 12x12 circles
    const cheekRadius = 6.0;

    // Left cheek position (below and to the left of left eye)
    final leftCheekX = size.width * 0.25;
    final leftCheekY = size.height * 0.52;

    // Right cheek position (below and to the right of right eye)
    final rightCheekX = size.width * 0.75;
    final rightCheekY = size.height * 0.52;

    // Draw rosy cheeks
    canvas.drawCircle(Offset(leftCheekX, leftCheekY), cheekRadius, cheekPaint);
    canvas.drawCircle(
      Offset(rightCheekX, rightCheekY),
      cheekRadius,
      cheekPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BuddyPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.showFace != showFace;
  }
}
