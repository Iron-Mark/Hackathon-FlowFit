import 'package:flowfit/models/buddy_profile.dart';
import 'package:flowfit/utils/buddy_customization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buddy customization helpers', () {
    test('reads saved accessory and background with compatibility keys', () {
      expect(
        currentBuddyAccessory(const {buddyAccessoryKey: 'crown'}),
        'crown',
      );
      expect(currentBuddyAccessory(const {'accessory': 'hat'}), 'hat');
      expect(
        currentBuddyBackground(const {buddyBackgroundKey: 'forest'}),
        'forest',
      );
      expect(currentBuddyBackground(const {'background': 'space'}), 'space');
      expect(currentBuddyAccessory(const {buddyAccessoryKey: '   '}), isNull);
    });

    test('validates trimmed Buddy names', () {
      expect(validateBuddyCustomizationName(' Bluey '), isNull);
      expect(
        validateBuddyCustomizationName('   '),
        'Buddy name must be 1-20 characters.',
      );
      expect(
        validateBuddyCustomizationName('123456789012345678901'),
        'Buddy name must be 20 characters or fewer.',
      );
    });

    test('normalizes stale saved selections to safe UI defaults', () {
      expect(
        normalizeBuddyAccessorySelection(
          const {buddyAccessoryKey: 'missing'},
          const ['none', 'crown'],
        ),
        'none',
      );
      expect(
        normalizeBuddyAccessorySelection(
          const {buddyAccessoryKey: 'crown'},
          const ['none', 'crown'],
        ),
        'crown',
      );
      expect(
        normalizeBuddyBackgroundSelection(
          const {buddyBackgroundKey: 'missing'},
          const ['ocean'],
        ),
        isNull,
      );
      expect(
        normalizeBuddyBackgroundSelection(
          const {buddyBackgroundKey: 'ocean'},
          const ['ocean'],
        ),
        'ocean',
      );
    });

    test(
      'builds a trimmed save payload and preserves existing accessories',
      () {
        final updatedAt = DateTime.utc(2026, 6, 20, 1, 2, 3);
        final updates = buildBuddyCustomizationUpdates(
          profile: _profile(
            accessories: const {
              'favorite_food': 'kelp',
              buddyAccessoryKey: 'hat',
            },
          ),
          nameInput: '  Splash  ',
          selectedColor: 'purple',
          selectedAccessory: 'crown',
          selectedBackground: 'ocean',
          updatedAt: updatedAt,
        );

        expect(updates['name'], 'Splash');
        expect(updates['color'], 'purple');
        expect(updates['updated_at'], updatedAt.toIso8601String());
        expect(updates['accessories'], const {
          'favorite_food': 'kelp',
          buddyAccessoryKey: 'crown',
          buddyBackgroundKey: 'ocean',
        });
      },
    );

    test('canonicalizes selection keys and drops stale compatibility keys', () {
      final updates = buildBuddyCustomizationUpdates(
        profile: _profile(
          accessories: const {
            'favorite_food': 'kelp',
            'accessory': 'hat',
            'background': 'missing',
            buddyBackgroundKey: 'missing',
          },
        ),
        nameInput: 'Buddy',
        selectedColor: 'blue',
        selectedAccessory: 'none',
        selectedBackground: null,
        updatedAt: DateTime.utc(2026),
      );

      expect(updates['accessories'], const {
        'favorite_food': 'kelp',
        buddyAccessoryKey: 'none',
      });
    });

    test('rejects invalid save payload names', () {
      expect(
        () => buildBuddyCustomizationUpdates(
          profile: _profile(),
          nameInput: ' ',
          updatedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
    });
  });
}

BuddyProfile _profile({Map<String, dynamic>? accessories}) {
  return BuddyProfile(
    id: 'buddy-1',
    userId: 'user-1',
    name: 'Buddy',
    color: 'blue',
    level: 8,
    xp: 700,
    accessories: accessories,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}
