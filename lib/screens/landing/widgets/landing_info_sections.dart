import 'package:flowfit/screens/landing/widgets/landing_theme.dart';
import 'package:flutter/material.dart';

class LandingPlatformStrip extends StatelessWidget {
  const LandingPlatformStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        alignment: WrapAlignment.center,
        children: [
          LandingPlatformItem(
            icon: Icons.watch_rounded,
            title: 'Watch sessions',
            body: 'Capture pulse and workout moments from Wear OS.',
            color: LandingPalette.blue,
          ),
          LandingPlatformItem(
            icon: Icons.phone_android_rounded,
            title: 'Phone companion',
            body: 'Review progress, goals, and settings on Android.',
            color: LandingPalette.green,
          ),
          LandingPlatformItem(
            icon: Icons.public_rounded,
            title: 'Web preview',
            body: 'Open the app in a browser before installing.',
            color: LandingPalette.red,
          ),
        ],
      ),
    );
  }
}

class LandingPlatformItem extends StatelessWidget {
  const LandingPlatformItem({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 348,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: LandingPalette.line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: LandingPalette.ink,
                        fontFamily: 'GeneralSans',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: const TextStyle(
                        color: LandingPalette.muted,
                        fontFamily: 'GeneralSans',
                        fontSize: 14,
                        height: 1.35,
                        letterSpacing: 0,
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

class LandingFeatureSection extends StatelessWidget {
  const LandingFeatureSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const LandingSectionBlock(
      eyebrow: 'What FlowFit connects',
      title: 'A simple loop for movement, recovery, and progress.',
      body:
          'Try the browser app, install the APK, and understand the watch-plus-phone flow in one pass.',
      children: [
        LandingFeatureBand(
          icon: Icons.monitor_heart_rounded,
          title: 'Heart-rate and sensor moments',
          body:
              'Designed around Wear OS sessions, live pulse readings, and workout context that moves with the user.',
          color: LandingPalette.red,
        ),
        LandingFeatureBand(
          icon: Icons.fitness_center_rounded,
          title: 'Workout paths without heavy setup',
          body:
              'Running, walking, resistance, and wellness surfaces stay close to the daily actions people expect.',
          color: LandingPalette.blue,
        ),
        LandingFeatureBand(
          icon: Icons.auto_awesome_rounded,
          title: 'Buddy and wellness motivation',
          body:
              'Companion progress, mood checks, and wellness missions give the app a warmer reason to come back.',
          color: LandingPalette.green,
        ),
      ],
    );
  }
}

class LandingHowItWorksSection extends StatelessWidget {
  const LandingHowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const LandingSectionBlock(
      eyebrow: 'How it works',
      title: 'Try it first, then install when the device flow matters.',
      body:
          'Start fast in the browser, then move to Android and Wear OS when device-connected testing matters.',
      children: [
        LandingStepRow(
          number: '01',
          title: 'Open the web app',
          body:
              'Use the browser preview to see onboarding, goals, settings, and core workout routes.',
        ),
        LandingStepRow(
          number: '02',
          title: 'Install the APK',
          body:
              'Move to Android when you want native device permissions, phone companion features, and watch pairing.',
        ),
        LandingStepRow(
          number: '03',
          title: 'Pair the watch path',
          body:
              'Use the Wear OS build for focused heart-rate, workout, and relax tools on the wrist.',
        ),
      ],
    );
  }
}

class LandingSectionBlock extends StatelessWidget {
  const LandingSectionBlock({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.children,
  });

  final String eyebrow;
  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 860;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Flex(
        direction: isWide ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isWide ? 5 : 0,
            child: LandingSectionHeader(
              eyebrow: eyebrow,
              title: title,
              body: body,
            ),
          ),
          SizedBox(width: isWide ? 56 : 0, height: isWide ? 0 : 28),
          Expanded(
            flex: isWide ? 7 : 0,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class LandingSectionHeader extends StatelessWidget {
  const LandingSectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            color: LandingPalette.blueDeep,
            fontFamily: 'GeneralSans',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: textTheme.headlineMedium?.copyWith(
            color: LandingPalette.ink,
            fontFamily: 'GeneralSans',
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          body,
          style: textTheme.bodyLarge?.copyWith(
            color: LandingPalette.muted,
            fontFamily: 'GeneralSans',
            height: 1.45,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class LandingFeatureBand extends StatelessWidget {
  const LandingFeatureBand({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: LandingPalette.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: LandingPalette.ink,
                      fontFamily: 'GeneralSans',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: const TextStyle(
                      color: LandingPalette.muted,
                      fontFamily: 'GeneralSans',
                      fontSize: 15,
                      height: 1.45,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LandingStepRow extends StatelessWidget {
  const LandingStepRow({
    super.key,
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: LandingPalette.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: LandingPalette.blueDeep,
                  fontFamily: 'GeneralSans',
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: LandingPalette.ink,
                      fontFamily: 'GeneralSans',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: const TextStyle(
                      color: LandingPalette.muted,
                      fontFamily: 'GeneralSans',
                      fontSize: 15,
                      height: 1.45,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
