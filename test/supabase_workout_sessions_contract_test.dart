import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260614062844_recreate_flowfit_backend.sql';
  const verificationPath = 'supabase/verification/verify_flowfit_backend.sql';

  late String migration;
  late String verificationSql;
  late Set<String> workoutSessionColumns;

  setUpAll(() {
    migration = File(migrationPath).readAsStringSync().replaceAll('\r\n', '\n');
    verificationSql = File(
      verificationPath,
    ).readAsStringSync().replaceAll('\r\n', '\n');
    workoutSessionColumns = _workoutSessionColumns(migration);
  });

  test('workout session model JSON keys are backed by migration columns', () {
    const modelPaths = [
      'lib/models/running_session.dart',
      'lib/models/walking_session.dart',
      'lib/models/resistance_session.dart',
    ];

    final modelKeys = {
      for (final path in modelPaths)
        ..._toJsonKeys(File(path).readAsStringSync()),
    };

    expect(
      modelKeys,
      isNotEmpty,
      reason: 'The contract test should find stored session JSON keys.',
    );

    for (final key in modelKeys) {
      expect(
        workoutSessionColumns,
        contains(key),
        reason:
            '$key is written by a workout session model but is missing from '
            'public.workout_sessions in $migrationPath.',
      );
    }
  });

  test('workout session table remains protected and reachable for users', () {
    expect(
      migration,
      contains(
        'alter table public.workout_sessions enable row level security;',
      ),
    );
    expect(
      migration,
      contains('from pg_policies'),
      reason: 'Canonical migration should remove stale permissive policies.',
    );
    expect(
      migration,
      matches(RegExp(r'revoke all\s+on\s+public\.user_profiles')),
      reason: 'Canonical migration should clear stale Data API grants first.',
    );
    expect(migration, contains('idx_workout_sessions_user_id'));
    expect(
      migration,
      contains('using ((select auth.uid()) = user_id)'),
      reason: 'RLS should evaluate auth.uid() once per statement.',
    );

    for (final policy in [
      'Users can view own workout sessions',
      'Users can insert own workout sessions',
      'Users can update own workout sessions',
      'Users can delete own workout sessions',
    ]) {
      expect(migration, contains('create policy "$policy"'));
    }

    expect(
      migration,
      matches(
        RegExp(
          r'grant select,\s*insert,\s*update,\s*delete\s+on\s+'
          r'public\.user_profiles,\s*public\.buddy_profiles,\s*'
          r'public\.workout_sessions,\s*public\.heart_rate\s+'
          r'to authenticated;',
          multiLine: true,
          caseSensitive: false,
        ),
      ),
      reason:
          'Authenticated users need explicit Data API grants; RLS still limits '
          'rows by user_id.',
    );

    expect(
      migration,
      matches(
        RegExp(
          r'grant usage on schema extensions\s+to authenticated,\s*'
          r'service_role;',
          multiLine: true,
          caseSensitive: false,
        ),
      ),
      reason:
          'Authenticated inserts rely on extensions.gen_random_uuid() defaults.',
    );
  });

  test('repair migration keeps required Data API columns non-null', () {
    for (final fragment in [
      'alter column name set not null',
      'alter column workout_type set not null',
      'alter column start_time set not null',
    ]) {
      expect(migration, contains(fragment));
    }
  });

  test('repair migration protects canonical id identity constraints', () {
    expect(migration, contains('Ensure canonical id identity constraints'));
    expect(migration, contains("managed_table || '_id_unique'"));
    expect(
      migration,
      contains('alter table public.%I add constraint %I unique (id)'),
    );
    expect(
      migration,
      contains('alter table public.%I alter column id set not null'),
    );
    expect(verificationSql, contains('expected_id_constraints'));
    expect(verificationSql, contains('missing_id_constraints'));
    expect(verificationSql, contains('missing_id_not_null'));
    expect(verificationSql, contains('id uniqueness constraints'));
    expect(verificationSql, contains('id not-null constraints'));

    for (final table in [
      'flowfit_recovery_quarantine',
      'user_profiles',
      'buddy_profiles',
      'workout_sessions',
      'heart_rate',
      'account_deletion_requests',
    ]) {
      expect(migration, contains(table));
      expect(
        verificationSql,
        contains("('$table', 'id')"),
        reason: '$verificationPath should prove public.$table has a unique id.',
      );
    }
  });

  test('workout history queries have a user-scoped time index', () {
    expect(
      migration,
      contains('idx_workout_sessions_user_start_time_desc'),
      reason:
          'Workout history reads filter by user_id and order/range by start_time.',
    );
    expect(
      migration,
      contains('on public.workout_sessions(user_id, start_time desc)'),
    );
    expect(
      verificationSql,
      contains('idx_workout_sessions_user_start_time_desc'),
    );
  });

  test('migration backfills Buddy-completed profiles through survey gate', () {
    expect(
      migration,
      contains('buddy-completed profile gate backfill'),
      reason:
          'Recovered projects can already have buddy_profiles rows from the '
          'older Buddy flow; those users must pass the returning-user gate.',
    );
    expect(
      migration,
      contains('survey_completed = true'),
      reason: 'Buddy-completed rows should mark the app survey gate complete.',
    );
    expect(
      migration,
      matches(
        RegExp(
          r'from public\.buddy_profiles as buddy\s+where buddy\.user_id = public\.user_profiles\.user_id',
          multiLine: true,
          caseSensitive: false,
        ),
      ),
    );
  });

  test('recovery migration quarantines invalid rows before cleanup deletes', () {
    expect(
      migration,
      contains('create table if not exists public.flowfit_recovery_quarantine'),
    );
    expect(
      migration,
      contains(
        'alter table public.flowfit_recovery_quarantine enable row level security;',
      ),
    );
    expect(
      migration,
      matches(
        RegExp(
          r'grant select,\s*delete\s+on public\.flowfit_recovery_quarantine\s+to service_role;',
          multiLine: true,
          caseSensitive: false,
        ),
      ),
    );

    for (final cleanup in [
      (
        table: 'user_profiles',
        reason: 'missing user_id',
        deleteSql: 'delete from public.user_profiles\nwhere user_id is null;',
      ),
      (
        table: 'buddy_profiles',
        reason: 'missing user_id',
        deleteSql: 'delete from public.buddy_profiles\nwhere user_id is null;',
      ),
      (
        table: 'workout_sessions',
        reason: 'missing user_id',
        deleteSql:
            'delete from public.workout_sessions\nwhere user_id is null;',
      ),
      (
        table: 'workout_sessions',
        reason: 'missing required workout identity',
        deleteSql:
            'delete from public.workout_sessions\nwhere workout_type is null',
      ),
      (
        table: 'workout_sessions',
        reason: 'invalid type-specific workout fields',
        deleteSql:
            'delete from public.workout_sessions\nwhere workout_type not in',
      ),
      (
        table: 'heart_rate',
        reason: 'missing user_id',
        deleteSql: 'delete from public.heart_rate\nwhere user_id is null;',
      ),
      (
        table: 'heart_rate',
        reason: 'missing timestamp',
        deleteSql: 'delete from public.heart_rate\nwhere "timestamp" is null;',
      ),
      (
        table: 'account_deletion_requests',
        reason: 'missing user_id',
        deleteSql:
            'delete from public.account_deletion_requests\nwhere user_id is null;',
      ),
    ]) {
      final deleteIndex = migration.indexOf(cleanup.deleteSql);
      expect(deleteIndex, isNonNegative);

      final prefix = migration.substring(0, deleteIndex);
      final insertIndex = prefix.lastIndexOf(
        'insert into public.flowfit_recovery_quarantine',
      );
      final tableIndex = prefix.lastIndexOf("'${cleanup.table}'");
      final reasonIndex = prefix.lastIndexOf("'${cleanup.reason}'");

      expect(insertIndex, isNonNegative);
      expect(tableIndex, isNonNegative);
      expect(reasonIndex, isNonNegative);
      expect(
        insertIndex,
        lessThan(tableIndex),
        reason:
            '${cleanup.table} rows should be copied to recovery quarantine '
            'with a source-table label before cleanup.',
      );
      expect(
        insertIndex,
        lessThan(reasonIndex),
        reason:
            '${cleanup.table} rows should be copied to recovery quarantine '
            'with a cleanup reason before deleting $cleanup.reason rows.',
      );
    }
  });

  test('recovery migration constrains workout type-specific fields', () {
    expect(migration, contains('invalid type-specific workout fields'));
    expect(migration, contains('workout_sessions_type_specific_fields_valid'));

    for (final fragment in [
      "workout_type = 'running'",
      "goal_type is not null",
      "goal_type in ('distance', 'duration')",
      "workout_type = 'walking'",
      "coalesce(mode, 'free') in ('free', 'mission')",
      "workout_type = 'resistance'",
      "workout_subtype is not null",
      "workout_subtype in ('upper', 'lower')",
    ]) {
      expect(migration, contains(fragment));
    }
  });

  test('database workout types match parsed session models', () {
    final service = File(
      'lib/services/workout_session_service.dart',
    ).readAsStringSync();
    final typeConstraint = RegExp(
      r'workout_type in \(([^)]+)\)',
      caseSensitive: false,
    ).allMatches(migration).last.group(1)!;

    for (final type in ['running', 'walking', 'resistance']) {
      expect(typeConstraint, contains("'$type'"));
      expect(service, contains("case '$type':"));
    }

    for (final unsupportedType in ['cycling', 'yoga']) {
      expect(typeConstraint, isNot(contains("'$unsupportedType'")));
    }
  });
}

