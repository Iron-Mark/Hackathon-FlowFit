import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/providers/buddy_onboarding_provider.dart',
    ).readAsStringSync();
  });

  test('Buddy onboarding upserts user_profiles by auth user_id', () {
    expect(source, contains(".from('user_profiles').upsert"));
    expect(source, contains("'user_id': userId"));
    expect(source, contains("onConflict: 'user_id'"));
    expect(source, isNot(contains(".eq('id', userId)")));
  });

  test('Buddy onboarding saves buddy_profiles idempotently by user_id', () {
    expect(source, contains(".from('buddy_profiles')"));
    expect(
      source,
      contains(".upsert(profile.toJson(), onConflict: 'user_id')"),
    );
    expect(source, isNot(contains(".from('buddy_profiles').insert")));
  });
}
