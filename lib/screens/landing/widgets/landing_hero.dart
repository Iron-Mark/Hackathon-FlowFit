import 'package:flowfit/screens/landing/widgets/landing_device_preview.dart';
import 'package:flowfit/screens/landing/widgets/landing_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LandingHero extends StatelessWidget {
  const LandingHero({
    super.key,
    required this.onOpenApp,
    required this.onDownloadApk,
  });

  final VoidCallback onOpenApp;
  final VoidCallback onDownloadApk;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 920;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, isWide ? 44 : 22, 0, 34),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            right: isWide ? -60 : -120,
            top: isWide ? -18 : 190,
            child: Opacity(
              opacity: isWide ? 0.28 : 0.18,
              child: SvgPicture.asset(
                'assets/images/onboarding_hero.svg',
                width: isWide ? 560 : 460,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 52 : 22,
              vertical: isWide ? 54 : 32,
            ),
            child: Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: isWide
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isWide ? 11 : 0,
                  child: LandingHeroCopy(
                    onOpenApp: onOpenApp,
                    onDownloadApk: onDownloadApk,
                  ),
                ),
                SizedBox(width: isWide ? 42 : 0, height: isWide ? 0 : 28),
                Expanded(
                  flex: isWide ? 8 : 0,
                  child: const LandingDevicePreview(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LandingHeroCopy extends StatelessWidget {
  const LandingHeroCopy({
    super.key,
    required this.onOpenApp,
    required this.onDownloadApk,
  });

  final VoidCallback onOpenApp;
  final VoidCallback onDownloadApk;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LandingPill(
          icon: Icons.watch_rounded,
          label: 'Wear OS, Android, and web',
          color: LandingPalette.green,
        ),
        const SizedBox(height: 22),
        Text(
          'FlowFit',
          style: textTheme.displayLarge?.copyWith(
            color: LandingPalette.ink,
            fontFamily: 'GeneralSans',
            fontWeight: FontWeight.w800,
            fontSize: 64,
            height: 0.95,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'A fitness buddy that makes healthy habits stick for kids — heart-rate sessions from the watch, whole-day tracking on the phone, one companion in front of it all.',
            style: textTheme.titleLarge?.copyWith(
              color: LandingPalette.muted,
              fontFamily: 'GeneralSans',
              fontWeight: FontWeight.w500,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onOpenApp,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Try Web App'),
              style: landingPrimaryButtonStyle(),
            ),
            OutlinedButton.icon(
              onPressed: onDownloadApk,
              icon: const Icon(Icons.android_rounded),
              label: const Text('Download APK'),
              style: landingSecondaryButtonStyle(),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            LandingSignal(
              label: 'Heart-rate tracking',
              color: LandingPalette.red,
            ),
            LandingSignal(label: 'Workout flows', color: LandingPalette.blue),
            LandingSignal(
              label: 'Wellness missions',
              color: LandingPalette.green,
            ),
          ],
        ),
      ],
    );
  }
}

class LandingPill extends StatelessWidget {
  const LandingPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LandingPalette.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            Text(
              label,
              style: const TextStyle(
                color: LandingPalette.ink,
                fontFamily: 'GeneralSans',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LandingSignal extends StatelessWidget {
  const LandingSignal({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: LandingPalette.muted,
            fontFamily: 'GeneralSans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
