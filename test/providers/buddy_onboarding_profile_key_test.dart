import 'dart:io';

import 'package:flowfit/models/buddy_onboarding_state.dart';
import 'package:flowfit/providers/buddy_onboarding_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/providers/buddy_onboarding_provider.dart',
    ).readAsStringSync();
  });

  test('Buddy onboarding upserts user_profiles by auth user_id', () {
    expect(source, contains(".from('user_profiles')"));
    expect(source, contains('.upsert('));
    expect(source, contains("'user_id': userId"));
    expect(source, contains("onConflict: 'user_id'"));
    expect(source, contains("'survey_completed': true"));
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

  test('Buddy onboarding user profile payload completes the survey gate', () {
    final payload = buildBuddyUserProfileUpsertPayload(
      userId: 'auth-user-1',
      nickname: 'Alex',
      wellnessGoals: const ['move_more', 'sleep_better'],
      notificationsEnabled: true,
    );

    expect(payload, {
      'user_id': 'auth-user-1',
      'nickname': 'Alex',
      'is_kids_mode': true,
      'survey_completed': true,
      'wellness_goals': ['move_more', 'sleep_better'],
      'notifications_enabled': true,
    });
  });

  test('Buddy onboarding user profile payload can restore offline state', () {
    const savedState = BuddyOnboardingState(
      userName: 'Jordan',
      selectedGoals: ['focus'],
      notificationsGranted: false,
    );

    final payload = buildBuddyUserProfileUpsertPayload(
      userId: 'auth-user-2',
      nickname: savedState.userNickname ?? savedState.userName,
      wellnessGoals: savedState.selectedGoals,
      notificationsEnabled: savedState.notificationsGranted,
    );

    expect(payload['user_id'], 'auth-user-2');
    expect(payload['nickname'], 'Jordan');
    expect(payload['is_kids_mode'], isTrue);
    expect(payload['survey_completed'], isTrue);
    expect(payload['wellness_goals'], ['focus']);
    expect(payload['notifications_enabled'], isFalse);
  });

  test(
    'offline Buddy sync replays user_profiles before clearing local state',
    () {
      expect(source, contains('loadOnboardingState()'));
      expect(source, contains('pendingProfile.userId'));
      expect(
        source,
        contains('onboardingState.userNickname ?? onboardingState.userName'),
      );
      expect(source, contains('await _updateUserProfile('));

      final updateIndex = source.indexOf('await _updateUserProfile(');
      final clearPendingIndex = source.indexOf(
        'await storage.clearPendingBuddyProfile();',
      );
      final clearStateIndex = source.indexOf(
        'await storage.clearOnboardingState();',
      );

      expect(updateIndex, isNonNegative);
      expect(clearPendingIndex, isNonNegative);
      expect(clearStateIndex, isNonNegative);
      expect(updateIndex, lessThan(clearPendingIndex));
      expect(updateIndex, lessThan(clearStateIndex));
    },
  );
}