Set<String> _toJsonKeys(String source) {
  final methodStart = source.indexOf('Map<String, dynamic> toJson()');
  if (methodStart < 0) {
    return {};
  }

  final returnStart = source.indexOf('return {', methodStart);
  if (returnStart < 0) {
    return {};
  }

  final bodyStart = source.indexOf('{', returnStart);
  var depth = 0;
  var bodyEnd = bodyStart;

  for (var i = bodyStart; i < source.length; i++) {
    final character = source[i];
    if (character == '{') {
      depth++;
    } else if (character == '}') {
      depth--;
      if (depth == 0) {
        bodyEnd = i;
        break;
      }
    }
  }

  final mapBody = source.substring(bodyStart + 1, bodyEnd);
  return RegExp(
    r"'([a-z0-9_]+)'\s*:",
  ).allMatches(mapBody).map((match) => match.group(1)!).toSet();
}

Set<String> _workoutSessionColumns(String migration) {
  final columns = <String>{};

  final tableStart = migration.indexOf(
    'create table if not exists public.workout_sessions (',
  );
  final tableEnd = migration.indexOf(
    ');\n\nalter table public.workout_sessions',
    tableStart,
  );
  expect(tableStart, isNonNegative);
  expect(tableEnd, isNonNegative);

  final tableBody = migration.substring(tableStart, tableEnd);
  for (final match in RegExp(
    r'^  ([a-z_][a-z0-9_]*|"[^"]+")\s+',
    multiLine: true,
  ).allMatches(tableBody)) {
    final column = _normalizeSqlIdentifier(match.group(1)!);
    if (column != 'constraint') {
      columns.add(column);
    }
  }

  final alterStart = migration.indexOf(
    'alter table public.workout_sessions',
    tableEnd,
  );
  final alterEnd = migration.indexOf(
    ';\n\nupdate public.workout_sessions',
    alterStart,
  );
  expect(alterStart, isNonNegative);
  expect(alterEnd, isNonNegative);

  final alterBody = migration.substring(alterStart, alterEnd);
  for (final match in RegExp(
    r'add column if not exists ([a-z_][a-z0-9_]*|"[^"]+")',
    caseSensitive: false,
  ).allMatches(alterBody)) {
    columns.add(_normalizeSqlIdentifier(match.group(1)!));
  }

  return columns;
}

String _normalizeSqlIdentifier(String identifier) {
  return identifier.replaceAll('"', '');
}
