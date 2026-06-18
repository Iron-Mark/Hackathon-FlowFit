import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String screenSource;
  late String migrationSource;

  setUpAll(() {
    screenSource = File(
      'lib/screens/profile/settings/delete_account_screen.dart',
    ).readAsStringSync();
    migrationSource = File(
      'supabase/migrations/20260614062844_recreate_flowfit_backend.sql',
    ).readAsStringSync().replaceAll('\r\n', '\n');
  });

  test('delete account screen submits the Supabase deletion request RPC', () {
    expect(screenSource, contains('DeepLinkHandler.beginInternalAuthFlow()'));
    expect(screenSource, contains('DeepLinkHandler.endInternalAuthFlow()'));
    expect(screenSource, contains('_reauthenticateForDeletion(client, user)'));
    expect(screenSource, contains('client.auth.signInWithPassword'));
    expect(screenSource, contains("client.rpc('request_account_deletion')"));
    expect(screenSource, contains('_clearLocalAccountData(user.id)'));
    expect(screenSource, contains('client.auth.signOut()'));
    expect(screenSource, isNot(contains('Future.delayed')));
    expect(screenSource, isNot(contains('Account deleted successfully')));
    expect(
      screenSource,
      isNot(contains("'Could not submit deletion request: \$error'")),
    );
    expect(screenSource, contains('_deletionErrorMessage(error)'));
  });

  test('delete account screen clears known local account data', () {
    expect(
      screenSource,
      isNot(contains("../../../services/database_service.dart")),
    );
    expect(screenSource, contains('clearLocalDatabaseAccountData()'));
    expect(screenSource, contains('user_profile_\$userId'));
    expect(screenSource, contains('sync_queue_\$userId'));
    expect(screenSource, contains('profile_image_\$userId'));
    expect(screenSource, contains('survey_data'));
    expect(screenSource, contains('pending_buddy_profile'));
    expect(screenSource, contains('wellness_history'));
    expect(
      screenSource,
      isNot(contains('DatabaseService.instance.clearAllData()')),
    );
  });

  test('canonical migration defines account deletion request backend', () {
    expect(
      migrationSource,
      contains('create table if not exists public.account_deletion_requests'),
    );
    expect(
      migrationSource,
      contains('create or replace function public.request_account_deletion()'),
    );
    expect(migrationSource, contains('security invoker'));
    expect(
      migrationSource,
      isNot(
        contains(
          'security'
          ' definer',
        ),
      ),
    );
    expect(
      migrationSource,
      contains('grant execute on function public.request_account_deletion()'),
    );
    expect(
      migrationSource,
      contains("set_config('app.flowfit_account_deletion_rpc', '1', true)"),
    );
    expect(
      migrationSource,
      anyOf(
        contains(
          "coalesce(current_setting('app.flowfit_account_deletion_rpc', true), '') = '1'",
        ),
        contains(
          "coalesce((select current_setting('app.flowfit_account_deletion_rpc', true)), '') = '1'",
        ),
      ),
    );
    expect(
      migrationSource,
      contains('grant select\n  on public.account_deletion_requests'),
    );
    expect(
      migrationSource,
      contains('grant insert (user_id, user_email, status, requested_at)'),
    );
    expect(
      migrationSource,
      isNot(
        contains('grant select, insert\n  on public.account_deletion_requests'),
      ),
    );
    expect(
      migrationSource,
      isNot(contains('Users can create own account deletion requests')),
    );
    expect(
      migrationSource,
      contains(
        'drop constraint if exists account_deletion_requests_user_id_fkey',
      ),
    );
  });

  test('canonical migration repairs legacy profile checks', () {
    expect(
      migrationSource,
      contains("where conrelid = 'public.user_profiles'::regclass"),
    );
    expect(migrationSource, contains("and contype = 'c'"));
    expect(
      migrationSource,
      contains('alter table public.user_profiles drop constraint if exists'),
    );
    expect(migrationSource, contains('add constraint user_profiles_age_valid'));
    expect(
      migrationSource,
      contains('check (age is null or (age between 7 and 120))'),
    );
    for (final constraint in [
      'user_profiles_daily_calorie_target_valid',
      'user_profiles_daily_steps_target_valid',
      'user_profiles_daily_active_minutes_target_valid',
      'user_profiles_daily_water_target_valid',
    ]) {
      expect(migrationSource, contains('add constraint $constraint'));
    }
    expect(
      migrationSource,
      isNot(contains('check (age is null or (age between 13 and 120))')),
    );
  });

  test('pending account deletion blocks future app-data writes', () {
    expect(
      migrationSource,
      contains(
        'create or replace function public.has_pending_account_deletion',
      ),
    );
    expect(
      migrationSource,
      contains("and status in ('pending', 'processing')"),
    );
    expect(
      migrationSource,
      contains('grant execute on function public.has_pending_account_deletion'),
    );

    final guardedWrites = RegExp(
      r'not public\.has_pending_account_deletion\(user_id\)',
    ).allMatches(migrationSource).length;
    expect(guardedWrites, greaterThanOrEqualTo(8));

    for (final policy in [
      'Users can insert own profile',
      'Users can update own profile',
      'Users can insert own buddy profile',
      'Users can update own buddy profile',
      'Users can insert own workout sessions',
      'Users can update own workout sessions',
      'Users can insert own heart rate',
      'Users can update own heart rate',
    ]) {
      final policyStart = migrationSource.indexOf('create policy "$policy"');
      expect(policyStart, isNonNegative, reason: policy);
      final nextPolicyStart = migrationSource.indexOf(
        'create policy "',
        policyStart + 1,
      );
      final policyBody = migrationSource.substring(
        policyStart,
        nextPolicyStart == -1 ? migrationSource.length : nextPolicyStart,
      );
      expect(
        policyBody,
        contains('not public.has_pending_account_deletion(user_id)'),
        reason: policy,
      );
    }
  });
}
