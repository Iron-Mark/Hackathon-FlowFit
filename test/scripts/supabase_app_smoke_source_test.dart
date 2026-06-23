import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String script;
  late String releaseRunbook;
  late String releaseEnvExample;

  setUpAll(() {
    script = File('scripts/verify_supabase_app_smoke.ps1').readAsStringSync();
    releaseRunbook = File(
      'docs/RELEASE_READINESS_RUNBOOK.md',
    ).readAsStringSync();
    releaseEnvExample = File('.env.release.example').readAsStringSync();
  });

  test('live Supabase app smoke requires explicit external write approval', () {
    expect(script, contains('AllowExternalWrites'));
    expect(script, contains('This live smoke signs in and writes'));
    expect(script, contains('CreateSmokeUser'));
    expect(script, contains('AllowNonSmokeEmail'));
    expect(script, contains('AllowOverwriteExistingAppData'));
    expect(script, contains('SkipCleanup'));
    expect(script, contains('FLOWFIT_SMOKE_EMAIL'));
    expect(script, contains('FLOWFIT_SMOKE_PASSWORD'));
  });

  test('live Supabase app smoke uses client auth and never server keys', () {
    expect(script, contains('/auth/v1/token?grant_type=password'));
    expect(script, contains('/auth/v1/signup'));
    expect(script, contains('/auth/v1/logout'));
    expect(script, contains('Redact-SensitiveText'));
    expect(script, contains('flowfit-live-smoke'));
    expect(script, contains('SUPABASE_PUBLISHABLE_KEY'));
    expect(script, contains('sb_publishable_'));
    expect(script, contains('service_role|sb_secret_'));
    expect(script, isNot(contains('SUPABASE_SERVICE_ROLE_KEY')));
    expect(script, isNot(contains('SUPABASE_SECRET_KEY')));
  });

  test('live Supabase app smoke covers app-owned tables and cleanup', () {
    for (final table in [
      'user_profiles',
      'buddy_profiles',
      'workout_sessions',
      'heart_rate',
    ]) {
      expect(script, contains(table));
    }

    expect(script, contains('profile onboarding upsert'));
    expect(script, contains('buddy onboarding upsert'));
    expect(script, contains("buddyName = 'FlowFitSmokeBuddy'"));
    expect(script, contains('workout create update list delete'));
    expect(script, contains('Assert-RowCount'));
    expect(script, contains('workout_sessions list after delete'));
    expect(script, contains('heart rate insert list'));
    expect(script, contains("Method 'DELETE'"));
    expect(script, contains('SUPABASE_APP_SMOKE_OK'));
  });

  test('release docs expose the guarded live app smoke workflow', () {
    expect(releaseRunbook, contains('scripts/verify_supabase_app_smoke.ps1'));
    expect(releaseRunbook, contains('-AllowExternalWrites'));
    expect(releaseRunbook, contains('-CreateSmokeUser'));
    expect(releaseRunbook, contains('dedicated confirmed smoke test user'));
    expect(releaseRunbook, contains('FLOWFIT_SMOKE_EMAIL'));
    expect(releaseRunbook, contains('FLOWFIT_SMOKE_PASSWORD'));
  });

  test('release env example keeps smoke credentials optional and ignored', () {
    expect(releaseEnvExample, contains('FLOWFIT_SMOKE_EMAIL'));
    expect(releaseEnvExample, contains('FLOWFIT_SMOKE_PASSWORD'));
    expect(
      releaseEnvExample,
      contains('Optional live Supabase app smoke test credentials'),
    );
    expect(releaseEnvExample, contains('CreateSmokeUser'));
    expect(releaseEnvExample, isNot(contains('service_role')));
    expect(releaseEnvExample, isNot(contains('sb_secret_')));
  });
}
