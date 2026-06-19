import 'dart:io';

import 'package:flowfit/core/config/supabase_tables.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Supabase table constants match backend migration table names', () {
    expect(SupabaseTables.userProfiles, 'user_profiles');
    expect(SupabaseTables.buddyProfiles, 'buddy_profiles');
    expect(SupabaseTables.workoutSessions, 'workout_sessions');
    expect(SupabaseTables.heartRate, 'heart_rate');
    expect(SupabaseTables.accountDeletionRequests, 'account_deletion_requests');
  });

  test('production Supabase table calls use shared constants', () {
    final directTableCalls =
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where((file) => !file.path.endsWith('supabase_tables.dart'))
            .expand((file) {
              final source = file.readAsStringSync();
              final matches = RegExp(
                r"\.from\('(?:user_profiles|buddy_profiles|workout_sessions|heart_rate|account_deletion_requests)'\)",
              ).allMatches(source);

              return matches.map((match) => '${file.path}:${match.group(0)}');
            })
            .toList()
          ..sort();

    expect(directTableCalls, isEmpty);
  });
}
