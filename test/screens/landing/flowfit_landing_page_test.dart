import 'package:flowfit/core/config/flowfit_runtime_config.dart';
import 'package:flowfit/screens/landing/flowfit_landing_page.dart';
import 'package:flowfit/screens/landing/widgets/landing_cta_footer.dart';
import 'package:flowfit/screens/landing/widgets/landing_hero.dart';
import 'package:flowfit/screens/landing/widgets/landing_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('landing page renders concise marketing content and CTAs', (
    tester,
  ) async {
    await _pumpLanding(tester);

    expect(find.text('FlowFit'), findsWidgets);
    expect(find.textContaining('parent or guardian'), findsWidgets);
    expect(
      find.textContaining('A fitness buddy for families.'),
      findsOneWidget,
    );
    expect(find.text('Try Web App'), findsWidgets);
    expect(find.text('Download APK'), findsWidgets);
    expect(find.text('What FlowFit connects'.toUpperCase()), findsOneWidget);
    expect(find.text('How it works'.toUpperCase()), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Account deletion'), findsOneWidget);

    // The extracted landing widgets stay composed into the shell page.
    expect(find.byType(LandingTopNav), findsOneWidget);
    expect(find.byType(LandingHero), findsOneWidget);
    expect(find.byType(LandingDownloadSection), findsOneWidget);
    expect(find.byType(LandingFooter), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      LandingPalette.paper,
    );
  });

  testWidgets('Try Web App opens the app startup route', (tester) async {
    await _pumpLanding(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Try Web App').first);
    await tester.pumpAndSettle();

    expect(find.text('app startup route'), findsOneWidget);
  });

  testWidgets('Download APK and compliance links launch configured URLs', (
    tester,
  ) async {
    final launchedUris = <Uri>[];
    await _pumpLanding(
      tester,
      launchExternalUrl: (uri) async {
        launchedUris.add(uri);
        return true;
      },
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Download APK').first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Privacy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Account deletion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account deletion'));
    await tester.pumpAndSettle();

    expect(
      launchedUris,
      containsAll(<Uri>[
        Uri.parse(FlowFitRuntimeConfig.apkDownloadUrl),
        Uri.parse('${FlowFitRuntimeConfig.publicWebBaseUrl}/privacy.html'),
        Uri.parse(
          '${FlowFitRuntimeConfig.publicWebBaseUrl}/account-deletion.html',
        ),
      ]),
    );
  });

  testWidgets('landing page stays scrollable on a compact mobile viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpLanding(tester);

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.text('Parent-supervised kids fitness for Wear OS and Android.'),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Parent-supervised kids fitness for Wear OS and Android.'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpLanding(
  WidgetTester tester, {
  ExternalUrlLauncher? launchExternalUrl,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      routes: {'/app': (_) => const Scaffold(body: Text('app startup route'))},
      home: FlowFitLandingPage(launchExternalUrl: launchExternalUrl),
    ),
  );
  await tester.pumpAndSettle();
}
