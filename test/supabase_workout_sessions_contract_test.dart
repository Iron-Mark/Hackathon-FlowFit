import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260614062844_recreate_flowfit_backend.sql';

  late String migration;
  late Set<String> workoutSessionColumns;

  setUpAll(() {
    migration = File(migrationPath).readAsStringSync();
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
