import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  late String scriptsReadme;
  late String offlineVerifier;

  setUpAll(() {
    source = File('scripts/verify_wear_emulator_smoke.ps1').readAsStringSync();
    scriptsReadme = File('docs/scripts/README.md').readAsStringSync();
    offlineVerifier = File(
      'scripts/verify_offline_app_actions.ps1',
    ).readAsStringSync();
  });

  test('Wear emulator smoke verifier exists and is documented', () {
    expect(source, contains('WEAR_EMULATOR_SMOKE_EVIDENCE_WRITTEN'));
    expect(scriptsReadme, contains('verify_wear_emulator_smoke.ps1'));
    expect(offlineVerifier, contains('wear_emulator_smoke_source_test.dart'));
  });

  test('Wear emulator smoke verifier builds Wear entrypoint safely', () {
    for (final token in [
      '--target-platform',
      '--split-per-abi',
      '--no-pub',
      'lib/main_wear.dart',
      'com.msiazondev.flowfit',
    ]) {
      expect(source, contains(token));
    }

    expect(source, isNot(contains('SUPABASE_PUBLISHABLE_KEY')));
    expect(source, isNot(contains('publishableKey')));
    expect(source, isNot(contains('FLOWFIT_SMOKE_PASSWORD')));
  });

  test(
    'Wear emulator smoke verifier exercises dashboard and heart-rate flow',
    () {
      for (final token in [
        'install',
        '-r',
        '-d',
        'pm',
        'clear',
        'grant',
        'am',
        'start',
        '-W',
        'pidof',
        'uiautomator',
        'dump',
        'screencap',
        'input',
        'tap',
        'keyevent',
      ]) {
        expect(source, contains("'$token'"));
      }

      for (final text in [
        'FlowFit',
        'Heart Rate',
        'BPM',
        'Start',
        'Samsung Health service unavailable',
        'Simulated',
        'Stop',
      ]) {
        expect(source, contains(text));
      }
    },
  );

  test('Wear emulator smoke verifier writes non-secret evidence', () {
    for (final token in [
      'schemaVersion',
      'generatedAt',
      'status',
      'checks',
      'artifacts',
      'device',
      'ConvertTo-Json',
      'Set-Content',
      'logcat',
      'AndroidRuntime',
      'GeneratedPluginRegistrant',
      'FLOWFIT_WEAR_SIMULATED_FALLBACK_STARTED',
      'FLOWFIT_WEAR_SIMULATED_FALLBACK_STOPPED',
    ]) {
      expect(source, contains(token));
    }
  });

  test('Wear emulator smoke verifier bounds failure logcat capture', () {
    for (final token in [
      'Invoke-ExternalWithTimeout',
      'Start-Process',
      'WaitForExit',
      'Save-Logcat',
      'TimeoutSeconds',
      'logcat capture timed out',
      'uiautomator dump failed',
      'Wait-ForUiTextOrLogText',
      'Invoke-TapTextOrCoordinates',
    ]) {
      expect(source, contains(token));
    }
  });
}
