import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String gradleBuild;
  late String releasePreflight;
  late String storeReleaseBuild;
  late String readinessAudit;
  late String supabaseConfig;
  late String releaseEnvExample;
  late String configureLocalRelease;
  late String webDeploymentVerifier;
  late String storeSubmissionChecklist;
  late String ciWorkflow;
  late String pagesWorkflow;
  late String copilotInstructions;
  late String androidMainManifest;
  late String androidDebugManifest;
  late String iosInfoPlist;
  late String androidMainActivity;
  late List<String> androidKotlinSources;

  setUpAll(() {
    gradleBuild = File('android/app/build.gradle.kts').readAsStringSync();
    releasePreflight = File('scripts/release_preflight.ps1').readAsStringSync();
    storeReleaseBuild = File(
      'scripts/store_release_build.ps1',
    ).readAsStringSync();
    readinessAudit = File(
      'scripts/release_readiness_audit.ps1',
    ).readAsStringSync();
    supabaseConfig = File('supabase/config.toml').readAsStringSync();
    releaseEnvExample = File('.env.release.example').readAsStringSync();
    configureLocalRelease = File(
      'scripts/configure_local_release.ps1',
    ).readAsStringSync();
    webDeploymentVerifier = File(
      'scripts/verify_web_deployment.ps1',
    ).readAsStringSync();
    storeSubmissionChecklist = File(
      'docs/STORE_SUBMISSION_CHECKLIST.md',
    ).readAsStringSync();
    ciWorkflow = File('.github/workflows/flutter-ci.yml').readAsStringSync();
    final pagesWorkflowFile = File('.github/workflows/flutter-web-pages.yml');
    pagesWorkflow = pagesWorkflowFile.existsSync()
        ? pagesWorkflowFile.readAsStringSync()
        : '';
    copilotInstructions = File(
      '.github/copilot-instructions.md',
    ).readAsStringSync();
    androidMainManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    androidDebugManifest = File(
      'android/app/src/debug/AndroidManifest.xml',
    ).readAsStringSync();
    iosInfoPlist = File('ios/Runner/Info.plist').readAsStringSync();
    androidMainActivity = File(
      'android/app/src/main/kotlin/com/oldstlabs/flowfit/MainActivity.kt',
    ).readAsStringSync();
    androidKotlinSources = Directory('android/app/src/main/kotlin')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.kt'))
        .map((file) => file.readAsStringSync())
        .toList();
  });

  test('Gradle signed release guard rejects smoke and placeholder IDs', () {
    expect(gradleBuild, contains('isProductionShapedFlowFitValue'));
    expect(gradleBuild, contains('com.flowfit.smoke'));
    expect(gradleBuild, contains('com.yourcompany.'));
    expect(gradleBuild, contains('flowfitDevAuthScheme'));
  });

  test('Android native namespace uses maintained fork package', () {
    expect(gradleBuild, contains('namespace = "com.oldstlabs.flowfit"'));
    expect(gradleBuild, contains('.orElse("com.oldstlabs.flowfit")'));
    expect(gradleBuild, isNot(contains('namespace = "com.example.flowfit"')));
    expect(readinessAudit, contains('Android native namespace'));
    expect(readinessAudit, contains('Android Kotlin package namespace'));
    expect(readinessAudit, contains('Android manifest app components'));
    expect(
      Directory(
        'android/app/src/main/kotlin/com/oldstlabs/flowfit',
      ).existsSync(),
      isTrue,
    );
    for (final source in androidKotlinSources) {
      expect(source, contains('package com.oldstlabs.flowfit'));
      expect(source, isNot(contains('package com.example.flowfit')));
    }
  });

  test('Android manifest relative components resolve to Kotlin classes', () {
    final declaredComponents = RegExp(r'android:name="\.(\w+)"')
        .allMatches('$androidMainManifest\n$androidDebugManifest')
        .map((match) => match.group(1)!)
        .toSet();

    expect(androidMainManifest, isNot(contains('.SensorTrackingService')));
    expect(declaredComponents, containsAll(['FlowFitApp', 'MainActivity']));

    for (final component in declaredComponents) {
      expect(
        File(
          'android/app/src/main/kotlin/com/oldstlabs/flowfit/$component.kt',
        ).existsSync(),
        isTrue,
        reason: '$component is declared as a relative Android component',
      );
    }
  });

  test('Android MainActivity does not manually invoke plugin registrant', () {
    expect(androidMainActivity, isNot(contains('GeneratedPluginRegistrant')));
  });

  test('release scripts clear stale ignored Android plugin registrant', () {
    for (final source in [releasePreflight, storeReleaseBuild]) {
      expect(source, contains('Remove-IgnoredGeneratedAndroidRegistrant'));
      expect(
        source,
        contains(
          'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
        ),
      );
    }
  });

  test(
    'store release wrapper blocks dirty source unless explicitly allowed',
    () {
      expect(storeReleaseBuild, contains('[switch]\$AllowDirty'));
      expect(storeReleaseBuild, contains('Assert-CleanGitTree'));
      expect(storeReleaseBuild, contains('git status --porcelain'));
      expect(storeReleaseBuild, contains('AllowDirty'));
    },
  );

  test('release scripts can load an ignored env file', () {
    expect(readinessAudit, contains('[string]\$EnvFile'));
    expect(storeReleaseBuild, contains('[string]\$EnvFile'));
    expect(readinessAudit, contains('Import-ReleaseEnvFile'));
    expect(storeReleaseBuild, contains('Import-ReleaseEnvFile'));
  });

  test('release env template lists required store inputs', () {
    for (final name in [
      'FLOWFIT_SUPPORT_EMAIL',
      'FLOWFIT_SUPPORT_EMAIL_VERIFIED',
      'FLOWFIT_PUBLIC_WEB_BASE_URL',
      'SUPABASE_URL',
      'SUPABASE_PUBLISHABLE_KEY',
      'ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID',
      'ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME',
    ]) {
      expect(releaseEnvExample, contains('$name='));
    }
    expect(
      releaseEnvExample,
      contains('REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY'),
    );
    expect(
      releaseEnvExample,
      isNot(contains('SUPABASE_PUBLISHABLE_KEY=sb_publishable_...')),
    );
    expect(releaseEnvExample, isNot(contains('service_role')));
    expect(releaseEnvExample, isNot(contains('sb_secret_')));
    expect(releaseEnvExample, isNot(contains('dnasghxxqwibwqnljvxr')));
  });

  test('legacy Kiro specs do not pin retired Supabase credentials', () {
    final kiroSpecs = Directory('.kiro')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.md'))
        .toList();

    for (final file in kiroSpecs) {
      final content = file.readAsStringSync();
      expect(
        content,
        isNot(contains('dnasghxxqwibwqnljvxr')),
        reason: '${file.path} must not pin the retired Supabase project ref.',
      );
      expect(
        content,
        isNot(
          matches(RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+')),
        ),
        reason: '${file.path} must not contain committed Supabase JWTs.',
      );
    }
  });

  test('store release wrapper runs validation before producing artifacts', () {
    expect(storeReleaseBuild, contains('[switch]\$SkipValidation'));
    expect(storeReleaseBuild, contains('Invoke-ReleaseValidation'));
    expect(storeReleaseBuild, contains("dart', 'analyze', '--format=machine"));
    expect(
      storeReleaseBuild,
      contains("flutter', 'test', '--reporter', 'compact"),
    );
    expect(storeReleaseBuild, contains(':app:lintRelease'));
  });

  test('store release wrapper uses portable nested release tools', () {
    expect(storeReleaseBuild, contains('Join-Path \$repoRoot'));
    expect(storeReleaseBuild, contains("'android'"));
    expect(storeReleaseBuild, contains("'gradlew.bat'"));
    expect(storeReleaseBuild, contains("'gradlew'"));
    expect(storeReleaseBuild, contains('scripts/release_readiness_audit.ps1'));
    expect(storeReleaseBuild, isNot(contains("return '.\\gradlew.bat'")));
    expect(
      storeReleaseBuild,
      isNot(contains("'scripts\\release_readiness_audit.ps1'")),
    );
  });

  test('release preflight invokes audit through portable script path', () {
    expect(releasePreflight, contains('Join-Path \$repoRoot'));
    expect(releasePreflight, contains('scripts/release_readiness_audit.ps1'));
    expect(
      releasePreflight,
      isNot(contains("'scripts\\release_readiness_audit.ps1'")),
    );
  });

  test('release preflight exposes optional Flutter web Wasm smoke build', () {
    expect(releasePreflight, contains('[switch]\$IncludeWasmSmoke'));
    expect(releasePreflight, contains('if (\$IncludeWasmSmoke)'));
    expect(releasePreflight, contains("'--wasm'"));
    expect(releasePreflight, contains('Flutter web Wasm release smoke build'));
  });

  test('store checklist supports env-only Supabase release inputs', () {
    expect(storeSubmissionChecklist, contains('SUPABASE_URL'));
    expect(storeSubmissionChecklist, contains('SUPABASE_PUBLISHABLE_KEY'));
    expect(storeSubmissionChecklist, contains('.env.release'));
    expect(
      storeSubmissionChecklist,
      isNot(
        contains(
          '- [ ] `lib/secrets.dart` uses the production Project URL and publishable key.',
        ),
      ),
    );
  });

  test('store release wrapper creates portable web deploy archive', () {
    final webReleaseBuild = storeReleaseBuild.substring(
      storeReleaseBuild.indexOf('function Invoke-WebReleaseBuild'),
    );

    expect(storeReleaseBuild, contains('[switch]\$WebWasm'));
    expect(storeReleaseBuild, contains('webBuildBackend'));
    expect(webReleaseBuild, contains("if (\$WebWasm)"));
    expect(webReleaseBuild, contains("'--wasm'"));
    expect(storeReleaseBuild, contains('function New-WebReleaseArchive'));
    expect(storeReleaseBuild, contains('build/release'));
    expect(storeReleaseBuild, contains('flowfit-web-release.zip'));
    expect(storeReleaseBuild, contains('Compress-Archive'));
    expect(
      storeReleaseBuild,
      contains("Add-Artifact -Name 'flutter-web-release-zip'"),
    );
    expect(
      webReleaseBuild.indexOf('Assert-WebCompliancePages'),
      lessThan(webReleaseBuild.indexOf('New-WebReleaseArchive')),
    );
  });

  test('store web release supports path-based static hosts', () {
    expect(storeReleaseBuild, contains('Resolve-WebReleaseConfig'));
    expect(storeReleaseBuild, contains('FLOWFIT_WEB_BASE_HREF'));
    expect(storeReleaseBuild, contains('--base-href'));
    expect(storeReleaseBuild, contains('webBaseHref'));
    expect(
      storeReleaseBuild,
      contains('https://iron-mark.github.io/Hackathon-FlowFit'),
    );
  });

  test('web deployment verifier checks deployed compliance pages', () {
    expect(webDeploymentVerifier, contains('[string]\$BaseUrl'));
    expect(webDeploymentVerifier, contains('[switch]\$AllowInsecureLocalhost'));
    expect(webDeploymentVerifier, contains('Invoke-WebRequest'));
    expect(webDeploymentVerifier, contains('/flutter_bootstrap.js'));
    expect(webDeploymentVerifier, contains('/main.dart.js'));
    expect(webDeploymentVerifier, contains('/privacy.html'));
    expect(webDeploymentVerifier, contains('/account-deletion.html'));
    expect(webDeploymentVerifier, contains('/manifest.json'));
    expect(webDeploymentVerifier, contains('FLOWFIT_SUPPORT_EMAIL'));
    expect(webDeploymentVerifier, contains('FlowFit Privacy Policy'));
    expect(webDeploymentVerifier, contains('FlowFit Account Deletion'));
    expect(webDeploymentVerifier, contains('without reinstalling the app'));
    expect(webDeploymentVerifier, contains('ConvertTo-Json'));
    expect(webDeploymentVerifier, contains('[string]\$OutFile'));
  });

  test('ci runs web static verifier against built web output', () {
    expect(ciWorkflow, contains('scripts/verify_web_deployment.ps1'));
    expect(ciWorkflow, contains('-AllowInsecureLocalhost'));
    expect(ciWorkflow, contains('web-static-ci-smoke.json'));
    expect(ciWorkflow, contains('python3 -m http.server'));
    expect(ciWorkflow, contains('Upload web static verification evidence'));
    expect(ciWorkflow, contains('flowfit-web-static-verification-smoke'));
    expect(ciWorkflow, isNot(contains('Verify web deployment smoke')));
  });

  test('ci installs Android SDK command-line tools before sdkmanager use', () {
    expect(ciWorkflow, contains('android-actions/setup-android@v3'));
    expect(
      ciWorkflow.indexOf('android-actions/setup-android@v3'),
      lessThan(ciWorkflow.indexOf('sdkmanager "platforms;android-36"')),
    );
  });

  test('GitHub workflows opt JavaScript actions into Node 24', () {
    expect(ciWorkflow, contains('FORCE_JAVASCRIPT_ACTIONS_TO_NODE24'));
    expect(pagesWorkflow, contains('FORCE_JAVASCRIPT_ACTIONS_TO_NODE24'));
  });

  test('ci keeps web Wasm and Android generated artifacts isolated', () {
    expect(ciWorkflow, contains('Flutter web Wasm release build'));
    expect(ciWorkflow, contains('--wasm'));
    expect(ciWorkflow, contains('--output=build/web-wasm'));
    expect(ciWorkflow, contains('Verify web Wasm artifact'));
    expect(ciWorkflow, contains('main.dart.wasm'));
    expect(ciWorkflow, contains('flowfit-web-wasm-smoke-not-for-store'));
    expect(
      ciWorkflow,
      contains(
        'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
      ),
    );
    expect(
      ciWorkflow,
      contains(
        'rm -f android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
      ),
    );
  });

  test('GitHub Pages workflow publishes production web artifacts', () {
    expect(pagesWorkflow, contains('name: Flutter Web Pages'));
    expect(pagesWorkflow, contains('actions/configure-pages@v5'));
    expect(pagesWorkflow, contains('actions/upload-pages-artifact@v3'));
    expect(pagesWorkflow, contains('actions/deploy-pages@v4'));
    expect(pagesWorkflow, contains('actions/upload-artifact@v4'));
    expect(pagesWorkflow, contains('scripts/store_release_build.ps1'));
    expect(pagesWorkflow, contains('-Target Web'));
    expect(pagesWorkflow, contains('-SkipFlutterPubGet'));
    expect(pagesWorkflow, contains('FLOWFIT_PUBLIC_WEB_BASE_URL'));
    expect(pagesWorkflow, contains('SUPABASE_URL'));
    expect(pagesWorkflow, contains('SUPABASE_PUBLISHABLE_KEY'));
    expect(pagesWorkflow, contains('flowfit-github-pages-verification'));
    expect(pagesWorkflow, contains('/Hackathon-FlowFit/'));
  });

  test('agent guidance matches maintained fork backend and native package', () {
    expect(copilotInstructions, contains('com.oldstlabs.flowfit'));
    expect(copilotInstructions, contains('SUPABASE_PUBLISHABLE_KEY'));
    expect(copilotInstructions, contains('publishable key'));
    expect(copilotInstructions, contains('SupabaseService'));
    expect(copilotInstructions, isNot(contains('com/example/flowfit')));
    expect(copilotInstructions, isNot(contains('com.example.flowfit')));
    expect(copilotInstructions, isNot(contains('anon key')));
    expect(copilotInstructions, isNot(contains('currently a placeholder')));
  });

  test('release guards reject reserved example hosts', () {
    for (final source in [
      storeReleaseBuild,
      readinessAudit,
      configureLocalRelease,
    ]) {
      expect(source, contains('(example|invalid|test|localhost)'));
      expect(source, contains('127\\.0\\.0\\.1'));
    }
  });

  test('strict audit rejects reserved public web origins', () {
    final env = Map<String, String>.from(Platform.environment)
      ..['FLOWFIT_PUBLIC_WEB_BASE_URL'] = 'https://flowfit-web-handoff.invalid'
      ..['FLOWFIT_SUPPORT_EMAIL_VERIFIED'] = 'true'
      ..['SUPABASE_URL'] = 'https://abcdefghijklmnop.supabase.co'
      ..['SUPABASE_PUBLISHABLE_KEY'] =
          'sb_publishable_abcdefghijklmnopqrstuvwxyz123456';

    final audit = Process.runSync('pwsh', [
      '-NoProfile',
      '-File',
      'scripts/release_readiness_audit.ps1',
      '-Strict',
      '-SupportEmailVerified',
    ], environment: env);

    expect(audit.exitCode, isNot(0));
    expect(
      '${audit.stdout}\n${audit.stderr}',
      contains('[FAIL] Public web deployment URL'),
    );
    expect('${audit.stdout}\n${audit.stderr}', contains('reserved'));
  });

  test('release guards reject fake publishable keys', () {
    expect(storeReleaseBuild, contains('Assert-SupabasePublishableKey'));
    expect(readinessAudit, contains('Test-SupabasePublishableKey'));
    expect(configureLocalRelease, contains('Assert-SupabasePublishableKey'));
    expect(storeReleaseBuild, contains(r'\.\.\.'));
    expect(readinessAudit, contains(r'\.\.\.'));
    expect(configureLocalRelease, contains(r'\.\.\.'));
    expect(storeReleaseBuild, contains(r'^sb_publishable_[A-Za-z0-9_-]{20,}$'));
    expect(readinessAudit, contains(r'^sb_publishable_[A-Za-z0-9_-]{20,}$'));
  });

  test('runtime release guards reject ellipsis publishable keys', () {
    final env = Map<String, String>.from(Platform.environment)
      ..['SUPABASE_URL'] = 'https://abcdefghijklmnop.supabase.co'
      ..['SUPABASE_PUBLISHABLE_KEY'] = 'sb_publishable_...';

    final audit = Process.runSync('pwsh', [
      '-NoProfile',
      '-File',
      'scripts/release_readiness_audit.ps1',
      '-OutFile',
      'build/test-invalid-publishable-audit.json',
    ], environment: env);
    expect(audit.exitCode, isNot(0));
    expect(
      '${audit.stdout}\n${audit.stderr}',
      contains('[FAIL] Supabase release publishable key'),
    );

    final store = Process.runSync('pwsh', [
      '-NoProfile',
      '-File',
      'scripts/store_release_build.ps1',
      '-Target',
      'Web',
      '-AllowDirty',
      '-SkipFlutterPubGet',
      '-SkipValidation',
    ], environment: env);
    expect(store.exitCode, isNot(0));
    final storeOutput = '${store.stdout}\n${store.stderr}'
        .replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
    expect(storeOutput, contains('must provide a real Supabase'));
    expect(storeOutput, contains('publishable client key'));
    expect(storeOutput, contains('sb_publishable_'));
  });

  test('store release native manifests exclude development auth schemes', () {
    expect(androidMainManifest, contains(r'${flowfitAuthScheme}'));
    expect(androidMainManifest, isNot(contains(r'${flowfitDevAuthScheme}')));
    expect(androidDebugManifest, contains(r'${flowfitDevAuthScheme}'));
    expect(iosInfoPlist, contains(r'$(FLOWFIT_IOS_BUNDLE_IDENTIFIER)'));
    expect(iosInfoPlist, isNot(contains(r'$(FLOWFIT_IOS_DEV_AUTH_SCHEME)')));
  });

  test('support inbox readiness follows configured support email', () {
    expect(readinessAudit, contains('FLOWFIT_SUPPORT_EMAIL'));
    expect(readinessAudit, contains('\$expectedSupportEmail'));
    expect(readinessAudit, contains('configured support inbox'));
  });

  test(
    'recovered Supabase config only allows maintained-fork mobile redirects',
    () {
      expect(supabaseConfig, contains('com.oldstlabs.flowfit://auth-callback'));
      expect(
        supabaseConfig,
        contains('com.oldstlabs.flowfit.dev://auth-callback'),
      );
      expect(
        supabaseConfig,
        isNot(contains('com.example.flowfit://auth-callback')),
      );
      expect(
        supabaseConfig,
        isNot(contains('com.example.flowfit.dev://auth-callback')),
      );
      expect(supabaseConfig, contains('enable_confirmations = true'));
    },
  );

  test('Supabase auth password policy matches app minimum length', () {
    expect(supabaseConfig, contains('minimum_password_length = 8'));
  });
}
