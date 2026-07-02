import 'package:flowfit/core/config/flowfit_runtime_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

class FlowFitLandingPage extends StatelessWidget {
  const FlowFitLandingPage({super.key, this.launchExternalUrl});

  final ExternalUrlLauncher? launchExternalUrl;

  static const Color _ink = Color(0xFF102033);
  static const Color _muted = Color(0xFF526070);
  static const Color _blue = Color(0xFF3183E8);
  static const Color _blueDeep = Color(0xFF174EA6);
  static const Color _green = Color(0xFF36A766);
  static const Color _red = Color(0xFFE94C3D);
  static const Color _yellow = Color(0xFFF3C743);
  static const Color _paper = Color(0xFFF7FAFE);
  static const Color _line = Color(0xFFD9E5F2);
  static const double _maxWidth = 1160;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _PageShell(child: _TopNav(onOpenApp: () => _openWebApp(context))),
              _PageShell(
                child: _Hero(
                  onOpenApp: () => _openWebApp(context),
                  onDownloadApk: () => _openExternalLink(
                    context,
                    Uri.parse(FlowFitRuntimeConfig.apkDownloadUrl),
                  ),
                ),
              ),
              const _PageShell(child: _PlatformStrip()),
              const _PageShell(child: _FeatureSection()),
              const _PageShell(child: _HowItWorksSection()),
              _PageShell(
                child: _DownloadSection(
                  onOpenApp: () => _openWebApp(context),
                  onDownloadApk: () => _openExternalLink(
                    context,
                    Uri.parse(FlowFitRuntimeConfig.apkDownloadUrl),
                  ),
                ),
              ),
              _PageShell(
                child: _Footer(
                  onPrivacy: () => _openExternalLink(
                    context,
                    _publicPageUri('privacy.html'),
                  ),
                  onAccountDeletion: () => _openExternalLink(
                    context,
                    _publicPageUri('account-deletion.html'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openWebApp(BuildContext context) {
    Navigator.of(context).pushNamed('/app');
  }

  Future<void> _openExternalLink(BuildContext context, Uri uri) async {
    final launcher = launchExternalUrl ?? _launchExternalUrl;
    final launched = await launcher(uri);

    if (!context.mounted || launched) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not open ${uri.toString()}')));
  }

  Uri _publicPageUri(String path) {
    final normalizedBase = FlowFitRuntimeConfig.publicWebBaseUrl.endsWith('/')
        ? FlowFitRuntimeConfig.publicWebBaseUrl
        : '${FlowFitRuntimeConfig.publicWebBaseUrl}/';
    return Uri.parse(normalizedBase).resolve(path);
  }

  static Future<bool> _launchExternalUrl(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _PageShell extends StatelessWidget {
  const _PageShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: FlowFitLandingPage._maxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: child,
        ),
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({required this.onOpenApp});

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

class _Hero extends StatelessWidget {
  const _Hero({required this.onOpenApp, required this.onDownloadApk});

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
                  child: _HeroCopy(
                    onOpenApp: onOpenApp,
                    onDownloadApk: onDownloadApk,
                  ),
                ),
                SizedBox(width: isWide ? 42 : 0, height: isWide ? 0 : 28),
                Expanded(flex: isWide ? 8 : 0, child: const _DevicePreview()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onOpenApp, required this.onDownloadApk});

  final VoidCallback onOpenApp;
  final VoidCallback onDownloadApk;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Pill(
          icon: Icons.watch_rounded,
          label: 'Wear OS, Android, and web',
          color: FlowFitLandingPage._green,
        ),
        const SizedBox(height: 22),
        Text(
          'FlowFit',
          style: textTheme.displayLarge?.copyWith(
            color: FlowFitLandingPage._ink,
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
            'A fitness companion for heart-rate sessions, workout tracking, wellness missions, and buddy progress across watch, phone, and browser.',
            style: textTheme.titleLarge?.copyWith(
              color: FlowFitLandingPage._muted,
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
              style: _primaryButtonStyle(),
            ),
            OutlinedButton.icon(
              onPressed: onDownloadApk,
              icon: const Icon(Icons.android_rounded),
              label: const Text('Download APK'),
              style: _secondaryButtonStyle(),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Signal(
              label: 'Heart-rate tracking',
              color: FlowFitLandingPage._red,
            ),
            _Signal(label: 'Workout flows', color: FlowFitLandingPage._blue),
            _Signal(
              label: 'Wellness missions',
              color: FlowFitLandingPage._green,
            ),
          ],
        ),
      ],
    );
  }
}

class _DevicePreview extends StatelessWidget {
  const _DevicePreview();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 520;

    return AspectRatio(
      aspectRatio: isCompact ? 0.76 : 1.04,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFC8DAF1)),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A174EA6),
                    blurRadius: 30,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(22),
                child: _ProgressPanel(),
              ),
            ),
          ),
          const Positioned(right: -8, bottom: 18, child: _WatchFace()),
          Positioned(
            left: 22,
            bottom: -18,
            child: Container(
              width: 178,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: FlowFitLandingPage._ink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_rounded, color: FlowFitLandingPage._red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '72 BPM synced',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'GeneralSans',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.directions_run_rounded, color: FlowFitLandingPage._blue),
            SizedBox(width: 8),
            Text(
              'Today',
              style: TextStyle(
                color: FlowFitLandingPage._ink,
                fontFamily: 'GeneralSans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _MetricRow(
          label: 'Active minutes',
          value: '42',
          percent: 0.72,
          color: FlowFitLandingPage._blue,
        ),
        const SizedBox(height: 18),
        const _MetricRow(
          label: 'Workout effort',
          value: '6.8',
          percent: 0.58,
          color: FlowFitLandingPage._red,
        ),
        const SizedBox(height: 18),
        const _MetricRow(
          label: 'Recovery check',
          value: 'Good',
          percent: 0.82,
          color: FlowFitLandingPage._green,
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 86,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7D6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: FlowFitLandingPage._yellow,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 86,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F8EF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.park_rounded,
                  color: FlowFitLandingPage._green,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  final String label;
  final String value;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: FlowFitLandingPage._muted,
                  fontFamily: 'GeneralSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: FlowFitLandingPage._ink,
                fontFamily: 'GeneralSans',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            color: color,
            backgroundColor: const Color(0xFFE6EDF7),
          ),
        ),
      ],
    );
  }
}

