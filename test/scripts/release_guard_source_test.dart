import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String gradleBuild;
  late String releasePreflight;
  late String storeReleaseBuild;
  late String readinessAudit;
  late String releaseStatusSnapshot;
  late String createAndroidUploadKeystore;
  late String exportAndroidSigningEnv;
  late String supportInboxVerifier;
  late String storeMetadataVerifier;
  late String createIosExportOptions;
  late String scriptsReadme;
  late String gitignore;
  late String supabaseConfig;
  late String releaseEnvExample;
  late String configureLocalRelease;
  late String configureSupabaseMcp;
  late String verifySupabaseBackend;
  late String supabaseBackendVerificationSql;
  late String runPhoneScript;
  late String runPhoneBat;
  late String testPhoneBat;
  late String webDeploymentVerifier;
  late String storeSubmissionChecklist;
  late String releaseReadinessRunbook;
  late String supabaseRecoveryRunbook;
  late String docsIndex;
  late String ciWorkflow;
  late String pagesWorkflow;
  late String copilotInstructions;
  late String androidMainManifest;
  late String androidDebugManifest;
  late String iosInfoPlist;
  late String iosPrivacyManifest;
  late String iosPbxproj;
  late String androidMainActivity;
  late String privacyDataMap;
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
    releaseStatusSnapshot = File(
      'scripts/release_status_snapshot.ps1',
    ).readAsStringSync();
    createAndroidUploadKeystore = File(
      'scripts/create_android_upload_keystore.ps1',
    ).readAsStringSync();
    exportAndroidSigningEnv = File(
      'scripts/export_android_signing_env.ps1',
    ).readAsStringSync();
    supportInboxVerifier = File(
      'scripts/verify_support_inbox.ps1',
    ).readAsStringSync();
    storeMetadataVerifier = File(
      'scripts/verify_store_metadata.ps1',
    ).readAsStringSync();
    createIosExportOptions = File(
      'scripts/create_ios_export_options.ps1',
    ).readAsStringSync();
    scriptsReadme = File('scripts/README.md').readAsStringSync();
    gitignore = File('.gitignore').readAsStringSync();
    supabaseConfig = File('supabase/config.toml').readAsStringSync();
    releaseEnvExample = File('.env.release.example').readAsStringSync();
    configureLocalRelease = File(
      'scripts/configure_local_release.ps1',
    ).readAsStringSync();
    configureSupabaseMcp = File(
      'scripts/configure_supabase_mcp.ps1',
    ).readAsStringSync();
    verifySupabaseBackend = File(
      'scripts/verify_supabase_backend.ps1',
    ).readAsStringSync();
    supabaseBackendVerificationSql = File(
      'supabase/verification/verify_flowfit_backend.sql',
    ).readAsStringSync();
    runPhoneScript = File('scripts/run_phone.ps1').readAsStringSync();
    runPhoneBat = File('scripts/run_phone.bat').readAsStringSync();
    testPhoneBat = File('scripts/test-phone.bat').readAsStringSync();
    webDeploymentVerifier = File(
      'scripts/verify_web_deployment.ps1',
    ).readAsStringSync();
    storeSubmissionChecklist = File(
      'docs/STORE_SUBMISSION_CHECKLIST.md',
    ).readAsStringSync();
    releaseReadinessRunbook = File(
      'docs/RELEASE_READINESS_RUNBOOK.md',
    ).readAsStringSync();
    supabaseRecoveryRunbook = File(
      'docs/SUPABASE_RECOVERY_RUNBOOK.md',
    ).readAsStringSync();
    docsIndex = File('docs/INDEX.md').readAsStringSync();
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
    iosPrivacyManifest = File(
      'ios/Runner/PrivacyInfo.xcprivacy',
    ).readAsStringSync();
    iosPbxproj = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    androidMainActivity = File(
      'android/app/src/main/kotlin/com/oldstlabs/flowfit/MainActivity.kt',
    ).readAsStringSync();
    privacyDataMap = File('docs/PRIVACY_DATA_MAP.md').readAsStringSync();
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

  test('release status snapshot captures handoff state without secrets', () {
    expect(releaseStatusSnapshot, contains('release_readiness_audit.ps1'));
    expect(releaseStatusSnapshot, contains('-Strict'));
    expect(releaseStatusSnapshot, contains('gh'));
    expect(releaseStatusSnapshot, contains('variable'));
    expect(releaseStatusSnapshot, contains('name,updatedAt'));
    expect(releaseStatusSnapshot, isNot(contains('name,value')));
    expect(releaseStatusSnapshot, contains('ConvertTo-SafeRemoteUrl'));
    expect(releaseStatusSnapshot, contains(r'$uri.UserInfo'));
    expect(releaseStatusSnapshot, contains('[System.UriBuilder]'));
    expect(releaseStatusSnapshot, contains("(?<userinfo>[^@\\s/]+)@"));
    expect(releaseStatusSnapshot, contains('SkipRemote'));
    expect(releaseStatusSnapshot, contains('SkipStrictAudit'));
    expect(releaseStatusSnapshot, contains('RELEASE_STATUS_SNAPSHOT_WRITTEN'));
    expect(scriptsReadme, contains('release_status_snapshot.ps1'));
    expect(releaseReadinessRunbook, contains('release_status_snapshot.ps1'));

    final tempDir = Directory.systemTemp.createTempSync(
      'flowfit_release_snapshot_',
    );
    try {
      final outFile = File(
        '${tempDir.path}${Platform.pathSeparator}snapshot.md',
      );
      final result = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/release_status_snapshot.ps1',
        '-SkipRemote',
        '-SkipStrictAudit',
        '-OutFile',
        outFile.path,
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('RELEASE_STATUS_SNAPSHOT_WRITTEN'));
      final snapshot = outFile.readAsStringSync();
      expect(snapshot, contains('FlowFit Release Status Snapshot'));
      expect(snapshot, contains('Strict audit skipped'));
      expect(snapshot, contains('Remote checks skipped'));
      expect(snapshot, isNot(contains('SUPABASE_PUBLISHABLE_KEY=')));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('release status snapshot redacts credential-bearing origin URLs', () {
    final tempDir = Directory.systemTemp.createTempSync(
      'flowfit_release_snapshot_remote_',
    );
    const fakeToken = 'ghp_FAKE_TOKEN_FOR_SNAPSHOT_TEST';
    try {
      final repoDir = Directory('${tempDir.path}${Platform.pathSeparator}repo')
        ..createSync();
      final scriptsDir = Directory(
        '${repoDir.path}${Platform.pathSeparator}scripts',
      )..createSync();
      final snapshotScript = File(
        '${scriptsDir.path}${Platform.pathSeparator}release_status_snapshot.ps1',
      );
      File('scripts/release_status_snapshot.ps1').copySync(snapshotScript.path);

      final init = Process.runSync('git', [
        'init',
      ], workingDirectory: repoDir.path);
      expect(init.exitCode, 0, reason: '${init.stdout}\n${init.stderr}');

      final addRemote = Process.runSync('git', [
        'remote',
        'add',
        'origin',
        'https://$fakeToken@github.com/Iron-Mark/Hackathon-FlowFit.git',
      ], workingDirectory: repoDir.path);
      expect(
        addRemote.exitCode,
        0,
        reason: '${addRemote.stdout}\n${addRemote.stderr}',
      );

      final outFile = File(
        '${tempDir.path}${Platform.pathSeparator}snapshot.md',
      );
      final result = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        snapshotScript.path,
        '-SkipRemote',
        '-SkipStrictAudit',
        '-OutFile',
        outFile.path,
      ], workingDirectory: repoDir.path);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      final snapshot = outFile.readAsStringSync();
      expect(snapshot, isNot(contains(fakeToken)));
      expect(
        snapshot,
        contains('https://github.com/Iron-Mark/Hackathon-FlowFit.git'),
      );
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'store release wrapper can materialize Android signing from env secrets',
    () {
      for (final name in [
        'FLOWFIT_ANDROID_KEYSTORE_BASE64',
        'FLOWFIT_ANDROID_KEYSTORE_PASSWORD',
        'FLOWFIT_ANDROID_KEY_ALIAS',
        'FLOWFIT_ANDROID_KEY_PASSWORD',
      ]) {
        expect(storeReleaseBuild, contains(name));
        expect(releaseEnvExample, contains(name));
      }

      expect(storeReleaseBuild, contains('Initialize-AndroidSigningFromEnv'));
      expect(storeReleaseBuild, contains('Convert]::FromBase64String'));
      expect(storeReleaseBuild, contains('android/key.properties'));
      expect(
        storeReleaseBuild,
        contains('Remove-GeneratedAndroidSigningFiles'),
      );
      expect(readinessAudit, contains('FLOWFIT_ANDROID_KEYSTORE_BASE64'));
    },
  );

  test(
    'Android upload keystore generator writes only ignored private outputs',
    () {
      expect(createAndroidUploadKeystore, contains('keytool'));
      expect(createAndroidUploadKeystore, contains("'-storetype', 'JKS'"));
      expect(createAndroidUploadKeystore, contains('New-RandomPassword'));
      expect(
        createAndroidUploadKeystore,
        contains('System.Security.Cryptography.RandomNumberGenerator'),
      );
      expect(
        createAndroidUploadKeystore,
        contains('FLOWFIT_ANDROID_KEYSTORE_BASE64'),
      );
      expect(
        createAndroidUploadKeystore,
        contains('ANDROID_UPLOAD_KEYSTORE_CREATED'),
      );
      expect(createAndroidUploadKeystore, contains('will not be overwritten'));
      expect(
        createAndroidUploadKeystore,
        isNot(contains(r'Write-Host $storePassword')),
      );
      expect(
        createAndroidUploadKeystore,
        isNot(contains(r'Write-Host $keyPassword')),
      );
      expect(scriptsReadme, contains('create_android_upload_keystore.ps1'));
      expect(
        releaseReadinessRunbook,
        contains('create_android_upload_keystore.ps1'),
      );
      expect(
        storeSubmissionChecklist,
        contains('create_android_upload_keystore.ps1'),
      );
      expect(gitignore, contains('.env.release.android-signing'));
      expect(gitignore, contains('.env.release.android-signing*'));
      expect(exportAndroidSigningEnv, contains('ANDROID_SIGNING_ENV_EXPORTED'));
      expect(exportAndroidSigningEnv, contains('git'));
      expect(exportAndroidSigningEnv, contains('check-ignore'));
      expect(exportAndroidSigningEnv, contains('ToBase64String'));
      expect(exportAndroidSigningEnv, contains('android/key.properties'));
      expect(exportAndroidSigningEnv, contains('will not be overwritten'));
      expect(
        exportAndroidSigningEnv,
        contains('Unsupported Java properties escaping'),
      );
      expect(
        exportAndroidSigningEnv,
        contains('FLOWFIT_ANDROID_KEYSTORE_BASE64'),
      );
      expect(
        exportAndroidSigningEnv,
        isNot(contains(r'Write-Host $keystoreBase64')),
      );
    },
  );

  test('Android signing env exporter writes ignored CI secret handoff', () {
    final unique = '${DateTime.now().microsecondsSinceEpoch}_$pid';
    final fixtureDir = Directory('build/android-signing-export-$unique');
    final androidDir = Directory('${fixtureDir.path}/android');
    final keyProperties = File('${androidDir.path}/key.properties');
    final escapedKeyProperties = File('${androidDir.path}/escaped.properties');
    final keystore = File('${androidDir.path}/upload-keystore.jks');
    final outFile = File(
      '${fixtureDir.path}/.env.release.android-signing.generated',
    );
    final escapedOutFile = File(
      '${fixtureDir.path}/.env.release.android-signing.escaped',
    );
    final nonIgnoredOutFile = File('android-signing-export-$unique.txt');

    try {
      final rootIgnore = Process.runSync('git', [
        'check-ignore',
        '-q',
        '--',
        '.env.release.android-signing.generated',
      ]);
      expect(rootIgnore.exitCode, 0);

      androidDir.createSync(recursive: true);
      keystore.writeAsStringSync('fake-keystore');
      keyProperties.writeAsStringSync('''
storePassword=store-password
keyPassword=key-password
keyAlias=upload
storeFile=upload-keystore.jks
''');

      final result = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/export_android_signing_env.ps1',
        '-KeyPropertiesPath',
        keyProperties.path,
        '-OutFile',
        outFile.path,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('ANDROID_SIGNING_ENV_EXPORTED'));

      final handoff = outFile.readAsStringSync();
      expect(
        handoff,
        contains(
          'FLOWFIT_ANDROID_KEYSTORE_BASE64=${base64Encode(utf8.encode('fake-keystore'))}',
        ),
      );
      expect(
        handoff,
        contains('FLOWFIT_ANDROID_KEYSTORE_PASSWORD=store-password'),
      );
      expect(handoff, contains('FLOWFIT_ANDROID_KEY_ALIAS=upload'));
      expect(handoff, contains('FLOWFIT_ANDROID_KEY_PASSWORD=key-password'));
      expect(
        handoff,
        contains('FLOWFIT_ANDROID_KEYSTORE_FILE_NAME=upload-keystore.jks'),
      );

      final nonIgnored = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/export_android_signing_env.ps1',
        '-KeyPropertiesPath',
        keyProperties.path,
        '-OutFile',
        nonIgnoredOutFile.path,
      ]);
      expect(nonIgnored.exitCode, isNot(0));
      expect(
        '${nonIgnored.stdout}\n${nonIgnored.stderr}',
        contains('OutFile must be gitignored'),
      );
      expect(nonIgnoredOutFile.existsSync(), isFalse);

      final overwrite = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/export_android_signing_env.ps1',
        '-KeyPropertiesPath',
        keyProperties.path,
        '-OutFile',
        outFile.path,
      ]);
      expect(overwrite.exitCode, isNot(0));
      expect(
        '${overwrite.stdout}\n${overwrite.stderr}',
        contains('will not be overwritten'),
      );

      escapedKeyProperties.writeAsStringSync(r'''
storePassword=store\ password
keyPassword=key-password
keyAlias=upload
storeFile=upload-keystore.jks
''');
      final escaped = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/export_android_signing_env.ps1',
        '-KeyPropertiesPath',
        escapedKeyProperties.path,
        '-OutFile',
        escapedOutFile.path,
      ]);
      expect(escaped.exitCode, isNot(0));
      expect(
        '${escaped.stdout}\n${escaped.stderr}',
        contains('Unsupported Java properties escaping'),
      );
      expect(escapedOutFile.existsSync(), isFalse);
    } finally {
      if (fixtureDir.existsSync()) {
        fixtureDir.deleteSync(recursive: true);
      }
      if (nonIgnoredOutFile.existsSync()) {
        nonIgnoredOutFile.deleteSync();
      }
    }
  });

  test('store release wrapper refuses to overwrite existing env keystore', () {
    expect(
      storeReleaseBuild,
      contains('Refusing to overwrite existing Android upload keystore'),
    );
    expect(
      storeReleaseBuild,
      contains(r'Test-Path -LiteralPath $storeFilePath'),
    );
  });

  test(
    'store release wrapper signing env fixture cleans up only generated files',
    () {
      final result = _runAndroidSigningEnvFixture();
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('ANDROID_SIGNING_ENV_FIXTURE_OK'));
    },
  );

  test('iOS export-options helper creates ignored Xcode plist input', () {
    expect(
      createIosExportOptions,
      contains('IOS_EXPORT_OPTIONS_PLIST_WRITTEN'),
    );
    expect(
      createIosExportOptions,
      contains('FLOWFIT_IOS_EXPORT_OPTIONS_PLIST'),
    );
    expect(createIosExportOptions, contains('ios/Flutter/FlowFit.xcconfig'));
    expect(createIosExportOptions, contains('FLOWFIT_IOS_BUNDLE_IDENTIFIER'));
    expect(createIosExportOptions, contains('app-store-connect'));
    expect(createIosExportOptions, contains('ProvisioningProfileName'));
    expect(createIosExportOptions, contains('will not be overwritten'));
    expect(createIosExportOptions, isNot(contains('AuthKey_')));
    expect(createIosExportOptions, isNot(contains('.p12')));
    expect(scriptsReadme, contains('create_ios_export_options.ps1'));
    expect(releaseReadinessRunbook, contains('create_ios_export_options.ps1'));
    expect(storeSubmissionChecklist, contains('create_ios_export_options.ps1'));
    expect(releaseEnvExample, contains('FLOWFIT_IOS_EXPORT_OPTIONS_PLIST'));
    expect(gitignore, contains('ios/ExportOptions.plist'));
    expect(gitignore, contains('ios/export_options*.plist'));
  });

  test('iOS export-options helper writes manual and automatic plists', () {
    final unique = '${DateTime.now().microsecondsSinceEpoch}_$pid';
    final manualOut = File('build/ios-export-options-manual-$unique.plist');
    final automaticOut = File(
      'build/ios-export-options-automatic-$unique.plist',
    );
    final missingProfileOut = File(
      'build/ios-export-options-missing-profile-$unique.plist',
    );

    try {
      final missingProfile = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/create_ios_export_options.ps1',
        '-TeamId',
        'ABCDE12345',
        '-OutFile',
        missingProfileOut.path,
      ]);
      expect(missingProfile.exitCode, isNot(0));
      expect(
        '${missingProfile.stdout}\n${missingProfile.stderr}',
        contains('ProvisioningProfileName'),
      );
      expect(missingProfileOut.existsSync(), isFalse);

      final manual = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/create_ios_export_options.ps1',
        '-TeamId',
        'ABCDE12345',
        '-ProvisioningProfileName',
        'FlowFit App Store',
        '-OutFile',
        manualOut.path,
      ]);
      expect(manual.exitCode, 0, reason: '${manual.stdout}\n${manual.stderr}');
      expect(manual.stdout, contains('IOS_EXPORT_OPTIONS_PLIST_WRITTEN'));
      expect(manual.stdout, isNot(contains('FlowFit App Store')));
      final manualPlist = manualOut.readAsStringSync();
      expect(manualPlist, contains('<string>app-store-connect</string>'));
      expect(manualPlist, contains('<string>manual</string>'));
      expect(manualPlist, contains('<string>ABCDE12345</string>'));
      expect(manualPlist, contains('<key>com.oldstlabs.flowfit</key>'));
      expect(manualPlist, contains('<string>FlowFit App Store</string>'));
      expect(manualPlist, contains('<string>Apple Distribution</string>'));

      final overwrite = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/create_ios_export_options.ps1',
        '-TeamId',
        'ABCDE12345',
        '-ProvisioningProfileName',
        'FlowFit App Store',
        '-OutFile',
        manualOut.path,
      ]);
      expect(overwrite.exitCode, isNot(0));
      expect(
        '${overwrite.stdout}\n${overwrite.stderr}',
        contains('will not be overwritten'),
      );

      final automatic = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/create_ios_export_options.ps1',
        '-TeamId',
        'ABCDE12345',
        '-SigningStyle',
        'automatic',
        '-OutFile',
        automaticOut.path,
      ]);
      expect(
        automatic.exitCode,
        0,
        reason: '${automatic.stdout}\n${automatic.stderr}',
      );
      final automaticPlist = automaticOut.readAsStringSync();
      expect(automaticPlist, contains('<string>automatic</string>'));
      expect(automaticPlist, isNot(contains('provisioningProfiles')));
    } finally {
      for (final file in [manualOut, automaticOut, missingProfileOut]) {
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    }
  });

  test('store metadata verifier covers listing copy and store assets', () {
    expect(
      storeMetadataVerifier,
      contains('STORE_METADATA_VERIFICATION_WRITTEN'),
    );
    expect(storeMetadataVerifier, contains('STORE_METADATA_DRAFT.md'));
    expect(storeMetadataVerifier, contains('PRIVACY_DATA_MAP.md'));
    expect(storeMetadataVerifier, contains('STORE_SUBMISSION_CHECKLIST.md'));
    expect(storeMetadataVerifier, contains('Short Description'));
    expect(storeMetadataVerifier, contains('Full Description'));
    expect(storeMetadataVerifier, contains('Screenshot Shot List'));
    expect(storeMetadataVerifier, contains('Review Evidence Checklist'));
    expect(storeMetadataVerifier, contains('Get-PngDimensions'));
    expect(storeMetadataVerifier, contains('ios-marketing'));
    expect(storeMetadataVerifier, contains('PrivacyInfo.xcprivacy'));
    expect(storeMetadataVerifier, contains('NSPrivacyCollectedDataTypes'));
    expect(storeMetadataVerifier, contains('NSPrivacyAccessedAPITypes'));
    expect(storeMetadataVerifier, contains('Icon-maskable-512.png'));
    expect(storeMetadataVerifier, contains('FLOWFIT_PUBLIC_WEB_BASE_URL'));
    expect(storeMetadataVerifier, contains('PublicWebBaseUrl'));
    expect(storeMetadataVerifier, contains('ConvertTo-NormalizedSearchText'));
    expect(storeMetadataVerifier, contains('GetLeftPart'));
    expect(storeMetadataVerifier, contains('AbsolutePath'));
    expect(storeMetadataVerifier, contains('Query'));
    expect(storeMetadataVerifier, contains('Fragment'));
    expect(storeMetadataVerifier, contains('Strict'));
    expect(releasePreflight, contains('verify_store_metadata.ps1'));
    expect(
      releasePreflight,
      contains('Invoke-CheckedCommandWithAllowedExitCodes'),
    );
    expect(releasePreflight, contains('@(0, 2)'));
    expect(scriptsReadme, contains('verify_store_metadata.ps1'));
    expect(releaseReadinessRunbook, contains('verify_store_metadata.ps1'));
    expect(storeSubmissionChecklist, contains('verify_store_metadata.ps1'));
    expect(
      storeSubmissionChecklist,
      contains('store-metadata-verification.json'),
    );
    expect(docsIndex, contains('verify_store_metadata.ps1'));
  });

  test('iOS privacy manifest is wired and guarded for App Store review', () {
    expect(iosPbxproj, contains('PrivacyInfo.xcprivacy in Resources'));
    expect(iosPbxproj, contains('path = PrivacyInfo.xcprivacy'));
    expect(iosPrivacyManifest, contains('NSPrivacyAccessedAPITypes'));
    expect(
      iosPrivacyManifest,
      contains('NSPrivacyAccessedAPICategoryUserDefaults'),
    );
    expect(iosPrivacyManifest, contains('CA92.1'));
    expect(
      iosPrivacyManifest,
      contains('NSPrivacyAccessedAPICategoryFileTimestamp'),
    );
    expect(iosPrivacyManifest, contains('C617.1'));
    expect(iosPrivacyManifest, contains('NSPrivacyCollectedDataTypes'));
    for (final dataType in [
      'NSPrivacyCollectedDataTypeEmailAddress',
      'NSPrivacyCollectedDataTypeName',
      'NSPrivacyCollectedDataTypeUserID',
      'NSPrivacyCollectedDataTypeHealth',
      'NSPrivacyCollectedDataTypeFitness',
      'NSPrivacyCollectedDataTypePreciseLocation',
      'NSPrivacyCollectedDataTypePhotosorVideos',
      'NSPrivacyCollectedDataTypeOtherUserContent',
      'NSPrivacyCollectedDataTypeProductInteraction',
    ]) {
      expect(iosPrivacyManifest, contains(dataType));
    }
    expect(
      iosPrivacyManifest,
      contains('NSPrivacyCollectedDataTypePurposeAppFunctionality'),
    );
    expect(
      iosPrivacyManifest,
      matches(RegExp(r'<key>NSPrivacyTracking</key>\s*<false\s*/>')),
    );
    expect(iosPrivacyManifest, contains('NSPrivacyTrackingDomains'));

    expect(readinessAudit, contains('iOS privacy manifest'));
    expect(readinessAudit, contains('Missing or blank'));
    expect(
      readinessAudit,
      contains('NSPrivacyAccessedAPICategoryUserDefaults'),
    );
    expect(readinessAudit, contains('NSPrivacyCollectedDataTypeHealth'));
    expect(readinessAudit, contains('NSPrivacyTrackingDomains=empty'));
    expect(storeMetadataVerifier, contains('Test-IosPrivacyManifest'));
    expect(storeMetadataVerifier, contains('must not be blank'));
    expect(
      storeMetadataVerifier,
      contains('iOS privacy manifest tracking domains'),
    );
    expect(privacyDataMap, contains('PrivacyInfo.xcprivacy'));
    expect(storeSubmissionChecklist, contains('PrivacyInfo.xcprivacy'));
    expect(storeSubmissionChecklist, contains('Generate Privacy Report'));
    expect(releaseReadinessRunbook, contains('PrivacyInfo.xcprivacy'));
    expect(releaseReadinessRunbook, contains('Generate Privacy Report'));
    expect(docsIndex, contains('PrivacyInfo.xcprivacy'));
  });

  test('store metadata verifier records advisory and strict evidence', () {
    final unique = '${DateTime.now().microsecondsSinceEpoch}_$pid';
    final advisoryOut = File('build/store-metadata-advisory-$unique.json');
    final strictOut = File('build/store-metadata-strict-$unique.json');
    const publicWebBaseUrl = 'https://release.flowfit.example/';
    const unsafePublicWebBaseUrl =
        'https://release.flowfit.example/app?debug=value#frag';

    try {
      final advisory = Process.runSync(
        'pwsh',
        [
          '-NoProfile',
          '-File',
          'scripts/verify_store_metadata.ps1',
          '-OutFile',
          advisoryOut.path,
        ],
        environment: {'FLOWFIT_PUBLIC_WEB_BASE_URL': publicWebBaseUrl},
      );
      expect(
        advisory.exitCode,
        anyOf(0, 2),
        reason: '${advisory.stdout}\n${advisory.stderr}',
      );
      expect(advisory.stdout, contains('STORE_METADATA_VERIFICATION_WRITTEN'));
      final advisoryJson =
          jsonDecode(advisoryOut.readAsStringSync()) as Map<String, dynamic>;
      expect(
        advisoryJson['publicWebBaseUrl'],
        'https://release.flowfit.example',
      );
      final advisorySummary = advisoryJson['summary'] as Map<String, dynamic>;
      expect(advisorySummary['fail'], 0);
      final advisoryWarnCount = advisorySummary['warn'] as int;
      if (advisory.exitCode == 2) {
        expect(advisoryWarnCount, greaterThanOrEqualTo(1));
      } else {
        expect(advisoryWarnCount, 0);
      }
      final advisoryResults = advisoryJson['results'] as List<dynamic>;
      expect(
        advisoryResults.any(
          (result) =>
              (result as Map<String, dynamic>)['name'] ==
              'Android launcher icon',
        ),
        isTrue,
      );
      expect(
        advisoryResults.any(
          (result) =>
              (result as Map<String, dynamic>)['name'] == 'iOS marketing icon',
        ),
        isTrue,
      );

      final strict = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/verify_store_metadata.ps1',
        '-Strict',
        '-PublicWebBaseUrl',
        unsafePublicWebBaseUrl,
        '-OutFile',
        strictOut.path,
      ]);
      expect(strict.exitCode, 1, reason: '${strict.stdout}\n${strict.stderr}');
      expect(strict.stdout, contains('STORE_METADATA_VERIFICATION_WRITTEN'));
      final strictJson =
          jsonDecode(strictOut.readAsStringSync()) as Map<String, dynamic>;
      expect(strictJson['publicWebBaseUrl'], 'https://release.flowfit.example');
      final strictEvidence = strictOut.readAsStringSync();
      expect(strictEvidence, isNot(contains('debug=value')));
      expect(strictEvidence, isNot(contains('/app?')));
      expect(strictEvidence, isNot(contains('#frag')));
      expect(
        ((strictJson['summary'] as Map<String, dynamic>)['fail'] as int),
        greaterThanOrEqualTo(1),
      );
    } finally {
      for (final file in [advisoryOut, strictOut]) {
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    }
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

  test('GitHub release variable helper validates and redacts values', () {
    final helper = File(
      'scripts/configure_github_release_variables.ps1',
    ).readAsStringSync();

    for (final name in [
      'FLOWFIT_PUBLIC_WEB_BASE_URL',
      'FLOWFIT_WEB_BASE_HREF',
      'FLOWFIT_SUPPORT_EMAIL',
      'FLOWFIT_SUPPORT_EMAIL_VERIFIED',
      'SUPABASE_URL',
      'SUPABASE_PUBLISHABLE_KEY',
    ]) {
      expect(helper, contains(name));
    }

    expect(helper, contains('gh variable set'));
    expect(helper, contains('DryRun'));
    expect(helper, contains('redacted'));
    expect(helper, contains('sb_secret_'));
    expect(helper, contains('service_role'));
    expect(helper, contains('dnasghxxqwibwqnljvxr'));
    expect(helper, contains('REPLACE_WITH'));
    expect(
      helper,
      contains('SupportEmailVerified must be passed before setting true'),
    );
    expect(scriptsReadme, contains('configure_github_release_variables.ps1'));
    expect(
      storeSubmissionChecklist,
      contains('configure_github_release_variables.ps1'),
    );
    expect(
      releaseReadinessRunbook,
      contains('configure_github_release_variables.ps1'),
    );
  });

  test('GitHub release variable helper dry-run redacts publishable key', () {
    const publishableKey = 'sb_publishable_abcdefghijklmnopqrstuvwxyz123456';
    final env = Map<String, String>.from(Platform.environment)
      ..['FLOWFIT_PUBLIC_WEB_BASE_URL'] =
          'https://iron-mark.github.io/Hackathon-FlowFit/'
      ..['FLOWFIT_SUPPORT_EMAIL'] = 'support@flowfit.com'
      ..['FLOWFIT_SUPPORT_EMAIL_VERIFIED'] = 'true'
      ..['SUPABASE_URL'] = 'https://abcdefghijklmnop.supabase.co'
      ..['SUPABASE_PUBLISHABLE_KEY'] = publishableKey;

    final dryRun = Process.runSync('pwsh', [
      '-NoProfile',
      '-File',
      'scripts/configure_github_release_variables.ps1',
      '-Repo',
      'Iron-Mark/Hackathon-FlowFit',
      '-DryRun',
      '-SupportEmailVerified',
    ], environment: env);

    expect(dryRun.exitCode, 0, reason: '${dryRun.stdout}\n${dryRun.stderr}');
    expect(dryRun.stdout, contains('GH_RELEASE_VARIABLES_DRY_RUN_OK'));
    expect(dryRun.stdout, contains('SUPABASE_PUBLISHABLE_KEY=<redacted>'));
    expect(dryRun.stdout, isNot(contains(publishableKey)));

    final blocked = Process.runSync('pwsh', [
      '-NoProfile',
      '-File',
      'scripts/configure_github_release_variables.ps1',
      '-Repo',
      'Iron-Mark/Hackathon-FlowFit',
      '-DryRun',
    ], environment: env);

    expect(blocked.exitCode, isNot(0));
    expect(
      '${blocked.stdout}\n${blocked.stderr}',
      contains('SupportEmailVerified must be passed before setting true'),
    );
  });

  test('Supabase MCP helper validates project scope and release posture', () {
    for (final needle in [
      'project_ref',
      'features=database,docs,debugging,development',
      'read_only=true',
      'REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF',
      'dnasghxxqwibwqnljvxr',
      'SUPABASE_MCP_CONFIG_DRY_RUN_OK',
      'SUPABASE_MCP_CONFIG_WRITTEN_OK',
      'OAuth',
    ]) {
      expect(configureSupabaseMcp, contains(needle));
    }

    expect(configureSupabaseMcp, isNot(contains('SUPABASE_ACCESS_TOKEN')));
    expect(configureSupabaseMcp, isNot(contains('Authorization')));
    expect(scriptsReadme, contains('configure_supabase_mcp.ps1'));
    expect(supabaseRecoveryRunbook, contains('configure_supabase_mcp.ps1'));
    expect(releaseReadinessRunbook, contains('configure_supabase_mcp.ps1'));
    expect(storeSubmissionChecklist, contains('configure_supabase_mcp.ps1'));
  });

  test('Supabase MCP helper dry-run keeps target config untouched', () {
    final tempDir = Directory.systemTemp.createTempSync(
      'flowfit_mcp_helper_dry_run_',
    );
    try {
      final mcpFile = File('${tempDir.path}${Platform.pathSeparator}.mcp.json');
      final result = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/configure_supabase_mcp.ps1',
        '-ProjectRef',
        'abcdefghijklmnopqrst',
        '-McpConfigPath',
        mcpFile.path,
        '-DryRun',
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('SUPABASE_MCP_CONFIG_DRY_RUN_OK'));
      expect(
        result.stdout,
        contains(
          'https://mcp.supabase.com/mcp?project_ref=abcdefghijklmnopqrst&features=database,docs,debugging,development',
        ),
      );
      expect(result.stdout, isNot(contains('read_only=true')));
      expect(mcpFile.existsSync(), isFalse);
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Supabase MCP helper writes release read-only config JSON', () {
    final tempDir = Directory.systemTemp.createTempSync(
      'flowfit_mcp_helper_write_',
    );
    try {
      final mcpFile = File('${tempDir.path}${Platform.pathSeparator}.mcp.json');
      final result = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/configure_supabase_mcp.ps1',
        '-ProjectRef',
        'abcdefghijklmnopqrst',
        '-McpConfigPath',
        mcpFile.path,
        '-ReleaseReadOnly',
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('SUPABASE_MCP_CONFIG_WRITTEN_OK'));

      final json = jsonDecode(mcpFile.readAsStringSync()) as Map;
      final mcpServers = json['mcpServers'] as Map;
      final supabase = mcpServers['supabase'] as Map;
      expect(supabase['type'], 'http');
      expect(
        supabase['url'],
        'https://mcp.supabase.com/mcp?project_ref=abcdefghijklmnopqrst&features=database,docs,debugging,development&read_only=true',
      );
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Supabase MCP helper rejects placeholder and retired project refs', () {
    for (final invalidRef in [
      'REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF',
      'dnasghxxqwibwqnljvxr',
      'https://abcdefghijklmnopqrst.supabase.co',
    ]) {
      final result = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/configure_supabase_mcp.ps1',
        '-ProjectRef',
        invalidRef,
        '-DryRun',
      ]);

      expect(
        result.exitCode,
        isNot(0),
        reason: '$invalidRef should be rejected',
      );
      expect(
        '${result.stdout}\n${result.stderr}',
        contains('Supabase project ref'),
      );
    }
  });

  test('Supabase backend verification SQL is read-only and complete', () {
    expect(
      supabaseBackendVerificationSql,
      contains('flowfit_backend_verification'),
    );
    expect(
      supabaseBackendVerificationSql,
      contains('information_schema.columns'),
    );
    expect(supabaseBackendVerificationSql, contains('pg_policies'));
    expect(supabaseBackendVerificationSql, contains('role_table_grants'));
    expect(supabaseBackendVerificationSql, contains('relrowsecurity'));
    expect(supabaseBackendVerificationSql, contains('prosecdef = false'));
    expect(supabaseBackendVerificationSql, contains('expected_constraints'));
    expect(
      supabaseBackendVerificationSql,
      contains('workout_sessions_type_specific_fields_valid'),
    );
    expect(
      supabaseBackendVerificationSql,
      contains('required check constraints'),
    );
    expect(
      supabaseBackendVerificationSql,
      contains('account_deletion_requests_user_id_fkey'),
    );

    for (final table in [
      'user_profiles',
      'buddy_profiles',
      'workout_sessions',
      'heart_rate',
      'account_deletion_requests',
      'flowfit_recovery_quarantine',
    ]) {
      expect(supabaseBackendVerificationSql, contains(table));
    }

    for (final routine in [
      'request_account_deletion',
      'has_pending_account_deletion',
      'update_updated_at_column',
    ]) {
      expect(supabaseBackendVerificationSql, contains(routine));
    }

    for (final role in ['authenticated', 'anon', 'service_role']) {
      expect(supabaseBackendVerificationSql, contains(role));
    }

    expect(
      supabaseBackendVerificationSql,
      isNot(
        matches(
          RegExp(
            r'^\s*(create|alter|drop|delete|insert|update|truncate|grant|revoke|comment|begin|commit)\b',
            caseSensitive: false,
            multiLine: true,
          ),
        ),
      ),
    );
  });

  test('Supabase backend verification runner validates SQL safely', () {
    expect(verifySupabaseBackend, contains('supabase@latest'));
    expect(verifySupabaseBackend, contains('db'));
    expect(verifySupabaseBackend, contains('query'));
    expect(verifySupabaseBackend, contains('--linked'));
    expect(verifySupabaseBackend, contains('--local'));
    expect(verifySupabaseBackend, contains('--db-url'));
    expect(
      verifySupabaseBackend,
      contains('SUPABASE_BACKEND_VERIFICATION_SQL_OK'),
    );
    expect(
      verifySupabaseBackend,
      contains('SUPABASE_BACKEND_VERIFICATION_RUN_OK'),
    );
    expect(scriptsReadme, contains('scripts/verify_supabase_backend.ps1'));
    expect(
      supabaseRecoveryRunbook,
      contains('supabase/verification/verify_flowfit_backend.sql'),
    );
    expect(
      releaseReadinessRunbook,
      contains('scripts/verify_supabase_backend.ps1'),
    );
    expect(readinessAudit, contains('Supabase backend verification SQL'));
    expect(readinessAudit, contains('Supabase backend verification runner'));
    expect(readinessAudit, contains('verify_flowfit_backend.sql'));
    expect(readinessAudit, contains('verify_supabase_backend.ps1'));
    expect(readinessAudit, contains('Workout type-specific constraints'));
  });

  test('Supabase backend verification runner validates read-only SQL', () {
    final result = Process.runSync('pwsh', [
      '-NoProfile',
      '-File',
      'scripts/verify_supabase_backend.ps1',
      '-ValidateOnly',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('SUPABASE_BACKEND_VERIFICATION_SQL_OK'));
  });

  test('Supabase backend verification runner rejects mutating SQL', () {
    final tempDir = Directory.systemTemp.createTempSync(
      'flowfit_supabase_verifier_mutating_',
    );
    try {
      final sqlFile = File(
        '${tempDir.path}${Platform.pathSeparator}bad_verifier.sql',
      );
      sqlFile.writeAsStringSync('''
with flowfit_backend_verification as (select 1 as ok)
drop table public.user_profiles;
''');

      final result = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/verify_supabase_backend.ps1',
        '-SqlFile',
        sqlFile.path,
        '-ValidateOnly',
      ]);

      expect(result.exitCode, isNot(0));
      expect('${result.stdout}\n${result.stderr}', contains('read-only'));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('phone run wrapper passes required Supabase dart defines', () {
    expect(runPhoneScript, contains('SUPABASE_URL'));
    expect(runPhoneScript, contains('SUPABASE_PUBLISHABLE_KEY'));
    expect(runPhoneScript, contains('lib/secrets.dart'));
    expect(runPhoneScript, contains('--dart-define=SUPABASE_URL='));
    expect(runPhoneScript, contains('--dart-define=SUPABASE_PUBLISHABLE_KEY='));
    expect(runPhoneScript, contains('sb_secret_'));
    expect(runPhoneScript, contains('service_role'));
    expect(runPhoneScript, contains('dnasghxxqwibwqnljvxr'));
    expect(runPhoneBat, contains('run_phone.ps1'));
    expect(testPhoneBat, contains('run_phone.ps1'));
    expect(runPhoneBat, isNot(contains('flutter run -d 6ece264d')));
    expect(testPhoneBat, isNot(contains('flutter run -d 6ece264d')));
    expect(scriptsReadme, contains('scripts\\run_phone.ps1'));
    expect(
      scriptsReadme,
      contains('passes them to Flutter as `--dart-define` inputs'),
    );
  });

  test('phone run wrapper rejects placeholder Supabase env file', () {
    final tempDir = Directory.systemTemp.createTempSync(
      'flowfit_run_phone_test_',
    );
    try {
      final envFile =
          File('${tempDir.path}${Platform.pathSeparator}.env.release')
            ..writeAsStringSync('''
SUPABASE_URL=https://PROJECT_REF.supabase.co
SUPABASE_PUBLISHABLE_KEY=REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY
''');

      final result = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/run_phone.ps1',
        '-EnvFile',
        envFile.path,
      ]);

      expect(result.exitCode, isNot(0));
      expect(
        '${result.stdout}\n${result.stderr}',
        contains('environment Supabase URL still contains placeholder'),
      );
      expect(result.stdout, isNot(contains('Running phone app')));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
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

  test(
    'ci and preflight smoke builds use runtime-valid Supabase dummy values',
    () {
      const smokeUrl = 'https://abcdefghijklmnopqrst.supabase.co';
      const smokeKey = 'sb_publishable_abcdefghijklmnopqrstuvwxyz123456';

      for (final source in [ciWorkflow, releasePreflight]) {
        expect(source, contains('--dart-define=SUPABASE_URL=$smokeUrl'));
        expect(
          source,
          contains('--dart-define=SUPABASE_PUBLISHABLE_KEY=$smokeKey'),
        );
        expect(source, isNot(contains('https://example.supabase.co')));
        expect(source, isNot(contains('sb_publishable_smoke_not_for_auth')));
      }

      expect(scriptsReadme, contains('validation-shaped dummy'));
      expect(scriptsReadme, contains('Supabase client values as Dart defines'));
      expect(
        releaseReadinessRunbook,
        contains('validation-shaped dummy Supabase client Dart defines'),
      );
    },
  );

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
    expect(webDeploymentVerifier, contains('Resolve-IndexBaseUri'));
    expect(webDeploymentVerifier, contains('Assert-SupportEmail'));
    expect(webDeploymentVerifier, contains('flutter_bootstrap.js'));
    expect(webDeploymentVerifier, contains('main.dart.js'));
    expect(webDeploymentVerifier, contains('/privacy.html'));
    expect(webDeploymentVerifier, contains('/account-deletion.html'));
    expect(webDeploymentVerifier, contains('manifest.json'));
    expect(webDeploymentVerifier, contains('FLOWFIT_SUPPORT_EMAIL'));
    expect(webDeploymentVerifier, contains('FlowFit Privacy Policy'));
    expect(webDeploymentVerifier, contains('FlowFit Account Deletion'));
    expect(webDeploymentVerifier, contains('without reinstalling the app'));
    expect(webDeploymentVerifier, contains('ConvertTo-Json'));
    expect(webDeploymentVerifier, contains('[string]\$OutFile'));
  });

  test(
    'web deployment verifier rejects mismatched Flutter base href',
    () async {
      final result = await _runWebDeploymentVerifierAgainstFixture(
        baseHref: '/',
      );

      expect(result.exitCode, isNot(0));
      expect(
        '${result.stdout}\n${result.stderr}',
        contains('Flutter base href'),
      );
    },
  );

  test('web deployment verifier rejects HTML-unsafe support emails', () async {
    final result = await _runWebDeploymentVerifierAgainstFixture(
      baseHref: '/app/',
      supportEmail: 'support"><script@flowfit.com',
    );

    expect(result.exitCode, isNot(0));
    expect(
      '${result.stdout}\n${result.stderr}',
      contains('SupportEmail must be a valid support email address'),
    );
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
    expect(ciWorkflow, contains('android-actions/setup-android@v4'));
    expect(
      ciWorkflow.indexOf('android-actions/setup-android@v4'),
      lessThan(ciWorkflow.indexOf('sdkmanager "platforms;android-36"')),
    );
  });

  test('GitHub workflows use current Node 24 action majors', () {
    expect(ciWorkflow, contains('FORCE_JAVASCRIPT_ACTIONS_TO_NODE24'));
    expect(pagesWorkflow, contains('FORCE_JAVASCRIPT_ACTIONS_TO_NODE24'));
    for (final workflow in [ciWorkflow, pagesWorkflow]) {
      expect(workflow, contains('actions/checkout@v6'));
      expect(workflow, contains('actions/upload-artifact@v7'));
      expect(workflow, isNot(contains('actions/checkout@v4')));
      expect(workflow, isNot(contains('actions/upload-artifact@v4')));
    }
    expect(ciWorkflow, contains('actions/setup-java@v5'));
    expect(ciWorkflow, contains('android-actions/setup-android@v4'));
    expect(ciWorkflow, isNot(contains('actions/setup-java@v4')));
    expect(ciWorkflow, isNot(contains('android-actions/setup-android@v3')));
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

  test('ci frees disk before Android builds', () {
    expect(ciWorkflow, contains('Free CI disk space'));
    expect(
      ciWorkflow,
      contains('Free web artifact build outputs before Android'),
    );

    final webUploadIndex = ciWorkflow.indexOf('Upload web build artifact');
    final webCleanupIndex = ciWorkflow.indexOf(
      'Free web artifact build outputs before Android',
    );
    final androidBuildIndex = ciWorkflow.indexOf('Android debug APK build');

    expect(webUploadIndex, isNonNegative);
    expect(webCleanupIndex, isNonNegative);
    expect(androidBuildIndex, isNonNegative);
    expect(webUploadIndex, lessThan(webCleanupIndex));
    expect(webCleanupIndex, lessThan(androidBuildIndex));
  });

  test('GitHub Pages workflow publishes production web artifacts', () {
    expect(pagesWorkflow, contains('name: Flutter Web Pages'));
    expect(pagesWorkflow, contains('deploy-ready:'));
    expect(
      pagesWorkflow,
      contains('if: needs.deploy-ready.outputs.ready == \'true\''),
    );
    expect(
      pagesWorkflow,
      contains('production web deploy variables are not configured'),
    );
    expect(releaseReadinessRunbook, contains('deploy-ready'));
    expect(releaseReadinessRunbook, contains('skips production GitHub Pages'));
    expect(releaseReadinessRunbook, contains('deployment with a notice'));
    expect(pagesWorkflow, contains('actions/configure-pages@v6'));
    expect(pagesWorkflow, contains('actions/upload-pages-artifact@v5'));
    expect(pagesWorkflow, contains('actions/deploy-pages@v5'));
    expect(pagesWorkflow, contains('actions/upload-artifact@v7'));
    expect(pagesWorkflow, contains('scripts/store_release_build.ps1'));
    expect(pagesWorkflow, contains('-Target Web'));
    expect(pagesWorkflow, contains('-SkipFlutterPubGet'));
    expect(pagesWorkflow, contains('FLOWFIT_PUBLIC_WEB_BASE_URL'));
    expect(pagesWorkflow, contains('SUPABASE_URL'));
    expect(pagesWorkflow, contains('SUPABASE_PUBLISHABLE_KEY'));
    expect(pagesWorkflow, contains('FLOWFIT_SUPPORT_EMAIL_VERIFIED'));
    expect(
      pagesWorkflow,
      contains(
        'Set FLOWFIT_SUPPORT_EMAIL_VERIFIED=true only after the configured support inbox is receiving mail.',
      ),
    );
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

  test('strict audit rejects public web URLs with query strings', () {
    final env = Map<String, String>.from(Platform.environment)
      ..['FLOWFIT_PUBLIC_WEB_BASE_URL'] = 'https://flowfit.app?preview=true'
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
    expect(
      '${audit.stdout}\n${audit.stderr}',
      contains('query strings or fragments'),
    );
  });

  test('strict audit can use GitHub repository variable evidence', () {
    final tempDir = Directory.systemTemp.createTempSync(
      'flowfit_github_variables_audit_',
    );
    try {
      final variablesFile = File(
        '${tempDir.path}${Platform.pathSeparator}github-vars.json',
      );
      variablesFile.writeAsStringSync('''
[
  {
    "name": "FLOWFIT_PUBLIC_WEB_BASE_URL",
    "value": "https://iron-mark.github.io/Hackathon-FlowFit/"
  },
  {
    "name": "FLOWFIT_SUPPORT_EMAIL",
    "value": "support@flowfit.com"
  },
  {
    "name": "FLOWFIT_SUPPORT_EMAIL_VERIFIED",
    "value": "true"
  },
  {
    "name": "SUPABASE_URL",
    "value": "https://abcdefghijklmnop.supabase.co"
  },
  {
    "name": "SUPABASE_PUBLISHABLE_KEY",
    "value": "sb_publishable_abcdefghijklmnopqrstuvwxyz123456"
  }
]
''');

      final mcpFile = File('${tempDir.path}${Platform.pathSeparator}.mcp.json');
      mcpFile.writeAsStringSync(
        '{"mcpServers":{"supabase":{"type":"http","url":"https://mcp.supabase.com/mcp?project_ref=abcdefghijklmnop&features=database,docs,debugging,development&read_only=true"}}}',
      );

      final env = Map<String, String>.from(Platform.environment)
        ..['FLOWFIT_PUBLIC_WEB_BASE_URL'] = ''
        ..['FLOWFIT_SUPPORT_EMAIL'] = ''
        ..['FLOWFIT_SUPPORT_EMAIL_VERIFIED'] = ''
        ..['SUPABASE_URL'] = ''
        ..['SUPABASE_PUBLISHABLE_KEY'] = ''
        ..['FLOWFIT_ANDROID_KEYSTORE_BASE64'] = 'ZmFrZS1rZXlzdG9yZQ=='
        ..['FLOWFIT_ANDROID_KEYSTORE_PASSWORD'] = 'store-password'
        ..['FLOWFIT_ANDROID_KEY_ALIAS'] = 'upload'
        ..['FLOWFIT_ANDROID_KEY_PASSWORD'] = 'key-password';

      final audit = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/release_readiness_audit.ps1',
        '-Strict',
        '-GitHubVariablesPath',
        variablesFile.path,
        '-McpConfigPath',
        mcpFile.path,
      ], environment: env);

      expect(audit.exitCode, 0, reason: '${audit.stdout}\n${audit.stderr}');
      expect(
        '${audit.stdout}\n${audit.stderr}',
        contains('GitHub release variables'),
      );
      expect(
        '${audit.stdout}\n${audit.stderr}',
        isNot(contains('sb_publishable_abcdefghijklmnopqrstuvwxyz123456')),
      );
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('recovery audit rejects read-only Supabase MCP config', () {
    final audit = _runAuditWithMcpConfig(
      'https://mcp.supabase.com/mcp?project_ref=abcdefghijklmnop&features=database,docs,debugging,development&read_only=true',
    );

    expect(audit.exitCode, isNot(0));
    expect(
      '${audit.stdout}\n${audit.stderr}',
      contains('[FAIL] Supabase MCP recovery write access'),
    );
  });

  test('strict release audit requires read-only Supabase MCP config', () {
    final writableAudit = _runAuditWithMcpConfig(
      'https://mcp.supabase.com/mcp?project_ref=abcdefghijklmnop&features=database,docs,debugging,development',
      strict: true,
    );

    expect(writableAudit.exitCode, isNot(0));
    expect(
      '${writableAudit.stdout}\n${writableAudit.stderr}',
      contains('[FAIL] Supabase MCP release read-only'),
    );

    final readOnlyAudit = _runAuditWithMcpConfig(
      'https://mcp.supabase.com/mcp?project_ref=abcdefghijklmnop&features=database,docs,debugging,development&read_only=true',
      strict: true,
    );

    expect(
      '${readOnlyAudit.stdout}\n${readOnlyAudit.stderr}',
      contains('[PASS] Supabase MCP release read-only'),
    );
    expect(
      '${readOnlyAudit.stdout}\n${readOnlyAudit.stderr}',
      isNot(contains('[FAIL] Supabase MCP recovery write access')),
    );
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
    expect(readinessAudit, contains('verify_support_inbox.ps1'));
    expect(supportInboxVerifier, contains('ConfirmedInbound'));
    expect(supportInboxVerifier, contains('EvidenceNote is required'));
    expect(supportInboxVerifier, contains('FLOWFIT_SUPPORT_EMAIL_VERIFIED'));
    expect(supportInboxVerifier, contains('Resolve-MxEvidence'));
    expect(
      supportInboxVerifier,
      contains('manual-inbound-confirmation-required'),
    );
    expect(supportInboxVerifier, contains('SUPPORT_INBOX_EVIDENCE_WRITTEN'));
    expect(supportInboxVerifier, contains('exit 2'));
    expect(scriptsReadme, contains('verify_support_inbox.ps1'));
    expect(releaseReadinessRunbook, contains('verify_support_inbox.ps1'));
    expect(storeSubmissionChecklist, contains('verify_support_inbox.ps1'));
    expect(storeReleaseBuild, contains('valid support email address'));
    expect(webDeploymentVerifier, contains('valid support email address'));
    expect(storeReleaseBuild, contains(r'^[A-Za-z0-9._+-]+@[A-Za-z0-9]'));
    expect(webDeploymentVerifier, contains(r'^[A-Za-z0-9._+-]+@[A-Za-z0-9]'));
  });

  test('support inbox verifier writes evidence with guarded exit codes', () {
    final unique = '${DateTime.now().microsecondsSinceEpoch}_$pid';
    final inventoryOut = File('build/support-inbox-inventory-$unique.json');
    final missingNoteOut = File(
      'build/support-inbox-missing-note-$unique.json',
    );
    final confirmedOut = File('build/support-inbox-confirmed-$unique.json');

    try {
      final inventory = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/verify_support_inbox.ps1',
        '-SupportEmail',
        'support@flowfit.com',
        '-SkipDns',
        '-OutFile',
        inventoryOut.path,
      ]);
      expect(
        inventory.exitCode,
        2,
        reason: '${inventory.stdout}\n${inventory.stderr}',
      );
      expect(inventory.stdout, contains('SUPPORT_INBOX_EVIDENCE_WRITTEN'));
      final inventoryJson =
          jsonDecode(inventoryOut.readAsStringSync()) as Map<String, dynamic>;
      expect(inventoryJson['confirmedInbound'], false);
      expect(inventoryJson['summary'], 'manual-inbound-confirmation-required');
      expect(
        (inventoryJson['releaseVariable'] as Map<String, dynamic>)['name'],
        'FLOWFIT_SUPPORT_EMAIL_VERIFIED',
      );
      expect(
        (inventoryJson['releaseVariable']
            as Map<String, dynamic>)['valueWhenReady'],
        'false',
      );
      expect((inventoryJson['sourceOccurrences'] as List<dynamic>), isNotEmpty);
      expect(
        (inventoryJson['dnsMx'] as Map<String, dynamic>)['status'],
        'skipped',
      );

      final missingNote = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/verify_support_inbox.ps1',
        '-SupportEmail',
        'support@flowfit.com',
        '-ConfirmedInbound',
        '-SkipDns',
        '-OutFile',
        missingNoteOut.path,
      ]);
      expect(missingNote.exitCode, isNot(0));
      expect(
        '${missingNote.stdout}\n${missingNote.stderr}',
        contains('EvidenceNote is required'),
      );
      expect(missingNoteOut.existsSync(), isFalse);

      final confirmed = Process.runSync('pwsh', [
        '-NoProfile',
        '-File',
        'scripts/verify_support_inbox.ps1',
        '-SupportEmail',
        'support@flowfit.com',
        '-ConfirmedInbound',
        '-EvidenceNote',
        'Received external test email during automated smoke coverage',
        '-SkipDns',
        '-OutFile',
        confirmedOut.path,
      ]);
      expect(
        confirmed.exitCode,
        0,
        reason: '${confirmed.stdout}\n${confirmed.stderr}',
      );
      expect(confirmed.stdout, contains('SUPPORT_INBOX_EVIDENCE_WRITTEN'));
      final confirmedJson =
          jsonDecode(confirmedOut.readAsStringSync()) as Map<String, dynamic>;
      expect(confirmedJson['confirmedInbound'], true);
      expect(
        confirmedJson['summary'],
        'ready-for-release-variable-dns-skipped',
      );
      expect(
        (confirmedJson['releaseVariable']
            as Map<String, dynamic>)['valueWhenReady'],
        'true',
      );
      expect(
        confirmedJson['evidenceNote'],
        'Received external test email during automated smoke coverage',
      );
    } finally {
      for (final file in [inventoryOut, missingNoteOut, confirmedOut]) {
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    }
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

  test('store docs and manifests keep location foreground-only', () {
    final privacyDataMap = File('docs/PRIVACY_DATA_MAP.md').readAsStringSync();
    final storeMetadata = File(
      'docs/STORE_METADATA_DRAFT.md',
    ).readAsStringSync();
    final storeChecklist = File(
      'docs/STORE_SUBMISSION_CHECKLIST.md',
    ).readAsStringSync();
    final mapMissionsUserFlow = File(
      'docs/MAP_MISSIONS_USER_FLOW.md',
    ).readAsStringSync();
    final mapFeatureGuide = File(
      'docs/MAP_FEATURE_GUIDE.md',
    ).readAsStringSync();
    final geofenceService = File(
      'lib/features/wellness/services/geofence_service.dart',
    ).readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(
      privacyDataMap,
      contains('Release builds are foreground-location only'),
    );
    expect(
      privacyDataMap,
      isNot(contains('Release builds request background location')),
    );
    expect(
      storeMetadata,
      contains('foreground location for wellness missions'),
    );
    expect(
      mapMissionsUserFlow,
      contains('Closed-app mission tracking stays future work'),
    );
    expect(
      mapMissionsUserFlow,
      isNot(contains('Required for mission tracking when app is closed')),
    );
    expect(mapFeatureGuide, contains('Foreground Tracking'));
    expect(
      mapFeatureGuide,
      isNot(contains('Monitors location even when app is closed')),
    );
    expect(mapFeatureGuide, isNot(contains('Uses native geofencing APIs')));
    expect(storeChecklist, contains('foreground-only wellness routes'));
    expect(androidMainManifest, isNot(contains('ACCESS_BACKGROUND_LOCATION')));
    expect(androidMainManifest, isNot(contains('NativeGeofence')));
    expect(iosInfoPlist, isNot(contains('UIBackgroundModes')));
    expect(iosInfoPlist, isNot(contains('NSLocationAlways')));
    expect(pubspec, isNot(contains('native_geofence')));
    expect(geofenceService, isNot(contains('GeofenceNative.register')));
  });

  test('wellness UI discloses location and backend sync accurately', () {
    final wellnessOnboarding = File(
      'lib/screens/wellness/wellness_onboarding_screen.dart',
    ).readAsStringSync();
    final wellnessSettings = File(
      'lib/screens/wellness/wellness_settings_screen.dart',
    ).readAsStringSync();
    final wellnessMap = File(
      'lib/widgets/wellness/wellness_map_widget.dart',
    ).readAsStringSync();

    expect(wellnessOnboarding, contains('foreground geofence'));
    expect(wellnessOnboarding, contains('Supabase'));
    expect(wellnessSettings, contains('Supabase'));
    expect(wellnessMap, contains('_showLocationPermissionDisclosure'));
    expect(
      wellnessMap.indexOf('_prepareLocationAccess'),
      lessThan(wellnessMap.indexOf('_getUserLocation();')),
    );
    expect(
      '$wellnessOnboarding\n$wellnessSettings',
      isNot(contains('No data is sent to external servers')),
    );
    expect(
      '$wellnessOnboarding\n$wellnessSettings',
      isNot(contains('Nothing is sent to external servers')),
    );
  });

  test('active settings screen exposes account deletion route', () {
    final activeSettings = File(
      'lib/screens/profile/settings/settings_screen.dart',
    ).readAsStringSync();
    final legacySettings = File(
      'lib/screens/profile/settings_screen.dart',
    ).readAsStringSync();

    for (final source in [activeSettings, legacySettings]) {
      expect(source, contains('Delete Account'));
      expect(
        source,
        contains("Navigator.pushNamed(context, '/delete-account')"),
      );
    }
  });
}

ProcessResult _runAndroidSigningEnvFixture() {
  final tempDir = Directory.systemTemp.createTempSync(
    'flowfit_android_signing_fixture_',
  );
  try {
    final fixtureScript = File(
      '${tempDir.path}${Platform.pathSeparator}android_signing_fixture.ps1',
    );
    fixtureScript.writeAsStringSync(r'''
param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,
    [Parameter(Mandatory = $true)]
    [string]$FixtureRoot
)

$ErrorActionPreference = 'Stop'

function Assert-Condition {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$storeReleaseBuildPath = Join-Path $RepoRoot 'scripts/store_release_build.ps1'
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $storeReleaseBuildPath,
    [ref]$tokens,
    [ref]$parseErrors
)
if ($parseErrors.Count -gt 0) {
    throw ($parseErrors | Out-String)
}

foreach ($name in @(
    'Get-OptionalEnv',
    'Initialize-AndroidSigningFromEnv',
    'Remove-GeneratedAndroidSigningFiles'
)) {
    $functionAst = $ast.Find({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -eq $name
    }, $true)
    Assert-Condition ($null -ne $functionAst) "Missing function in production script: $name"
    Invoke-Expression $functionAst.Extent.Text
}

$repoRoot = (Resolve-Path $FixtureRoot).Path
$androidDir = Join-Path $repoRoot 'android'
New-Item -ItemType Directory -Force -Path $androidDir | Out-Null

$script:generatedAndroidSigningFiles = New-Object System.Collections.Generic.List[string]
[Environment]::SetEnvironmentVariable('FLOWFIT_ANDROID_KEYSTORE_BASE64', 'ZmFrZS1rZXlzdG9yZQ==', 'Process')
[Environment]::SetEnvironmentVariable('FLOWFIT_ANDROID_KEYSTORE_PASSWORD', 'store-password', 'Process')
[Environment]::SetEnvironmentVariable('FLOWFIT_ANDROID_KEY_ALIAS', 'upload', 'Process')
[Environment]::SetEnvironmentVariable('FLOWFIT_ANDROID_KEY_PASSWORD', 'key-password', 'Process')

$keyPropertiesPath = Join-Path $repoRoot 'android/key.properties'
$keystorePath = Join-Path $repoRoot 'android/upload-keystore.jks'

try {
    Initialize-AndroidSigningFromEnv

    Assert-Condition (Test-Path -LiteralPath $keyPropertiesPath) 'Generated key.properties was not created.'
    Assert-Condition (Test-Path -LiteralPath $keystorePath) 'Generated keystore was not created.'

    $properties = Get-Content -Raw -LiteralPath $keyPropertiesPath
    Assert-Condition ($properties.Contains('storePassword=store-password')) 'Generated key.properties is missing storePassword.'
    Assert-Condition ($properties.Contains('keyPassword=key-password')) 'Generated key.properties is missing keyPassword.'
    Assert-Condition ($properties.Contains('keyAlias=upload')) 'Generated key.properties is missing keyAlias.'
    Assert-Condition ($properties.Contains('storeFile=upload-keystore.jks')) 'Generated key.properties is missing storeFile.'

    $keystoreText = [System.Text.Encoding]::UTF8.GetString(
        [System.IO.File]::ReadAllBytes($keystorePath)
    )
    Assert-Condition ($keystoreText -eq 'fake-keystore') 'Generated keystore bytes do not match env base64.'

    Remove-GeneratedAndroidSigningFiles

    Assert-Condition (-not (Test-Path -LiteralPath $keyPropertiesPath)) 'Generated key.properties was not removed.'
    Assert-Condition (-not (Test-Path -LiteralPath $keystorePath)) 'Generated keystore was not removed.'

    $script:generatedAndroidSigningFiles = New-Object System.Collections.Generic.List[string]
    Set-Content -LiteralPath $keystorePath -Value 'existing-keystore' -NoNewline

    try {
        Initialize-AndroidSigningFromEnv
        throw 'Expected overwrite failure did not occur.'
    } catch {
        if ($_.Exception.Message -notmatch 'Refusing to overwrite existing Android upload keystore') {
            throw
        }
    }

    Assert-Condition (-not (Test-Path -LiteralPath $keyPropertiesPath)) 'key.properties was created after overwrite refusal.'
    Assert-Condition (Test-Path -LiteralPath $keystorePath) 'Existing keystore was removed after overwrite refusal.'
    Assert-Condition ((Get-Content -Raw -LiteralPath $keystorePath) -eq 'existing-keystore') 'Existing keystore contents changed.'

    Remove-GeneratedAndroidSigningFiles
    Assert-Condition (Test-Path -LiteralPath $keystorePath) 'Cleanup removed an existing keystore not created by this invocation.'

    Write-Output 'ANDROID_SIGNING_ENV_FIXTURE_OK'
} finally {
    foreach ($name in @(
        'FLOWFIT_ANDROID_KEYSTORE_BASE64',
        'FLOWFIT_ANDROID_KEYSTORE_PASSWORD',
        'FLOWFIT_ANDROID_KEY_ALIAS',
        'FLOWFIT_ANDROID_KEY_PASSWORD',
        'FLOWFIT_ANDROID_KEYSTORE_FILE_NAME'
    )) {
        [Environment]::SetEnvironmentVariable($name, $null, 'Process')
    }
}
''');

    return Process.runSync('pwsh', [
      '-NoProfile',
      '-File',
      fixtureScript.path,
      '-RepoRoot',
      Directory.current.path,
      '-FixtureRoot',
      tempDir.path,
    ]);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

Future<ProcessResult> _runWebDeploymentVerifierAgainstFixture({
  required String baseHref,
  String supportEmail = 'support@flowfit.com',
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  late final StreamSubscription<HttpRequest> subscription;

  subscription = server.listen((request) {
    final path = request.uri.path;
    final response = request.response;

    switch (path) {
      case '/app/':
        response.headers.contentType = ContentType.html;
        response.write('''
<!doctype html>
<html>
<head>
  <base href="$baseHref">
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
  manifest.json
</body>
</html>
''');
      case '/app/flutter_bootstrap.js':
        response.headers.contentType = ContentType('application', 'javascript');
        response.write("import('./main.dart.js');");
      case '/app/main.dart.js':
        response.headers.contentType = ContentType('application', 'javascript');
        response.write('function main() {}');
      case '/app/manifest.json':
        response.headers.contentType = ContentType.json;
        response.write('{"name": "FlowFit", "short_name": "FlowFit"}');
      case '/app/privacy.html':
        response.headers.contentType = ContentType.html;
        response.write('''
<title>FlowFit Privacy Policy</title>
$supportEmail
account-deletion.html
account and associated app data
''');
      case '/app/account-deletion.html':
        response.headers.contentType = ContentType.html;
        response.write('''
<title>FlowFit Account Deletion</title>
mailto:$supportEmail
privacy.html
FlowFit account deletion request
associated app data
without reinstalling the app
Profile &gt; Settings &gt; Delete Account
''');
      default:
        response.statusCode = HttpStatus.notFound;
        response.write('not found');
    }

    response.close();
  });

  try {
    return await Process.run('pwsh', [
      '-NoProfile',
      '-File',
      'scripts/verify_web_deployment.ps1',
      '-BaseUrl',
      'http://127.0.0.1:${server.port}/app',
      '-SupportEmail',
      supportEmail,
      '-AllowInsecureLocalhost',
      '-TimeoutSeconds',
      '5',
    ]);
  } finally {
    await subscription.cancel();
    await server.close(force: true);
  }
}

ProcessResult _runAuditWithMcpConfig(String url, {bool strict = false}) {
  final tempDir = Directory.systemTemp.createTempSync('flowfit_mcp_audit_');
  try {
    final mcpFile = File('${tempDir.path}${Platform.pathSeparator}.mcp.json');
    mcpFile.writeAsStringSync(
      '{"mcpServers":{"supabase":{"type":"http","url":"$url"}}}',
    );

    final env = Map<String, String>.from(Platform.environment)
      ..['FLOWFIT_PUBLIC_WEB_BASE_URL'] = 'https://flowfit.app'
      ..['FLOWFIT_SUPPORT_EMAIL_VERIFIED'] = 'true'
      ..['SUPABASE_URL'] = 'https://abcdefghijklmnop.supabase.co'
      ..['SUPABASE_PUBLISHABLE_KEY'] =
          'sb_publishable_abcdefghijklmnopqrstuvwxyz123456';

    return Process.runSync('pwsh', [
      '-NoProfile',
      '-File',
      'scripts/release_readiness_audit.ps1',
      '-McpConfigPath',
      mcpFile.path,
      if (strict) '-Strict',
      if (strict) '-SupportEmailVerified',
    ], environment: env);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
