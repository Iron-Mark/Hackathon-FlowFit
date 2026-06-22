import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  late String scriptsReadme;
  late String offlineVerifier;

  setUpAll(() {
    source = File('scripts/verify_android_phone_smoke.ps1').readAsStringSync();
    scriptsReadme = File('docs/scripts/README.md').readAsStringSync();
    offlineVerifier = File(
      'scripts/verify_offline_app_actions.ps1',
    ).readAsStringSync();
  });

  test('Android phone smoke verifier exists and is documented', () {
    expect(source, contains('ANDROID_PHONE_SMOKE_EVIDENCE_WRITTEN'));
    expect(scriptsReadme, contains('verify_android_phone_smoke.ps1'));
    expect(offlineVerifier, contains('android_phone_smoke_source_test.dart'));
  });

  test('Android phone smoke verifier builds configured phone APK safely', () {
    for (final token in [
      '--target-platform',
      '--split-per-abi',
      '--no-pub',
      'lib/main.dart',
      '--dart-define=SUPABASE_URL=',
      '--dart-define=SUPABASE_PUBLISHABLE_KEY=',
      '--dart-define=FLOWFIT_AUTH_SCHEME=',
      'com.msiazondev.flowfit',
    ]) {
      expect(source, contains(token));
    }

    expect(source, isNot(contains(r'Write-Host $($config.PublishableKey)')));
    expect(source, isNot(contains(r'Write-Output $($config.PublishableKey)')));
  });

  test(
    'Android phone smoke verifier exercises native launch and UI actions',
    () {
      for (final token in [
        'install',
        '-r',
        '-d',
        'pm',
        'clear',
        'am',
        'start',
        '-W',
        'pidof',
        'dumpsys',
        'window',
        'uiautomator',
        'dump',
        'screencap',
        'input',
        'tap',
        'input',
        'swipe',
      ]) {
        expect(source, contains("'$token'"));
      }

      for (final text in [
        'Find Your Flow',
        'Get Started',
        'Create Your Account',
        'Read Terms',
        'Read Policy',
        'Welcome Back!',
        'Forgot password?',
        'Please enter your email',
        'Sign Up',
      ]) {
        expect(source, contains(text));
      }
    },
  );

  test(
    'Android phone smoke verifier catches setup and native crash regressions',
    () {
      for (final token in [
        'FlowFit setup is incomplete',
        'SUPABASE_URL must',
        'SUPABASE_PUBLISHABLE_KEY must',
        'logcat',
        '-c',
        '-d',
        'GeneratedPluginRegistrant',
        'GeneratedPluginsRegister',
        'NoClassDefFoundError',
        'FATAL EXCEPTION',
        'Error registering Flutter plugin',
        'AndroidRuntime',
      ]) {
        expect(source, contains(token));
      }
    },
  );

  test('Android phone smoke verifier writes redacted evidence', () {
    for (final token in [
      'schemaVersion',
      'generatedAt',
      'status',
      'checks',
      'artifacts',
      'supabaseConfigSource',
      'supabaseProjectHost',
      'key redacted',
      'ConvertTo-Json',
      'Set-Content',
    ]) {
      expect(source, contains(token));
    }

    expect(source, isNot(contains('supabasePublishableKey')));
    expect(source, isNot(contains('publishableKey =')));
  });
}