class _WatchFace extends StatelessWidget {
  const _WatchFace();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      height: 126,
      decoration: BoxDecoration(
        color: FlowFitLandingPage._ink,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24102033),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_rounded,
            color: FlowFitLandingPage._red,
            size: 24,
          ),
          SizedBox(height: 6),
          Text(
            '72',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'GeneralSans',
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'BPM',
            style: TextStyle(
              color: Color(0xFFB7C8DD),
              fontFamily: 'GeneralSans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformStrip extends StatelessWidget {
  const _PlatformStrip();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        alignment: WrapAlignment.center,
        children: [
          _PlatformItem(
            icon: Icons.watch_rounded,
            title: 'Watch sessions',
            body: 'Capture pulse and workout moments from Wear OS.',
            color: FlowFitLandingPage._blue,
          ),
          _PlatformItem(
            icon: Icons.phone_android_rounded,
            title: 'Phone companion',
            body: 'Review progress, goals, and settings on Android.',
            color: FlowFitLandingPage._green,
          ),
          _PlatformItem(
            icon: Icons.public_rounded,
            title: 'Web preview',
            body: 'Open the app in a browser before installing.',
            color: FlowFitLandingPage._red,
          ),
        ],
      ),
    );
  }
}

class _PlatformItem extends StatelessWidget {
  const _PlatformItem({
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
          border: Border.all(color: FlowFitLandingPage._line),
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
                        color: FlowFitLandingPage._ink,
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
                        color: FlowFitLandingPage._muted,
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

class _FeatureSection extends StatelessWidget {
  const _FeatureSection();

  @override
  Widget build(BuildContext context) {
    return const _SectionBlock(
      eyebrow: 'What FlowFit connects',
      title: 'A simple loop for movement, recovery, and progress.',
      body:
          'Try the browser app, install the APK, and understand the watch-plus-phone flow in one pass.',
      children: [
        _FeatureBand(
          icon: Icons.monitor_heart_rounded,
          title: 'Heart-rate and sensor moments',
          body:
              'Designed around Wear OS sessions, live pulse readings, and workout context that moves with the user.',
          color: FlowFitLandingPage._red,
        ),
        _FeatureBand(
          icon: Icons.fitness_center_rounded,
          title: 'Workout paths without heavy setup',
          body:
              'Running, walking, resistance, and wellness surfaces stay close to the daily actions people expect.',
          color: FlowFitLandingPage._blue,
        ),
        _FeatureBand(
          icon: Icons.auto_awesome_rounded,
          title: 'Buddy and wellness motivation',
          body:
              'Companion progress, mood checks, and wellness missions give the app a warmer reason to come back.',
          color: FlowFitLandingPage._green,
        ),
      ],
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return const _SectionBlock(
      eyebrow: 'How it works',
      title: 'Try it first, then install when the device flow matters.',
      body:
          'Start fast in the browser, then move to Android and Wear OS when device-connected testing matters.',
      children: [
        _StepRow(
          number: '01',
          title: 'Open the web app',
          body:
              'Use the browser preview to see onboarding, goals, settings, and core workout routes.',
        ),
        _StepRow(
          number: '02',
          title: 'Install the APK',
          body:
              'Move to Android when you want native device permissions, phone companion features, and watch pairing.',
        ),
        _StepRow(
          number: '03',
          title: 'Pair the watch path',
          body:
              'Use the Wear OS build for focused heart-rate, workout, and relax tools on the wrist.',
        ),
      ],
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
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
            child: _SectionHeader(eyebrow: eyebrow, title: title, body: body),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
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
            color: FlowFitLandingPage._blueDeep,
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
            color: FlowFitLandingPage._ink,
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
            color: FlowFitLandingPage._muted,
            fontFamily: 'GeneralSans',
            height: 1.45,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _FeatureBand extends StatelessWidget {
  const _FeatureBand({
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
        border: Border(top: BorderSide(color: FlowFitLandingPage._line)),
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
                      color: FlowFitLandingPage._ink,
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
                      color: FlowFitLandingPage._muted,
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

class _StepRow extends StatelessWidget {
  const _StepRow({
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
        border: Border(top: BorderSide(color: FlowFitLandingPage._line)),
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
                  color: FlowFitLandingPage._blueDeep,
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
                      color: FlowFitLandingPage._ink,
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
                      color: FlowFitLandingPage._muted,
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

class _DownloadSection extends StatelessWidget {
  const _DownloadSection({
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
          color: FlowFitLandingPage._ink,
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
                      style: _primaryButtonStyle(
                        background: Colors.white,
                        foreground: FlowFitLandingPage._ink,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onDownloadApk,
                      icon: const Icon(Icons.android_rounded),
                      label: const Text('Download APK'),
                      style: _secondaryButtonStyle(
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

class _Footer extends StatelessWidget {
  const _Footer({required this.onPrivacy, required this.onAccountDeletion});

  final VoidCallback onPrivacy;
  final VoidCallback onAccountDeletion;

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
              'FlowFit prototype release surface',
              style: TextStyle(
                color: FlowFitLandingPage._muted,
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
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FlowFitLandingPage._line),
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
                color: FlowFitLandingPage._ink,
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

class _Signal extends StatelessWidget {
  const _Signal({required this.label, required this.color});

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
            color: FlowFitLandingPage._muted,
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

ButtonStyle _primaryButtonStyle({
  Color background = FlowFitLandingPage._blue,
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

ButtonStyle _secondaryButtonStyle({
  Color foreground = FlowFitLandingPage._ink,
  Color side = FlowFitLandingPage._line,
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
