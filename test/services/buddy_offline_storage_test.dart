import 'package:flowfit/models/buddy_onboarding_state.dart';
import 'package:flowfit/models/buddy_profile.dart';
import 'package:flowfit/services/buddy_offline_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'stale onboarding state is retained while a Buddy profile is pending',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = BuddyOfflineStorage(prefs);
      final now = DateTime.now();

      await storage.savePendingBuddyProfile(
        BuddyProfile(
          id: 'buddy-1',
          userId: 'auth-user-1',
          name: 'Fluke',
          color: 'blue',
          unlockedColors: const ['blue'],
          createdAt: now,
          updatedAt: now,
        ),
      );
      await storage.saveOnboardingState(
        const BuddyOnboardingState(
          userName: 'Jordan',
          buddyName: 'Fluke',
          selectedColor: 'blue',
          selectedGoals: ['focus'],
          notificationsGranted: true,
          isComplete: true,
        ),
      );
      await prefs.setInt(
        'buddy_onboarding_timestamp',
        now.subtract(const Duration(hours: 25)).millisecondsSinceEpoch,
      );

      final restored = await storage.loadOnboardingState();

      expect(restored, isNotNull);
      expect(restored!.isComplete, isTrue);
      expect(restored.userName, 'Jordan');
      expect(restored.selectedGoals, ['focus']);
      expect(restored.notificationsGranted, isTrue);
      expect(await storage.hasPendingBuddyProfile(), isTrue);
    },
  );

  test(
    'stale onboarding state is cleared when no Buddy profile is pending',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = BuddyOfflineStorage(prefs);
      final now = DateTime.now();

      await storage.saveOnboardingState(
        const BuddyOnboardingState(userName: 'Jordan'),
      );
      await prefs.setInt(
        'buddy_onboarding_timestamp',
        now.subtract(const Duration(hours: 25)).millisecondsSinceEpoch,
      );

      expect(await storage.loadOnboardingState(), isNull);
      expect(prefs.containsKey('buddy_onboarding_state'), isFalse);
    },
  );
}
