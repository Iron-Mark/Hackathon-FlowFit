import 'package:flowfit/core/config/flowfit_runtime_config.dart';
import 'package:flowfit/screens/landing/widgets/landing_cta_footer.dart';
import 'package:flowfit/screens/landing/widgets/landing_hero.dart';
import 'package:flowfit/screens/landing/widgets/landing_info_sections.dart';
import 'package:flowfit/screens/landing/widgets/landing_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

class FlowFitLandingPage extends StatelessWidget {
  const FlowFitLandingPage({super.key, this.launchExternalUrl});

  final ExternalUrlLauncher? launchExternalUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandingPalette.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _PageShell(
                child: LandingTopNav(onOpenApp: () => _openWebApp(context)),
              ),
              _PageShell(
                child: LandingHero(
                  onOpenApp: () => _openWebApp(context),
                  onDownloadApk: () => _openExternalLink(
                    context,
                    Uri.parse(FlowFitRuntimeConfig.apkDownloadUrl),
                  ),
                ),
              ),
              const _PageShell(child: LandingPlatformStrip()),
              const _PageShell(child: LandingFeatureSection()),
              const _PageShell(child: LandingHowItWorksSection()),
              _PageShell(
                child: LandingDownloadSection(
                  onOpenApp: () => _openWebApp(context),
                  onDownloadApk: () => _openExternalLink(
                    context,
                    Uri.parse(FlowFitRuntimeConfig.apkDownloadUrl),
                  ),
                ),
              ),
              _PageShell(
                child: LandingFooter(
                  onPrivacy: () => _openExternalLink(
                    context,
                    _publicPageUri('privacy.html'),
                  ),
                  onAccountDeletion: () => _openExternalLink(
                    context,
                    _publicPageUri('account-deletion.html'),
                  ),
                  onCaseStudy: () => _openExternalLink(
                    context,
                    Uri.parse('https://www.marksiazon.dev/projects/flowfit'),
                  ),
                  onMoreApps: () => _openExternalLink(
                    context,
                    Uri.parse('https://apps.marksiazon.dev/flowfit/'),
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
        constraints: const BoxConstraints(maxWidth: LandingPalette.maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: child,
        ),
      ),
    );
  }
}
