import 'package:flutter/material.dart';

/// Shared palette and layout constants for the FlowFit landing page.
class LandingPalette {
  const LandingPalette._();

  static const Color ink = Color(0xFF102033);
  static const Color muted = Color(0xFF526070);
  static const Color blue = Color(0xFF3183E8);
  static const Color blueDeep = Color(0xFF174EA6);
  static const Color green = Color(0xFF36A766);
  static const Color red = Color(0xFFE94C3D);
  static const Color yellow = Color(0xFFF3C743);
  static const Color paper = Color(0xFFF7FAFE);
  static const Color line = Color(0xFFD9E5F2);
  static const double maxWidth = 1160;
}

ButtonStyle landingPrimaryButtonStyle({
  Color background = LandingPalette.blueDeep,
  Color foreground = Colors.white,
}) {
  return FilledButton.styleFrom(
    backgroundColor: background,
    foregroundColor: foreground,
    minimumSize: const Size(148, 52),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    textStyle: const TextStyle(
      fontFamily: 'GeneralSans',
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}

ButtonStyle landingSecondaryButtonStyle({
  Color foreground = LandingPalette.ink,
  Color side = LandingPalette.line,
}) {
  return OutlinedButton.styleFrom(
    foregroundColor: foreground,
    side: BorderSide(color: side),
    minimumSize: const Size(154, 52),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    textStyle: const TextStyle(
      fontFamily: 'GeneralSans',
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}
