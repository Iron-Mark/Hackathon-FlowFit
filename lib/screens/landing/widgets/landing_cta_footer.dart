import 'package:flowfit/screens/landing/widgets/landing_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LandingTopNav extends StatelessWidget {
  const LandingTopNav({super.key, required this.onOpenApp});

  final VoidCallback onOpenApp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/flowfit_logo_header.svg',
            height: 32,
            semanticsLabel: 'FlowFit',
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onOpenApp,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Open App'),
          ),
        ],
      ),
    );
  }
}

class LandingDownloadSection extends StatelessWidget {
  const LandingDownloadSection({
    super.key,
    required this.onOpenApp,
    required this.onDownloadApk,
  });

  final VoidCallback onOpenApp;
  final VoidCallback onDownloadApk;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: LandingPalette.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: EdgeInsets.all(isWide ? 34 : 22),
          child: Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: isWide
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: isWide ? 6 : 0,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start in the browser or install the APK.',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'GeneralSans',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'The web app is the quickest preview. The APK is for native Android and device-connected testing.',
                      style: TextStyle(
                        color: Color(0xFFC7D4E7),
                        fontFamily: 'GeneralSans',
                        fontSize: 16,
                        height: 1.45,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isWide ? 32 : 0, height: isWide ? 0 : 22),
              Expanded(
                flex: isWide ? 4 : 0,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: isWide ? WrapAlignment.end : WrapAlignment.start,
                  children: [
                    FilledButton.icon(
                      onPressed: onOpenApp,
                      icon: const Icon(Icons.public_rounded),
                      label: const Text('Try Web App'),
                      style: landingPrimaryButtonStyle(
                        background: Colors.white,
                        foreground: LandingPalette.ink,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onDownloadApk,
                      icon: const Icon(Icons.android_rounded),
                      label: const Text('Download APK'),
                      style: landingSecondaryButtonStyle(
                        foreground: Colors.white,
                        side: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LandingFooter extends StatelessWidget {
  const LandingFooter({
    super.key,
    required this.onPrivacy,
    required this.onAccountDeletion,
    required this.onCaseStudy,
    required this.onMoreApps,
  });

  final VoidCallback onPrivacy;
  final VoidCallback onAccountDeletion;
  final VoidCallback onCaseStudy;
  final VoidCallback onMoreApps;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 620;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 36),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: isNarrow ? double.infinity : 360,
            child: const Text(
              'Parent-supervised kids fitness for Wear OS and Android.',
              style: TextStyle(
                color: LandingPalette.muted,
                fontFamily: 'GeneralSans',
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
          TextButton(onPressed: onPrivacy, child: const Text('Privacy')),
          TextButton(
            onPressed: onAccountDeletion,
            child: const Text('Account deletion'),
          ),
          TextButton(onPressed: onCaseStudy, child: const Text('Case study')),
          TextButton(onPressed: onMoreApps, child: const Text('More apps')),
        ],
      ),
    );
  }
}
