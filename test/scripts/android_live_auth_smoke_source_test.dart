import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  late String scriptsReadme;
  late String offlineVerifier;

  setUpAll(() {
    source = File(
      'scripts/verify_android_live_auth_smoke.ps1',
    ).readAsStringSync();
    scriptsReadme = File('docs/scripts/README.md').readAsStringSync();
    offlineVerifier = File(
      'scripts/verify_offline_app_actions.ps1',
    ).readAsStringSync();
  });

  test('Android live auth smoke verifier exists and is documented', () {
    expect(source, contains('ANDROID_LIVE_AUTH_SMOKE_EVIDENCE_WRITTEN'));
    expect(scriptsReadme, contains('verify_android_live_auth_smoke.ps1'));
    expect(
      offlineVerifier,
      contains('android_live_auth_smoke_source_test.dart'),
    );
  });

  test(
    'Android live auth smoke verifier builds configured phone APK safely',
    () {
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
      expect(
        source,
        isNot(contains(r'Write-Output $($config.PublishableKey)')),
      );
    },
  );

  test(
    'Android live auth smoke requires dedicated redacted smoke credentials',
    () {
      for (final token in [
        'FLOWFIT_SMOKE_EMAIL',
        'FLOWFIT_SMOKE_PASSWORD',
        'FLOWFIT_LIVE_SMOKE_EMAIL',
        'FLOWFIT_LIVE_SMOKE_PASSWORD',
        'Assert-SmokeEmail',
        'Get-RedactedEmail',
        'password redacted',
        'Sensitive',
        'value redacted',
        'No shell command implementation',
        'exclamation mark',
      ]) {
        expect(source, contains(token));
      }

      expect(source, isNot(contains('SUPABASE_SERVICE_ROLE_KEY')));
      expect(source, isNot(contains('supabasePublishableKey')));
      expect(source, isNot(contains('publishableKey =')));
      expect(source, isNot(contains(r'Write-Host $credentials')));
      expect(source, isNot(contains(r'Write-Output $credentials')));
    },
  );

  test('Android live auth smoke exercises login and onboarding buttons', () {
    for (final token in [
      'install',
      '-r',
      '-d',
      'pm',
      'clear',
      'am',
      'start',
      '-W',
      'uiautomator',
      'dump',
      'screencap',
      'input',
      'tap',
      'keyevent',
      '279',
    ]) {
      expect(source, contains("'$token'"));
    }

    for (final text in [
      'Find Your Flow',
      'Log In',
      'Welcome Back!',
      'Enter your email',
      'Enter your password',
      'Welcome to FlowFit!',
      "I'm 13 or older",
      'Quick Setup',
      "Let's Personalize",
      'Tell us about yourself',
      'Continue',
    ]) {
      expect(source, contains(text));
    }
  });

  test('Android live auth smoke catches setup, auth, and native crashes', () {
    for (final token in [
      'FlowFit setup is incomplete',
      'SUPABASE_URL must',
      'SUPABASE_PUBLISHABLE_KEY must',
      'Invalid login credentials',
      'Email not confirmed',
      'Could not check onboarding status',
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
  });

  test('Android live auth smoke writes non-secret evidence', () {
    for (final token in [
      'schemaVersion',
      'generatedAt',
      'status',
      'checks',
      'artifacts',
      'supabaseConfigSource',
      'supabaseProjectHost',
      'smokeEmail',
      'ConvertTo-Json',
      'Set-Content',
    ]) {
      expect(source, contains(token));
    }

    expect(source, isNot(contains(r'$credentials.Password |')));
    expect(source, isNot(contains(r'$credentials.Email |')));
  });
}
